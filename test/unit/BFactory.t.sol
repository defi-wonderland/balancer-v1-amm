// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BFactory} from 'contracts/BFactory.sol';
import {BPool} from 'contracts/BPool.sol';
import {IERC20} from 'contracts/BToken.sol';
import {Test} from 'forge-std/Test.sol';

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
   * @notice Test that a valid pool is present on the mapping
   */
  function test_validPoolIsBPool() public {
    BPool _pool = bFactory.newBPool();
    assertTrue(bFactory.isBPool(address(_pool)));
  }

  /**
   * @notice Test that a invalid pool is not present on the mapping
   */
  function test_invalidPoolIsNotBPool(address _randomPool) public view {
    vm.assume(_randomPool != address(0));
    assertFalse(bFactory.isBPool(_randomPool));
  }
}

contract BFactory_Unit_NewBPool is Base {
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

contract BFactory_Unit_GetBLabs is Base {
  /**
   * @notice Test that the correct owner is returned
   */
  function test_correctOwner(address _randomDeployer) public {
    vm.prank(_randomDeployer);
    BFactory _bFactory = new BFactory();
    assertEq(_randomDeployer, _bFactory.getBLabs());
  }
}

contract BFactory_Unit_SetBLabs is Base {
  /**
   * @notice Test that only the owner can set the BLabs
   */
  function test_failIfNotBLabs(address _randomCaller) public {
    vm.assume(_randomCaller != owner);
    vm.expectRevert('ERR_NOT_BLABS');
    vm.prank(_randomCaller);
    bFactory.setBLabs(_randomCaller);
  }

  /**
   * @notice Test that event is emitted
   */
  function test_emitEvent(address _addressToSet) public {
    vm.expectEmit(true, true, true, true);
    emit BFactory.LOG_BLABS(owner, _addressToSet);
    vm.prank(owner);
    bFactory.setBLabs(_addressToSet);
  }

  /**
   * @notice Test that the BLabs is set correctly
   */
  function test_setBLabs(address _addressToSet) public {
    vm.prank(owner);
    bFactory.setBLabs(_addressToSet);
    assertEq(_addressToSet, bFactory.getBLabs());
  }
}

contract BFactory_Unit_Collect is Base {
  /**
   * @notice Test that only the owner can collect
   */
  function test_failIfNotBLabs(address _randomCaller) public {
    vm.assume(_randomCaller != owner);
    vm.expectRevert('ERR_NOT_BLABS');
    vm.prank(_randomCaller);
    bFactory.collect(BPool(address(0)));
  }

  /**
   * @notice Test that LP token `balanceOf` function is called
   */
  function test_callBalanceOf(address _lpToken, uint _toCollect) public {
    vm.assume(_lpToken != address(VM_ADDRESS));
    vm.mockCall(_lpToken, abi.encodeWithSelector(IERC20.balanceOf.selector, address(bFactory)), abi.encode(_toCollect));
    vm.mockCall(_lpToken, abi.encodeWithSelector(IERC20.transfer.selector, owner, _toCollect), abi.encode(true));

    vm.expectCall(_lpToken, abi.encodeWithSelector(IERC20.balanceOf.selector, address(bFactory)));
    vm.prank(owner);
    bFactory.collect(BPool(_lpToken));
  }

  /**
   * @notice Test that LP token `transfer` function is called
   */
  function test_callTransfer(address _lpToken, uint _toCollect) public {
    vm.assume(_lpToken != address(VM_ADDRESS));
    vm.mockCall(_lpToken, abi.encodeWithSelector(IERC20.balanceOf.selector, address(bFactory)), abi.encode(_toCollect));
    vm.mockCall(_lpToken, abi.encodeWithSelector(IERC20.transfer.selector, owner, _toCollect), abi.encode(true));

    vm.expectCall(_lpToken, abi.encodeWithSelector(IERC20.transfer.selector, owner, _toCollect));
    vm.prank(owner);
    bFactory.collect(BPool(_lpToken));
  }

  /**
   * @notice Test that the function fail if the transfer failed
   */
  function test_failIfTransferFailed(address _lpToken, uint _toCollect) public {
    vm.assume(_lpToken != address(VM_ADDRESS));
    vm.mockCall(_lpToken, abi.encodeWithSelector(IERC20.balanceOf.selector, address(bFactory)), abi.encode(_toCollect));
    vm.mockCall(_lpToken, abi.encodeWithSelector(IERC20.transfer.selector, owner, _toCollect), abi.encode(false));

    vm.expectRevert('ERR_ERC20_FAILED');
    vm.prank(owner);
    bFactory.collect(BPool(_lpToken));
  }
}