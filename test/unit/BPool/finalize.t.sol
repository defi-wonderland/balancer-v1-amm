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
}
