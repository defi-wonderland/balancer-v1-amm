// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BCoWPool as BPool} from 'contracts/BCoWPool.sol';
import {BFactory, IBFactory} from 'contracts/BFactory.sol';
import {IERC20} from 'contracts/BToken.sol';
import {Test} from 'forge-std/Test.sol';

abstract contract Base is Test {
  BFactory public bFactory;
  address public owner = makeAddr('owner');
  address public cowSwap = makeAddr('cowSwap');
  address public vaultRelayer = makeAddr('vaultRelayer');

  function setUp() public {
    vm.prank(owner);
    bFactory = new BFactory(cowSwap);

    vm.mockCall(cowSwap, abi.encodeWithSignature('domainSeparator()'), abi.encode(bytes32(0)));
    vm.mockCall(cowSwap, abi.encodeWithSignature('vaultRelayer()'), abi.encode(vaultRelayer));
  }
}

contract BFactory_Unit_Constructor is Base {
  /**
   * @notice Test that the owner is set correctly
   */
  function test_Set_BLabs() public view {
    assertEq(owner, bFactory.getBLabs());
  }

  /**
   * @notice Test that the cowSwap address is set correctly
   */
  function test_Set_CowSwap() public view {
    assertEq(cowSwap, bFactory.getCowSwap());
  }
}

contract BFactory_Unit_IsBPool is Base {
  /**
   * @notice Test that a valid pool is present on the mapping
   */
  function test_Returns_IsValidPool(address _pool) public {
    // Writing TRUE (1) to the mapping with the `_pool` key
    vm.store(address(bFactory), keccak256(abi.encode(_pool, uint256(0))), bytes32(uint256(1)));
    assertTrue(bFactory.isBPool(address(_pool)));
  }

  /**
   * @notice Test that a invalid pool is not present on the mapping
   */
  function test_Returns_IsInvalidPool(address _randomPool) public view {
    vm.assume(_randomPool != address(0));
    assertFalse(bFactory.isBPool(_randomPool));
  }
}

contract BFactory_Unit_NewBPool is Base {
  /**
   * @notice Test that the pool is set on the mapping
   */
  function test_Set_Pool() public {
    BPool _pool = bFactory.newBPool();
    assertTrue(bFactory.isBPool(address(_pool)));
  }

  /**
   * @notice Test that event is emitted
   */
  function test_Emit_Log(address _randomCaller) public {
    assumeNotForgeAddress(_randomCaller);
    vm.expectEmit();
    address _expectedPoolAddress = vm.computeCreateAddress(address(bFactory), 1);
    emit IBFactory.LOG_NEW_POOL(_randomCaller, _expectedPoolAddress);
    vm.prank(_randomCaller);
    bFactory.newBPool();
  }

  /**
   * @notice Test that msg.sender is set as the controller
   */
  function test_Set_Controller(address _randomCaller) public {
    assumeNotForgeAddress(_randomCaller);
    vm.prank(_randomCaller);
    BPool _pool = bFactory.newBPool();
    assertEq(_randomCaller, _pool.getController());
  }

  /**
   * @notice Test that the pool address is returned
   */
  function test_Returns_Pool() public {
    address _expectedPoolAddress = vm.computeCreateAddress(address(bFactory), 1);
    BPool _pool = bFactory.newBPool();
    assertEq(_expectedPoolAddress, address(_pool));
  }
}

contract BFactory_Unit_GetBLabs is Base {
  /**
   * @notice Test that the correct owner is returned
   */
  function test_Set_Owner(address _randomDeployer) public {
    vm.prank(_randomDeployer);
    BFactory _bFactory = new BFactory(address(0));
    assertEq(_randomDeployer, _bFactory.getBLabs());
  }
}

contract BFactory_Unit_SetBLabs is Base {
  /**
   * @notice Test that only the owner can set the BLabs
   */
  function test_Revert_NotLabs(address _randomCaller) public {
    vm.assume(_randomCaller != owner);
    vm.expectRevert('ERR_NOT_BLABS');
    vm.prank(_randomCaller);
    bFactory.setBLabs(_randomCaller);
  }

  /**
   * @notice Test that event is emitted
   */
  function test_Emit_Log(address _addressToSet) public {
    vm.expectEmit();
    emit IBFactory.LOG_BLABS(owner, _addressToSet);
    vm.prank(owner);
    bFactory.setBLabs(_addressToSet);
  }

  /**
   * @notice Test that the BLabs is set correctly
   */
  function test_Set_BLabs(address _addressToSet) public {
    vm.prank(owner);
    bFactory.setBLabs(_addressToSet);
    assertEq(_addressToSet, bFactory.getBLabs());
  }
}

contract BFactory_Unit_Collect is Base {
  /**
   * @notice Test that only the owner can collect
   */
  function test_Revert_NotLabs(address _randomCaller) public {
    vm.assume(_randomCaller != owner);
    vm.expectRevert('ERR_NOT_BLABS');
    vm.prank(_randomCaller);
    bFactory.collect(BPool(address(0)));
  }

  /**
   * @notice Test that LP token `balanceOf` function is called
   */
  function test_Call_BalanceOf(address _lpToken, uint256 _toCollect) public {
    assumeNotForgeAddress(_lpToken);
    vm.mockCall(_lpToken, abi.encodeWithSelector(IERC20.balanceOf.selector, address(bFactory)), abi.encode(_toCollect));
    vm.mockCall(_lpToken, abi.encodeWithSelector(IERC20.transfer.selector, owner, _toCollect), abi.encode(true));

    vm.expectCall(_lpToken, abi.encodeWithSelector(IERC20.balanceOf.selector, address(bFactory)));
    vm.prank(owner);
    bFactory.collect(BPool(_lpToken));
  }

  /**
   * @notice Test that LP token `transfer` function is called
   */
  function test_Call_Transfer(address _lpToken, uint256 _toCollect) public {
    assumeNotForgeAddress(_lpToken);
    vm.mockCall(_lpToken, abi.encodeWithSelector(IERC20.balanceOf.selector, address(bFactory)), abi.encode(_toCollect));
    vm.mockCall(_lpToken, abi.encodeWithSelector(IERC20.transfer.selector, owner, _toCollect), abi.encode(true));

    vm.expectCall(_lpToken, abi.encodeWithSelector(IERC20.transfer.selector, owner, _toCollect));
    vm.prank(owner);
    bFactory.collect(BPool(_lpToken));
  }

  /**
   * @notice Test that the function fail if the transfer failed
   */
  function test_Revert_TransferFailed(address _lpToken, uint256 _toCollect) public {
    assumeNotForgeAddress(_lpToken);
    vm.mockCall(_lpToken, abi.encodeWithSelector(IERC20.balanceOf.selector, address(bFactory)), abi.encode(_toCollect));
    vm.mockCall(_lpToken, abi.encodeWithSelector(IERC20.transfer.selector, owner, _toCollect), abi.encode(false));

    vm.expectRevert('ERR_ERC20_FAILED');
    vm.prank(owner);
    bFactory.collect(BPool(_lpToken));
  }
}
