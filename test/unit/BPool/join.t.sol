// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {BConst} from 'contracts/BConst.sol';
import {BPool, IBPool, IERC20} from 'contracts/BPool.sol';
import {StdStorage, Test, stdStorage} from 'forge-std/Test.sol';

// For test contract: execute a reentering call to an arbitrary function
contract BPoolReentering is BPool {
  event HAS_REENTERED();

  function TestTryToReenter(bytes calldata _calldata) external _lock_ {
    (bool success, bytes memory ret) = address(this).call(_calldata);

    if (!success) {
      assembly {
        revert(add(ret, 0x20), mload(ret))
      }
    }
  }
}

// For test contract: expose and modify the internal state variables of BPool
contract BPoolExposed is BPool {
  function forTest_getRecord(address token) external view returns (IBPool.Record memory) {
    return _records[token];
  }

  function forTest_setFinalize(bool _isFinalized) external {
    _finalized = _isFinalized;
  }

  function forTest_setTokens(address[] memory __tokens) external {
    _tokens = __tokens;
  }

  function forTest_setRecords(address _token, bool _bound, uint256 _index, uint256 _denorm) external {
    _records[_token].bound = _bound;
    _records[_token].index = _index;
    _records[_token].denorm = _denorm;
  }

  function forTest_setTotalWeight(uint256 __totalWeight) external {
    _totalWeight = __totalWeight;
  }
}

// Main test contract
contract BPoolTest is Test, BConst {
  using stdStorage for StdStorage;

  BPool pool;

  address deployer = makeAddr('deployer');

  function setUp() external {
    vm.prank(deployer);
    pool = new BPool();
  }

  function test_JoinPoolRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();
    uint256[] memory _arr = new uint256[](1);
    _arr[0] = 1;

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.joinPool, (1, _arr)));
  }

  function test_JoinPoolRevertWhen_ThePoolIsNotFinalized() external {
    // Pre condition
    BPoolExposed poolExposed = new BPoolExposed();
    poolExposed.forTest_setFinalize(false);

    // it should revert
    vm.expectRevert('ERR_NOT_FINALIZED');

    // Action
    poolExposed.joinPool(1, new uint256[](1));
  }

  function test_JoinPoolRevertWhen_TheRatioPoolAmountOutToPoolTotalIsZero(
    uint256 _totalSupply,
    uint256 _poolAmountOut
  ) external {
    // Pre Condition
    BPoolExposed poolExposed = new BPoolExposed();
    poolExposed.forTest_setFinalize(true);

    // Insure we always floor to 0
    _poolAmountOut = bound(_poolAmountOut, 1, (type(uint256).max / (BONE * 2)) - 1);
    _totalSupply = bound(_totalSupply, (2 * BONE * _poolAmountOut) + 1, type(uint256).max);

    stdstore.target(address(poolExposed)).sig('totalSupply()').checked_write(_totalSupply);

    uint256[] memory maxAmountsIn = new uint256[](1);
    maxAmountsIn[0] = 1;

    // it should revert
    vm.expectRevert('ERR_MATH_APPROX');

    // Action
    poolExposed.joinPool(_poolAmountOut, maxAmountsIn);
  }

  // Internal helper setting a finalized pool with some tokens and total supply
  function helper_setPoolWithTokens(uint256 _numberOfTokens) internal returns (BPoolExposed) {
    BPoolExposed poolExposed = new BPoolExposed();

    // Finalize the pool
    poolExposed.forTest_setFinalize(true);

    // Add tokens
    address[] memory _tokens = new address[](_numberOfTokens);
    string memory tokenName = 'token';

    for (uint256 i; i < _numberOfTokens; i++) {
      _tokens[i] = makeAddr(tokenName);
      tokenName = string.concat(tokenName, 'a'); // Don't boo me, you know I'm right
    }

    poolExposed.forTest_setTokens(_tokens);

    // Set a total supply
    stdstore.target(address(poolExposed)).sig('totalSupply()').checked_write(100);

    return poolExposed;
  }

  function test_JoinPoolRevertWhen_OneOfTheTokenAmountInIsZero() external {
    // Pre condition
    uint256 _numberOfTokens = 3;
    BPoolExposed poolExposed = helper_setPoolWithTokens(_numberOfTokens);

    address[] memory _tokens = poolExposed.getCurrentTokens();
    uint256[] memory _maxAmountsIn = new uint256[](_numberOfTokens);
    for (uint256 i; i < _numberOfTokens; i++) {
      _maxAmountsIn[i] = 10;
      vm.mockCall(_tokens[i], abi.encodeCall(IERC20.balanceOf, (address(poolExposed))), abi.encode(10));
    }

    _maxAmountsIn[0] = 0;

    // Post condition
    // it should revert
    vm.expectRevert('ERR_MATH_APPROX');

    // Action
    poolExposed.joinPool(1, _maxAmountsIn);
  }

  function test_JoinPoolRevertWhen_TheTokenAmountInOfOneOfThePoolTokenExceedsTheCorrespondingMaxAmountsIn() external {
    // Pre condition
    uint256 _numberOfTokens = 3;
    BPoolExposed poolExposed = helper_setPoolWithTokens(_numberOfTokens);

    address[] memory _tokens = poolExposed.getCurrentTokens();
    uint256[] memory _maxAmountsIn = new uint256[](_numberOfTokens);
    for (uint256 i; i < _numberOfTokens; i++) {
      _maxAmountsIn[i] = 10;
      vm.mockCall(_tokens[i], abi.encodeCall(IERC20.balanceOf, (address(poolExposed))), abi.encode(10));
    }

    // tokenAmountIn = balance * pool amount out / total supply
    uint256 _poolAmountOut = 20; // ratio 20/100
    _maxAmountsIn[0] = 1; // ratio would be max 10/100

    // Post condition
    // it should revert
    vm.expectRevert('ERR_LIMIT_IN');

    // Action
    poolExposed.joinPool(_poolAmountOut, _maxAmountsIn);
  }

  modifier whenTheFunctionRequirementsAreMet() {
    _;
  }

  function test_JoinPoolWhenTheFunctionRequirementsAreMet() external whenTheFunctionRequirementsAreMet {
    // Pre condition
    address caller = makeAddr('caller');
    vm.startPrank(caller);

    uint256 _poolAmountOut = 10; // ratio 10/100
    uint256 _numberOfTokens = 5;
    BPoolExposed poolExposed = helper_setPoolWithTokens(_numberOfTokens);

    address[] memory _tokens = poolExposed.getCurrentTokens();
    uint256[] memory _maxAmountsIn = new uint256[](_numberOfTokens);

    for (uint256 i; i < _numberOfTokens; i++) {
      _maxAmountsIn[i] = 10;
    }

    // it should emit LOG_CALL
    vm.expectEmit(address(poolExposed));
    emit IBPool.LOG_CALL(
      poolExposed.joinPool.selector, caller, abi.encodeCall(poolExposed.joinPool, (_poolAmountOut, _maxAmountsIn))
    );

    for (uint256 i; i < _numberOfTokens; i++) {
      vm.mockCall(_tokens[i], abi.encodeCall(IERC20.balanceOf, (address(poolExposed))), abi.encode(10));
      vm.expectCall(_tokens[i], abi.encodeCall(IERC20.balanceOf, (address(poolExposed))));

      // it should transfer the token amount in from the caller to the pool, for each token
      vm.mockCall(_tokens[i], abi.encodeCall(IERC20.transferFrom, (caller, address(poolExposed), 1)), abi.encode(true));
      vm.expectCall(_tokens[i], abi.encodeCall(IERC20.transferFrom, (caller, address(poolExposed), 1)));

      // it should emit LOG_JOIN for each token
      vm.expectEmit(address(poolExposed));
      emit IBPool.LOG_JOIN(caller, _tokens[i], 1);
    }

    // Action
    poolExposed.joinPool(_poolAmountOut, _maxAmountsIn);

    // it should mint pool shares for the caller
    assertEq(poolExposed.balanceOf(caller), _poolAmountOut);
  }

  function test_JoinPoolRevertWhen_OneOfTheUnderlyingTokenTransfersFails() external whenTheFunctionRequirementsAreMet {
    // Pre condition
    address caller = makeAddr('caller');
    vm.startPrank(caller);

    BPoolExposed poolExposed = helper_setPoolWithTokens(1);

    address[] memory _tokens = poolExposed.getCurrentTokens();
    uint256[] memory _maxAmountsIn = new uint256[](1);
    _maxAmountsIn[0] = 10;
    vm.mockCall(_tokens[0], abi.encodeCall(IERC20.balanceOf, (address(poolExposed))), abi.encode(10));
    vm.expectCall(_tokens[0], abi.encodeCall(IERC20.balanceOf, (address(poolExposed))));

    // it should transfer the token amount in from the caller to the pool, for each token
    vm.mockCall(_tokens[0], abi.encodeCall(IERC20.transferFrom, (caller, address(poolExposed), 1)), abi.encode(false));
    vm.expectCall(_tokens[0], abi.encodeCall(IERC20.transferFrom, (caller, address(poolExposed), 1)));

    // it should revert
    vm.expectRevert('ERR_ERC20_FALSE');

    // Action
    poolExposed.joinPool(10, _maxAmountsIn);
  }
}
