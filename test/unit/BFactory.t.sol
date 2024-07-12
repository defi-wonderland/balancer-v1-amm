// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {BPool} from 'contracts/BPool.sol';

import {Test} from 'forge-std/Test.sol';
import {IBFactory} from 'interfaces/IBFactory.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {MockBFactory} from 'test/smock/MockBFactory.sol';

contract BFactoryTest is Test {
  address factoryDeployer = makeAddr('factoryDeployer');

  MockBFactory factory;

  function setUp() external {
    vm.prank(factoryDeployer);
    factory = new MockBFactory();
  }

  function test_ConstructorWhenCalled(address _blabs) external {
    vm.prank(_blabs);
    MockBFactory newFactory = new MockBFactory();
    // it should set BLabs
    assertEq(newFactory.getBLabs(), _blabs);
  }

  function test_NewBPoolWhenCalled(address _deployer, address _newBPool) external {
    assumeNotForgeAddress(_newBPool);
    vm.mockCall(_newBPool, abi.encodePacked(IBPool.setController.selector), abi.encode());
    factory.mock_call__newBPool(IBPool(_newBPool));
    // it should call _newBPool
    factory.expectCall__newBPool();
    // it should set the controller of the newBPool to the caller
    vm.expectCall(_newBPool, abi.encodeCall(IBPool.setController, (_deployer)));
    // it should emit a PoolCreated event
    vm.expectEmit(address(factory));
    emit IBFactory.LOG_NEW_POOL(_deployer, _newBPool);

    vm.prank(_deployer);
    IBPool pool = factory.newBPool();

    // it should add the newBPool to the list of pools
    assertTrue(factory.isBPool(address(_newBPool)));
    // it should return the address of the new BPool
    assertEq(address(pool), _newBPool);
  }

  function test__newBPoolWhenCalled() external {
    vm.prank(address(factory));
    bytes memory _expectedCode = address(new BPool()).code; // NOTE: uses nonce 1
    address _futurePool = vm.computeCreateAddress(address(factory), 2);

    address _newBPool = address(factory.call__newBPool());
    assertEq(_newBPool, _futurePool);
    // it should deploy a new BPool
    assertEq(_newBPool.code, _expectedCode);
  }

  function test_SetBLabsRevertWhen_TheSenderIsNotTheCurrentBLabs(address _caller) external {
    vm.assume(_caller != factoryDeployer);

    // it should revert
    vm.expectRevert(IBFactory.BFactory_NotBLabs.selector);

    vm.prank(_caller);
    factory.setBLabs(makeAddr('newBLabs'));
  }

  modifier whenTheSenderIsTheCurrentBLabs() {
    vm.startPrank(factoryDeployer);
    _;
  }

  function test_SetBLabsRevertWhen_TheAddressIsZero() external whenTheSenderIsTheCurrentBLabs {
    // it should revert
    vm.expectRevert(IBFactory.BFactory_AddressZero.selector);

    factory.setBLabs(address(0));
  }

  function test_SetBLabsWhenTheAddressIsNotZero(address _newBLabs) external whenTheSenderIsTheCurrentBLabs {
    vm.assume(_newBLabs != address(0));

    // it should emit a BLabsSet event
    vm.expectEmit(address(factory));
    emit IBFactory.LOG_BLABS(factoryDeployer, _newBLabs);

    factory.setBLabs(_newBLabs);

    // it should set the new bLabs address
    assertEq(factory.getBLabs(), _newBLabs);
  }

  function test_CollectRevertWhen_TheSenderIsNotTheCurrentBLabs(address _caller) external {
    vm.assume(_caller != factoryDeployer);

    // it should revert
    vm.expectRevert(IBFactory.BFactory_NotBLabs.selector);

    vm.prank(_caller);
    factory.collect(IBPool(makeAddr('pool')));
  }

  function test_CollectWhenTheSenderIsTheCurrentBLabs(uint256 _factoryBTBalance)
    external
    whenTheSenderIsTheCurrentBLabs
  {
    address _mockPool = makeAddr('pool');
    vm.mockCall(_mockPool, abi.encodeCall(IERC20.balanceOf, address(factory)), abi.encode(_factoryBTBalance));
    vm.mockCall(_mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, _factoryBTBalance)), abi.encode(true));

    // it should get the pool's btoken balance of the factory
    vm.expectCall(_mockPool, abi.encodeCall(IERC20.balanceOf, address(factory)));

    // it should transfer the btoken balance of the factory to BLabs
    vm.expectCall(_mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, _factoryBTBalance)));

    factory.collect(IBPool(_mockPool));
  }

  function test_CollectRevertWhen_TheBtokenTransferFails(uint256 _factoryBTBalance)
    external
    whenTheSenderIsTheCurrentBLabs
  {
    address _mockPool = makeAddr('pool');
    vm.mockCall(_mockPool, abi.encodeCall(IERC20.balanceOf, address(factory)), abi.encode(_factoryBTBalance));
    vm.expectCall(_mockPool, abi.encodeCall(IERC20.balanceOf, address(factory)));
    vm.mockCall(_mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, _factoryBTBalance)), abi.encode(false));
    vm.expectCall(_mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, _factoryBTBalance)));

    // it should revert
    vm.expectRevert(abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, _mockPool));

    factory.collect(IBPool(_mockPool));
  }
}
