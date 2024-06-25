// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

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

  function test_BindRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.bind, (makeAddr('token'), MIN_BALANCE, MIN_WEIGHT)));
  }

  function test_BindRevertWhen_CalledByANon_controller(address _caller) external {
    // Pre condition
    vm.assume(_caller != deployer);

    // it should revert
    vm.expectRevert('ERR_NOT_CONTROLLER');

    // Action
    vm.prank(_caller);
    pool.bind(makeAddr('token'), MIN_BALANCE, MIN_WEIGHT);
  }

  function test_BindRevertWhen_TheTokenToBindIsAlreadyBound() external {
    // Pre condition
    vm.startPrank(deployer);
    address _token = makeAddr('token');
    BPoolExposed poolExposed = new BPoolExposed();
    poolExposed.forTest_setRecords({_token: _token, _bound: true, _index: 0, _denorm: 1});

    // it should revert
    vm.expectRevert('ERR_IS_BOUND');

    // Action
    poolExposed.bind(_token, MIN_BALANCE, MIN_WEIGHT);
  }

  function test_BindRevertWhen_ThePoolIsFinalized() external {
    // Pre condition
    vm.startPrank(deployer);
    BPoolExposed poolExposed = new BPoolExposed();
    poolExposed.forTest_setFinalize(true);

    // it should revert
    vm.expectRevert('ERR_IS_FINALIZED');

    // Action
    poolExposed.bind(makeAddr('token'), MIN_BALANCE, MIN_WEIGHT);
  }

  function test_BindRevertWhen_ThereAreAlreadyMAX_BOUNDTokens() external {
    // Pre condition
    vm.startPrank(deployer);
    BPoolExposed poolExposed = new BPoolExposed();
    address[] memory _tokens = new address[](MAX_BOUND_TOKENS);
    poolExposed.forTest_setTokens(_tokens);

    // it should revert
    vm.expectRevert('ERR_MAX_TOKENS');

    // Action
    poolExposed.bind(makeAddr('token'), MIN_BALANCE, MIN_WEIGHT);
  }

  function test_BindRevertWhen_TheDenormIsLtMIN_WEIGHT(uint256 _denorm) external {
    // Pre condition
    vm.startPrank(deployer);
    _denorm = bound(_denorm, 0, MIN_WEIGHT - 1);

    // it should revert
    vm.expectRevert('ERR_MIN_WEIGHT');

    // Action
    pool.bind(makeAddr('token'), MIN_BALANCE, _denorm);
  }

  function test_BindRevertWhen_TheDenormIsGtMAX_WEIGHT(uint256 _denorm) external {
    // Pre condition
    vm.startPrank(deployer);
    _denorm = bound(_denorm, pool.MAX_WEIGHT() + 1, type(uint256).max);

    // it should revert
    vm.expectRevert('ERR_MAX_WEIGHT');

    // Action
    pool.bind(makeAddr('token'), MIN_BALANCE, _denorm);
  }

  function test_BindRevertWhen_TheBalanceToSendIsLessThanMIN_BALANCE(uint256 _balance) external {
    // Pre condition
    vm.startPrank(deployer);
    _balance = bound(_balance, 0, MIN_BALANCE - 1);

    // it should revert
    vm.expectRevert('ERR_MIN_BALANCE');

    // Action
    pool.bind(makeAddr('token'), _balance, MIN_WEIGHT);
  }

  function test_BindRevertWhen_TheNewTotalWeightIsGtMAX_TOTAL_WEIGHT() external {
    // Pre condition
    vm.startPrank(deployer);
    BPoolExposed poolExposed = new BPoolExposed();
    poolExposed.forTest_setTotalWeight(MAX_TOTAL_WEIGHT - MIN_WEIGHT);

    // it should revert
    vm.expectRevert('ERR_MAX_TOTAL_WEIGHT');

    // Action
    poolExposed.bind(makeAddr('token'), MIN_BALANCE, MIN_WEIGHT + 1);
  }

  modifier whenTheFunctionRequirementsAreMet() {
    _;
  }

  function test_BindWhenTheFunctionRequirementsAreMet(
    uint256 _denom,
    uint256 _balance
  ) external whenTheFunctionRequirementsAreMet {
    // Pre condition
    vm.startPrank(deployer);

    BPoolExposed poolExposed = new BPoolExposed();

    _balance = bound(_balance, MIN_BALANCE, type(uint256).max);
    _denom = bound(_denom, MIN_WEIGHT, MAX_WEIGHT);
    address _token = makeAddr('token');

    // it should emit LOG_CALL (post condition)
    vm.expectEmit(address(poolExposed));
    emit IBPool.LOG_CALL(
      poolExposed.bind.selector, deployer, abi.encodeCall(poolExposed.bind, (_token, _balance, _denom))
    );

    // it should transfer the amount from the caller to the pool (post condition)
    vm.mockCall(
      _token, abi.encodeCall(IERC20.transferFrom, (deployer, address(poolExposed), _balance)), abi.encode(true)
    );
    vm.expectCall(_token, abi.encodeCall(IERC20.transferFrom, (deployer, address(poolExposed), _balance)));

    // Action
    poolExposed.bind(_token, _balance, _denom);

    // Post condition
    IBPool.Record memory _record = poolExposed.forTest_getRecord(_token);
    // it should set the token as bound,
    assertTrue(_record.bound);

    // it should set the token's index
    assertEq(_record.index, poolExposed.getCurrentTokens().length - 1);

    // it should set the token's denorm,
    assertEq(_record.denorm, _denom);

    // it should add the token to the tokens array
    assertEq(poolExposed.getCurrentTokens()[_record.index], _token);
  }

  function test_BindRevertWhen_TheTokenTransferFails(
    uint256 _denom,
    uint256 _balance
  ) external whenTheFunctionRequirementsAreMet {
    // Pre condition
    vm.startPrank(deployer);

    BPoolExposed poolExposed = new BPoolExposed();

    _balance = bound(_balance, MIN_BALANCE, type(uint256).max);
    _denom = bound(_denom, MIN_WEIGHT, MAX_WEIGHT);
    address _token = makeAddr('token');

    // it should transfer the amount from the caller to the pool (post condition)
    vm.mockCall(
      _token, abi.encodeCall(IERC20.transferFrom, (deployer, address(poolExposed), _balance)), abi.encode(false)
    );
    vm.expectCall(_token, abi.encodeCall(IERC20.transferFrom, (deployer, address(poolExposed), _balance)));

    // it should revert
    vm.expectRevert('ERR_ERC20_FALSE');

    // Action
    poolExposed.bind(_token, _balance, _denom);
  }
}
