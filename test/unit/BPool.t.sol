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

  function test_SetSwapFeeRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.setSwapFee, 1));
  }

  function test_SetSwapFeeRevertWhen_PoolIsFinalized() external {
    // Pre condition
    BPoolExposed poolExposed = new BPoolExposed();
    poolExposed.forTest_setFinalize(true);

    // Post condition
    // it should revert
    vm.expectRevert('ERR_IS_FINALIZED');

    // Action
    poolExposed.setSwapFee(1);
  }

  function test_SetSwapFeeRevertWhen_CalledByANon_controller(address _caller) external {
    // Pre condition
    vm.assume(_caller != deployer);

    // Post condition
    // it should revert
    vm.expectRevert('ERR_NOT_CONTROLLER');

    // Action
    vm.prank(_caller);
    pool.setSwapFee(1);
  }

  modifier whenCalledByTheController() {
    vm.startPrank(deployer);
    _;
  }

  function test_SetSwapFeeRevertWhen_TheFeeIsSetLteMIN_FEE(uint256 _fee) external whenCalledByTheController {
    // Pre condition
    _fee = bound(_fee, 0, pool.MIN_FEE() - 1);

    // Post condition
    // it should revert
    vm.expectRevert('ERR_MIN_FEE');

    // Action
    pool.setSwapFee(_fee);
  }

  function test_SetSwapFeeRevertWhen_TheFeeIsSetGteMAX_FEE(uint256 _fee) external whenCalledByTheController {
    // Pre condition
    _fee = bound(_fee, pool.MAX_FEE() + 1, type(uint256).max);

    // Post condition
    // it should revert
    vm.expectRevert('ERR_MAX_FEE');

    // Action
    pool.setSwapFee(_fee);
  }

  function test_SetSwapFeeWhenTheFeeIsSetBetweenMIN_FEEAndMAX_FEE(uint256 _fee) external whenCalledByTheController {
    // Pre condition
    _fee = bound(_fee, pool.MIN_FEE(), pool.MAX_FEE());

    // Post condition
    // it should emit LOG_CALL
    vm.expectEmit(address(pool));
    emit IBPool.LOG_CALL(pool.setSwapFee.selector, deployer, abi.encodeCall(pool.setSwapFee, _fee));

    // Action
    pool.setSwapFee(_fee);

    // Post condition
    // it should set the fee
    assertEq(pool.getSwapFee(), _fee);
  }

  function test_SetControllerRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.setController, makeAddr('manager')));
  }

  function test_SetControllerRevertWhen_CalledByANon_controller(address _caller) external {
    // Pre condition
    vm.assume(_caller != deployer);
    vm.prank(_caller);

    // it should revert
    vm.expectRevert('ERR_NOT_CONTROLLER');

    // Action
    pool.setController(makeAddr('manager'));
  }

  function test_SetControllerWhenCalledByTheController() external {
    // Pre condition
    address _newController = makeAddr('manager');
    vm.startPrank(deployer);

    // it should emit LOG_CALL (Post condition)
    vm.expectEmit(address(pool));
    emit IBPool.LOG_CALL(pool.setController.selector, deployer, abi.encodeCall(pool.setController, _newController));

    // Action
    pool.setController(_newController);

    // Post condition
    // it should set the controller
    assertEq(pool.getController(), _newController);
  }

  function test_FinalizeRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.finalize, ()));
  }

  function test_FinalizeRevertWhen_CalledByANon_controller(address _caller) external {
    // Pre condition
    vm.assume(_caller != deployer);
    vm.prank(_caller);

    // it should revert
    vm.expectRevert('ERR_NOT_CONTROLLER');

    // Action
    pool.finalize();
  }

  function test_FinalizeRevertWhen_PoolIsFinalized() external {
    // Pre condition
    BPoolExposed poolExposed = new BPoolExposed();
    poolExposed.forTest_setFinalize(true);

    // it should revert
    vm.expectRevert('ERR_IS_FINALIZED');

    // Action
    poolExposed.finalize();
  }

  function test_FinalizeRevertWhen_ThereAreLessTokensThanMIN_BOUND_TOKENS() external {
    // Pre condition
    BPoolExposed poolExposed = new BPoolExposed();
    address[] memory _tokens = new address[](pool.MIN_BOUND_TOKENS() - 1);
    poolExposed.forTest_setTokens(_tokens);

    // it should revert
    vm.expectRevert('ERR_MIN_TOKENS');

    // Action
    poolExposed.finalize();
  }

  function test_FinalizeWhenCalledByTheController() external {
    // Pre condition
    vm.startPrank(deployer);
    BPoolExposed poolExposed = new BPoolExposed();
    address[] memory _tokens = new address[](pool.MIN_BOUND_TOKENS());
    poolExposed.forTest_setTokens(_tokens);

    // it should emit LOG_CALL
    vm.expectEmit(address(poolExposed));
    emit IBPool.LOG_CALL(poolExposed.finalize.selector, deployer, abi.encodeCall(poolExposed.finalize, ()));

    // Action
    poolExposed.finalize();

    // Post condition
    // it should mint the initial BToken supply
    assertEq(poolExposed.totalSupply(), poolExposed.INIT_POOL_SUPPLY());

    // it should send the initial BToken supply to the caller
    assertEq(poolExposed.balanceOf(deployer), poolExposed.INIT_POOL_SUPPLY());

    // it should set the pool as finalized
    assertTrue(poolExposed.isFinalized());
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

  function test_UnbindRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.unbind, makeAddr('token')));
  }

  function test_UnbindRevertWhen_CalledByANon_controller(address _caller) external {
    // Pre condition
    vm.assume(_caller != deployer);

    // it should revert
    vm.expectRevert('ERR_NOT_CONTROLLER');

    // Action
    vm.prank(_caller);
    pool.unbind(makeAddr('token'));
  }

  function test_UnbindRevertWhen_TheTokenToUnbindIsNotBound() external {
    // Pre condition
    vm.startPrank(deployer);
    BPoolExposed poolExposed = new BPoolExposed();
    address _token = makeAddr('token');
    poolExposed.forTest_setRecords({_token: _token, _bound: false, _index: 0, _denorm: 1});

    // it should revert
    vm.expectRevert('ERR_NOT_BOUND');

    // Action
    poolExposed.unbind(_token);
  }

  function test_UnbindRevertWhen_ThePoolIsFinalized() external {
    // Pre condition
    vm.startPrank(deployer);
    address _token = makeAddr('token');
    BPoolExposed poolExposed = new BPoolExposed();
    poolExposed.forTest_setRecords({_token: _token, _bound: true, _index: 0, _denorm: 1});
    poolExposed.forTest_setFinalize(true);

    // it should revert
    vm.expectRevert('ERR_IS_FINALIZED');

    // Action
    poolExposed.unbind(_token);
  }

  function test_UnbindWhenTheFunctionRequirementsAreMet() external whenTheFunctionRequirementsAreMet {
    // Pre condition
    vm.startPrank(deployer);

    BPoolExposed poolExposed = new BPoolExposed();
    uint256 _balance = 100;
    uint256 _denorm = 5;
    uint256 _totalWeight = 10;
    address _token = makeAddr('token');
    address[] memory _tokens = new address[](1);
    _tokens[0] = _token;

    poolExposed.forTest_setRecords({_token: _token, _bound: true, _index: 0, _denorm: _denorm});
    poolExposed.forTest_setTotalWeight(_totalWeight);
    poolExposed.forTest_setTokens(_tokens);

    // it should emit LOG_CALL
    vm.expectEmit(address(poolExposed));
    emit IBPool.LOG_CALL(poolExposed.unbind.selector, deployer, abi.encodeCall(poolExposed.unbind, _token));

    // it should transfer the token balance to the caller
    vm.mockCall(_token, abi.encodeCall(IERC20.balanceOf, (address(poolExposed))), abi.encode(_balance));
    vm.expectCall(_token, abi.encodeCall(IERC20.balanceOf, (address(poolExposed))));
    vm.mockCall(_token, abi.encodeCall(IERC20.transfer, (deployer, _balance)), abi.encode(true));
    vm.expectCall(_token, abi.encodeCall(IERC20.transfer, (deployer, _balance)));

    // Action
    poolExposed.unbind(_token);

    // Post condition

    // it should update the total weight
    assertEq(poolExposed.getTotalDenormalizedWeight(), _totalWeight - _denorm);

    // it should remove the token from the token array
    address[] memory _currTokens = poolExposed.getCurrentTokens();
    for (uint256 i = 0; i < _currTokens.length; i++) {
      if (_currTokens[i] == _token) {
        emit log('Pool token not removed');
        fail();
      }
    }

    // it should update the token record to unbound
    IBPool.Record memory _record = poolExposed.forTest_getRecord(_token);
    assertFalse(_record.bound);
  }

  function test_UnbindRevertWhen_TheTokenTransferFails() external whenTheFunctionRequirementsAreMet {
    // Pre condition
    vm.startPrank(deployer);

    BPoolExposed poolExposed = new BPoolExposed();
    uint256 _balance = 100;
    uint256 _denorm = 5;
    uint256 _totalWeight = 10;
    address _token = makeAddr('token');
    address[] memory _tokens = new address[](1);
    _tokens[0] = _token;

    poolExposed.forTest_setRecords({_token: _token, _bound: true, _index: 0, _denorm: _denorm});
    poolExposed.forTest_setTotalWeight(_totalWeight);
    poolExposed.forTest_setTokens(_tokens);

    // it should transfer the token balance to the caller
    vm.mockCall(_token, abi.encodeCall(IERC20.balanceOf, (address(poolExposed))), abi.encode(_balance));
    vm.expectCall(_token, abi.encodeCall(IERC20.balanceOf, (address(poolExposed))));
    vm.mockCall(_token, abi.encodeCall(IERC20.transfer, (deployer, _balance)), abi.encode(false));
    vm.expectCall(_token, abi.encodeCall(IERC20.transfer, (deployer, _balance)));

    // it should revert
    vm.expectRevert('ERR_ERC20_FALSE');

    // Action
    poolExposed.unbind(_token);
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

  function test_ExitPoolRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();
    uint256[] memory _arr = new uint256[](1);
    _arr[0] = 1;

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.exitPool, (1, _arr)));
  }

  function test_ExitPoolRevertWhen_ThePoolIsNotFinalized() external {
    // it should revert
    vm.skip(true);
  }

  function test_ExitPoolWhenNetPoolShareIsZero() external {
    // it should revert
    //     poolAmountIn - poolAmountIn * exit fee / pooltotal is zero
    vm.skip(true);
  }

  function test_ExitPoolWhenTheFunctionRequirementsAreMet() external whenTheFunctionRequirementsAreMet {
    // it should transfer the btoken from the caller to the pool
    // it should transfer the exit fee (poolAmountIn*exit fee) to the factory
    // it should burn the rest of the btoken
    // it should transfer the pool tokens to the caller
    // it should emit LOG_CALL
    // it should emit LOG_EXIT for each token
    vm.skip(true);
  }

  function test_ExitPoolRevertWhen_OneOfTheUnderlyingTokenTransferIsAZeroAmount()
    external
    whenTheFunctionRequirementsAreMet
  {
    // it should revert
    vm.skip(true);
  }

  function test_ExitPoolRevertWhen_OneOfTheUnderlyingTokenTransferAmountIsLessThanTheMinAmountsOut()
    external
    whenTheFunctionRequirementsAreMet
  {
    // it should revert
    vm.skip(true);
  }

  function test_ExitPoolRevertWhen_OneOfTheUnderlyingTokenTransferFails() external whenTheFunctionRequirementsAreMet {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountInRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(
      abi.encodeCall(poolReentering.swapExactAmountIn, (makeAddr('tokenIn'), 1, makeAddr('tokenOut'), 1, 1))
    );
  }

  function test_SwapExactAmountInRevertWhen_TheTokenInIsNotBound() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountInRevertWhen_TheTokenOutIsNotBound() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountInRevertWhen_ThePoolIsNotFinalized() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountInWhenTheTokenAmountInIsTooSmall() external {
    // it should revert
    //     tokenAmountIn is lte tokenInBalance * MAX_IN_RATIO
    vm.skip(true);
  }

  function test_SwapExactAmountInRevertWhen_TheSpotPriceBeforeTheSwapIsGtMaxPrice() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountInRevertWhen_TheTokenAmountOutIsLessThanMinAmountOut() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountInRevertWhen_TheSpotPriceDecreasesAfterTheSwap() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountInRevertWhen_TheSpotPriceAfterTheSwapIsGtMaxPrice() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountInRevertWhen_TheSpotPriceAfterTheSwapIsGtTokenAmountInDivByTokenAmountOut() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountInWhenTheFunctionRequirementsAreMet() external whenTheFunctionRequirementsAreMet {
    // it should transfer tokenAmountIn tokenIn from the caller to the pool
    // it should transfer tokenAmountOut tokenOut from the pool to the caller
    // it should emit LOG_CALL
    vm.skip(true);
  }

  function test_SwapExactAmountInRevertWhen_OneOfTheUnderlyingTokenTransferFails()
    external
    whenTheFunctionRequirementsAreMet
  {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountOutRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(
      abi.encodeCall(poolReentering.swapExactAmountOut, (makeAddr('tokenIn'), 1, makeAddr('tokenOut'), 1, 1))
    );
  }

  function test_SwapExactAmountOutRevertWhen_TheTokenInIsNotBound() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountOutRevertWhen_TheTokenOutIsNotBound() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountOutRevertWhen_ThePoolIsNotFinalized() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountOutRevertWhen_TheTokenAmountOutIsLteTokenInBalanceMulByMAX_OUT_RATIO() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountOutRevertWhen_TheSpotPriceBeforeTheSwapIsGtMaxPrice() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountOutRevertWhen_TheTokenAmountInIsGtMaxAmountIn() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountOutRevertWhen_TheSpotPriceDecreasesAfterTheSwap() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountOutRevertWhen_TheSpotPriceAfterTheSwapIsGtMaxPrice() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountOutRevertWhen_TheSpotPriceAfterTheSwapIsGtTokenAmountInDivByTokenAmountOut() external {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountOutWhenTheFunctionRequirementsAreMet() external whenTheFunctionRequirementsAreMet {
    // it should transfer the tokenIn from the caller to the pool
    // it should transfer the tokenOut from the pool to the caller
    // it should emit LOG_CALL
    vm.skip(true);
  }

  function test_SwapExactAmountOutRevertWhen_OneOfTheUnderlyingTokenTransferFails()
    external
    whenTheFunctionRequirementsAreMet
  {
    // it should revert
    vm.skip(true);
  }

  function test_JoinswapExternAmountInRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.joinswapExternAmountIn, (makeAddr('tokenIn'), 1, 1)));
  }

  function test_JoinswapExternAmountInRevertWhen_TheTokenIsNotBound() external {
    // it should revert
    vm.skip(true);
  }

  function test_JoinswapExternAmountInRevertWhen_ThePoolIsNotFinalized() external {
    // it should revert
    vm.skip(true);
  }

  function test_JoinswapExternAmountInRevertWhen_TheTokenAmountInIsLteTokenInBalanceMulByMAX_IN_RATIO() external {
    // it should revert
    vm.skip(true);
  }

  function test_JoinswapExternAmountInRevertWhen_ThePoolAmountOutIsLtMinPoolAmountOut() external {
    // it should revert
    vm.skip(true);
  }

  function test_JoinswapExternAmountInWhenTheFunctionRequirementsAreMet() external {
    // it should mint pool amount out
    // it should transfer the pool amount out to the caller
    // it should transfer the token amount in from the caller to the pool
    // it should emit LOG_CALL
    vm.skip(true);
  }

  function test_JoinswapPoolAmountOutRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.joinswapPoolAmountOut, (makeAddr('tokenIn'), 1, 1)));
  }

  function test_JoinswapPoolAmountOutRevertWhen_TheTokenIsNotBound() external {
    // it should revert
    vm.skip(true);
  }

  function test_JoinswapPoolAmountOutRevertWhen_ThePoolIsNotFinalized() external {
    // it should revert
    vm.skip(true);
  }

  function test_JoinswapPoolAmountOutRevertWhen_TheCalculatedTokenAmountInEquals0() external {
    // it should revert
    vm.skip(true);
  }

  function test_JoinswapPoolAmountOutRevertWhen_TheCalculatedTokenAmountInIsGtMaxAmountIn() external {
    // it should revert
    vm.skip(true);
  }

  function test_JoinswapPoolAmountOutRevertWhen_TheCalculatedTokenAmountInIsGtTokenInBalanceMulByMAX_IN_RATIO()
    external
  {
    // it should revert
    vm.skip(true);
  }

  function test_JoinswapPoolAmountOutWhenTheFunctionRequirementsAreMet() external {
    // it should mint pool amount out
    // it should transfer the pool amount out to the caller
    // it should transfer the token amount in from the caller to the pool
    // it should emit LOG_JOIN
    // it should emit LOG_CALL
    vm.skip(true);
  }

  function test_ExitswapPoolAmountInRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.exitswapPoolAmountIn, (makeAddr('tokenIn'), 1, 1)));
  }

  function test_ExitswapPoolAmountInRevertWhen_TheTokenIsNotBound() external {
    // it should revert
    vm.skip(true);
  }

  function test_ExitswapPoolAmountInRevertWhen_ThePoolIsNotFinalized() external {
    // it should revert
    vm.skip(true);
  }

  function test_ExitswapPoolAmountInRevertWhen_TheCalculatedTokenAmountOutIsLtMinAmountOut() external {
    // it should revert
    vm.skip(true);
  }

  function test_ExitswapPoolAmountInRevertWhen_TheCalculatedTokenAmountOutIsGtTokenOutBalanceMulByMAX_OUT_RATIO()
    external
  {
    // it should revert
    vm.skip(true);
  }

  function test_ExitswapPoolAmountInWhenTheFunctionRequirementsAreMet() external {
    // it should pull the pool amount in
    // it should burn the pool amount in minus fee
    // it should transfer the fee to the factory
    // it should transfer the token amount out to the caller
    // it should emit LOG_EXIT
    // it should emit LOG_CALL
    vm.skip(true);
  }

  function test_ExitswapExternAmountOutRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.exitswapExternAmountOut, (makeAddr('tokenIn'), 1, 1)));
  }

  function test_ExitswapExternAmountOutRevertWhen_TheTokenIsNotBound() external {
    // it should revert
    vm.skip(true);
  }

  function test_ExitswapExternAmountOutRevertWhen_ThePoolIsNotFinalized() external {
    // it should revert
    vm.skip(true);
  }

  function test_ExitswapExternAmountOutRevertWhen_ThePoolAmountOutIsGtTokenOutBalanceMulByMAX_OUT_RATIO() external {
    // it should revert
    vm.skip(true);
  }

  function test_ExitswapExternAmountOutRevertWhen_TheCalculatedPoolAmountInIsZero() external {
    // it should revert
    vm.skip(true);
  }

  function test_ExitswapExternAmountOutRevertWhen_TheCalculatedPoolAmountInIsGtMaxPoolAmountIn() external {
    // it should revert
    vm.skip(true);
  }

  function test_ExitswapExternAmountOutWhenTheFunctionRequirementsAreMet() external {
    // it should pull the pool amount in
    // it should burn the pool amount in minus fee
    // it should transfer the fee to the factory
    // it should transfer the token amount out to the caller
    // it should emit LOG_EXIT
    // it should emit LOG_CALL
    vm.skip(true);
  }

  function test_GetSpotPriceRevertWhen_TheTokenInIsNotBound() external {
    // it should revert
    vm.skip(true);
  }

  function test_GetSpotPriceRevertWhen_TheTokenOutIsNotBound() external {
    // it should revert
    vm.skip(true);
  }

  function test_GetSpotPriceWhenBothTokenAreNotBound() external {
    // it should return the spot price
    vm.skip(true);
  }

  function test_GetSpotPriceSansFeeRevertWhen_TheTokenInIsNotBound() external {
    // it should revert
    vm.skip(true);
  }

  function test_GetSpotPriceSansFeeRevertWhen_TheTokenOutIsNotBound() external {
    // it should revert
    vm.skip(true);
  }

  function test_GetSpotPriceSansFeeWhenBothTokenAreNotBound() external {
    // it should return the spot price without fees
    vm.skip(true);
  }
}
