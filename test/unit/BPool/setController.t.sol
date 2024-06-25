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
}
