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
}
