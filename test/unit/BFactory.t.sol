// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {BFactory, IBFactory, IBPool} from 'contracts/BFactory.sol';
import {Test} from 'forge-std/Test.sol';

contract BFactoryTest is Test {
  address factoryDeployer = makeAddr('factoryDeployer');
  address deployer = makeAddr('deployer');

  BFactory factory;

  function setUp() external {
    vm.prank(factoryDeployer);
    factory = new BFactory();
  }

  function test_NewBPoolWhenCalled() external {
    // it should emit a PoolCreated event (post condition)
    address _futurePool = vm.computeCreateAddress(address(factory), 1);
    vm.expectEmit(address(factory));
    emit IBFactory.LOG_NEW_POOL(deployer, _futurePool);

    // Action
    vm.prank(deployer);
    IBPool pool = factory.newBPool();

    // Post-conditions

    // it should deploy a new newBPool
    assertGt(address(pool).code.length, 0);

    // it should add the newBPool to the list of pools
    assertTrue(factory.isBPool(address(pool)));

    // it should call set the controller of the newBPool to the caller
    assertEq(pool.getController(), deployer);
  }

  function test_SetBLabsRevertWhen_TheSenderIsNotTheCurrentSetBLabs(address _caller) external {
    // Pre-condition
    vm.assume(_caller != factoryDeployer);

    // Post-condition
    // it should revert
    vm.expectRevert('ERR_NOT_BLABS');

    // Action
    vm.prank(_caller);
    factory.setBLabs(makeAddr('newBLabs'));
  }

  function test_SetBLabsWhenTheSenderIsTheCurrentSetBLabs(address _newBLabs) external {
    // it should emit a BLabsSet event (post condition)
    vm.expectEmit(address(factory));
    emit IBFactory.LOG_BLABS(factoryDeployer, _newBLabs);

    // Action
    vm.prank(factoryDeployer);
    factory.setBLabs(_newBLabs);

    // it should set the new setBLabs address
    assertEq(factory.getBLabs(), _newBLabs);
  }

  function test_CollectRevertWhen_TheSenderIsNotTheCurrentSetBLabs(address _caller) external {
    // Pre-condition
    vm.assume(_caller != factoryDeployer);

    // it should revert (post condition)
    vm.expectRevert('ERR_NOT_BLABS');

    // Action
    vm.prank(_caller);
    factory.collect(IBPool(makeAddr('pool')));
  }

  modifier whenTheSenderIsTheCurrentSetBLabs() {
    vm.startPrank(factoryDeployer);
    _;
  }

  function test_CollectWhenTheSenderIsTheCurrentSetBLabs(uint256 _factoryBTBalance)
    external
    whenTheSenderIsTheCurrentSetBLabs
  {
    // Pre-condition
    address _mockPool = makeAddr('pool');
    vm.mockCall(_mockPool, abi.encodeCall(IERC20.balanceOf, address(factory)), abi.encode(_factoryBTBalance));
    vm.mockCall(_mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, _factoryBTBalance)), abi.encode(true));

    // Post-condition
    // it should get the pool's btoken balance of the factory
    vm.expectCall(_mockPool, abi.encodeCall(IERC20.balanceOf, address(factory)));

    // it should transfer the btoken balance of the factory to BLabs
    vm.expectCall(_mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, _factoryBTBalance)));

    // Action
    factory.collect(IBPool(_mockPool));
  }

  function test_CollectRevertWhen_TheBtokenTransferFails(uint256 _factoryBTBalance)
    external
    whenTheSenderIsTheCurrentSetBLabs
  {
    // Pre-condition
    address _mockPool = makeAddr('pool');
    vm.mockCall(_mockPool, abi.encodeCall(IERC20.balanceOf, address(factory)), abi.encode(_factoryBTBalance));
    vm.expectCall(_mockPool, abi.encodeCall(IERC20.balanceOf, address(factory)));
    vm.mockCall(_mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, _factoryBTBalance)), abi.encode(false));
    vm.expectCall(_mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, _factoryBTBalance)));

    // it should revert
    vm.expectRevert('ERR_ERC20_FAILED');

    // Action
    factory.collect(IBPool(_mockPool));
  }
}
