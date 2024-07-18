// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

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

  function test_ConstructorWhenCalled(address _bDao) external {
    vm.prank(_bDao);
    MockBFactory newFactory = new MockBFactory();
    // it should set BDao
    assertEq(newFactory.getBDao(), _bDao);
  }

  function test_NewBPoolWhenCalled(address _deployer) external {
    address _newBPool = vm.computeCreateAddress(address(factory), 1);
    // it should call _newBPool
    factory.expectCall__newBPool();
    // it should set the controller of the newBPool to the caller
    vm.expectCall(_newBPool, abi.encodeCall(IBPool.setController, (_deployer)));
    // it should emit a PoolCreated event
    vm.expectEmit(address(factory));
    emit IBFactory.LOG_NEW_POOL(_deployer, _newBPool);

    vm.prank(_deployer);
    IBPool pool = factory.newBPool();
    vm.prank(address(factory)); // bpool has immutable FACTORY
    bytes memory expectedCode = address(new BPool()).code;

    // it should deploy a new BPool
    assertEq(address(pool).code, expectedCode);

    // it should add the newBPool to the list of pools
    assertTrue(factory.isBPool(address(_newBPool)));
    // it should return the address of the new BPool
    assertEq(address(pool), _newBPool);
  }

  function test_SetBDaoRevertWhen_TheSenderIsNotTheCurrentBDao(address _caller) external {
    vm.assume(_caller != factoryDeployer);

    // it should revert
    vm.expectRevert(IBFactory.BFactory_NotBDao.selector);

    vm.prank(_caller);
    factory.setBDao(makeAddr('newBDao'));
  }

  modifier whenTheSenderIsTheCurrentBDao() {
    vm.startPrank(factoryDeployer);
    _;
  }

  function test_SetBDaoRevertWhen_TheAddressIsZero() external whenTheSenderIsTheCurrentBDao {
    // it should revert
    vm.expectRevert(IBFactory.BFactory_AddressZero.selector);

    factory.setBDao(address(0));
  }

  function test_SetBDaoWhenTheAddressIsNotZero(address _newBDao) external whenTheSenderIsTheCurrentBDao {
    vm.assume(_newBDao != address(0));

    // it should emit a BDaoSet event
    vm.expectEmit(address(factory));
    emit IBFactory.LOG_BDAO(factoryDeployer, _newBDao);

    factory.setBDao(_newBDao);

    // it should set the new bDao address
    assertEq(factory.getBDao(), _newBDao);
  }

  function test_CollectRevertWhen_TheSenderIsNotTheCurrentBDao(address _caller) external {
    vm.assume(_caller != factoryDeployer);

    // it should revert
    vm.expectRevert(IBFactory.BFactory_NotBDao.selector);

    vm.prank(_caller);
    factory.collect(IBPool(makeAddr('pool')));
  }

  function test_CollectWhenTheSenderIsTheCurrentBDao(uint256 _factoryBTBalance) external whenTheSenderIsTheCurrentBDao {
    address _mockPool = makeAddr('pool');
    vm.mockCall(_mockPool, abi.encodeCall(IERC20.balanceOf, address(factory)), abi.encode(_factoryBTBalance));
    vm.mockCall(_mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, _factoryBTBalance)), abi.encode(true));

    // it should get the pool's btoken balance of the factory
    vm.expectCall(_mockPool, abi.encodeCall(IERC20.balanceOf, address(factory)));

    // it should transfer the btoken balance of the factory to BDao
    vm.expectCall(_mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, _factoryBTBalance)));

    factory.collect(IBPool(_mockPool));
  }

  function test_CollectRevertWhen_TheBtokenTransferFails(uint256 _factoryBTBalance)
    external
    whenTheSenderIsTheCurrentBDao
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
