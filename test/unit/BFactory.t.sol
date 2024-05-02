// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BFactory} from 'contracts/BFactory.sol';
import {BPool} from 'contracts/BPool.sol';
import {Test, Vm} from 'forge-std/Test.sol';

abstract contract Base is Test {
  BFactory public bFactory;
  address public owner = makeAddr('owner');

  function setUp() public {
    vm.prank(owner);
    bFactory = new BFactory();
  }
}

contract BFactory_Unit_Constructor is Base {
  /**
   * @notice Test that the owner is set correctly
   */
  function test_correctDeploy() public view {
    assertEq(owner, bFactory.getBLabs());
  }
}

contract BFactory_Unit_IsBPool is Base {
  /**
   * @notice Test that the pool is set on the mapping
   */
  function test_poolIsBPool() public {
    BPool _pool = bFactory.newBPool();
    assertTrue(bFactory.isBPool(address(_pool)));
  }

  /**
   * @notice Test that event is emitted
   */
  function test_emitEvent() public {
    vm.expectEmit(true, true, true, true);
    address _expectedPoolAddress = vm.computeCreateAddress(address(bFactory), 1);
    emit BFactory.LOG_NEW_POOL(owner, _expectedPoolAddress);
    vm.prank(owner);
    bFactory.newBPool();
  }

  /**
   * @notice Test that msg.sender is set as the controller
   */
  function test_controllerIsSet() public {
    vm.prank(owner);
    BPool _pool = new BPool();
    assertEq(owner, _pool.getController());
  }

  /**
   * @notice Test that the pool address is returned
   */
  function test_poolIsReturned() public {
    address _expectedPoolAddress = vm.computeCreateAddress(address(bFactory), 1);
    BPool _pool = bFactory.newBPool();
    assertEq(_expectedPoolAddress, address(_pool));
  }
}

contract BFactory_Unit_NewBPool is Base {
}

contract BFactory_Unit_GetBLabs is Base {
}

contract BFactory_Unit_SetBLabs is Base {
}

contract BFactory_Unit_Collect is Base {
}