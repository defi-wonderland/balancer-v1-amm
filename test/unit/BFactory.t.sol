// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {BPool} from 'contracts/BPool.sol';

import {Test} from 'forge-std/Test.sol';
import {IBFactory} from 'interfaces/IBFactory.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {MockBFactory} from 'test/smock/MockBFactory.sol';

contract BFactoryTest_Base is Test {
  address factoryDeployer = makeAddr('factoryDeployer');
  MockBFactory factory;

  function setUp() public virtual {
    vm.prank(factoryDeployer);
    factory = new MockBFactory();
  }
}

contract BFactoryTest_Constructor_WHEN_Called is BFactoryTest_Base {
  function test_THEN_setsDeployerAsBLabs(address _blabs) external {
    vm.prank(_blabs);
    MockBFactory newFactory = new MockBFactory();
    assertEq(newFactory.getBLabs(), _blabs);
  }
}

contract BFactoryTest_NewBPool_WHEN_Called is BFactoryTest_Base {
  address public newBPool = makeAddr('newBPool');
  address public deployer = makeAddr('deployer');

  function setUp() public virtual override {
    super.setUp();
    vm.mockCall(newBPool, abi.encodePacked(IBPool.setController.selector), abi.encode());
    factory.mock_call__newBPool(IBPool(newBPool));
  }

  function test_THEN_itCalls_newBPool() external {
    factory.expectCall__newBPool();
    factory.newBPool();
  }

  function test_THEN_setsControllerAsCaller() external {
    vm.expectCall(newBPool, abi.encodeCall(IBPool.setController, (deployer)));
    vm.prank(deployer);
    factory.newBPool();
  }

  function test_THEN_EmitsPoolCreatedEvent() external {
    vm.expectEmit(address(factory));
    emit IBFactory.LOG_NEW_POOL(deployer, newBPool);
    vm.prank(deployer);
    factory.newBPool();
  }

  function test_THEN_addsPoolToIsBPoolMapping() external {
    vm.prank(deployer);
    factory.newBPool();
    assertTrue(factory.isBPool(address(newBPool)));
  }

  function test_THEN_returnsTheAddressOfTheNewBPool() public {
    vm.prank(deployer);
    IBPool pool = factory.newBPool();
    assertEq(address(pool), newBPool);
  }
}

contract BFactoryTest__newBPool_WHEN_called is BFactoryTest_Base {
  function test_THEN_itDeploysABPool() external {
    address _futurePool = vm.computeCreateAddress(address(factory), 1);
    address _newBPool = address(factory.call__newBPool());
    assertEq(_newBPool, _futurePool);
    assertEq(_newBPool.code, address(new BPool()).code);
  }
}

contract BFactoryTest_SetBLabs_WHEN_CallerIs_NOT_BLabs is BFactoryTest_Base {
  function test_THEN_itReverts(address _caller) external {
    vm.assume(_caller != factoryDeployer);
    vm.expectRevert(IBFactory.BFactory_NotBLabs.selector);
    vm.prank(_caller);
    factory.setBLabs(makeAddr('newBLabs'));
  }
}

contract BFactoryTest_SetBLabs_WHEN_CallerIsBLabs is BFactoryTest_Base {
  function test_THEN_itEmitsALOG_BLABSEvent(address _newBLabs) external {
    vm.expectEmit(address(factory));
    emit IBFactory.LOG_BLABS(factoryDeployer, _newBLabs);
    vm.prank(factoryDeployer);
    factory.setBLabs(_newBLabs);
  }

  function test_THEN_itSetsBLabs(address _newBLabs) external {
    vm.prank(factoryDeployer);
    factory.setBLabs(_newBLabs);
    assertEq(factory.getBLabs(), _newBLabs);
  }
}

contract BFactoryTest_Collect_WHEN_SenderIs_NOT_BLabs is BFactoryTest_Base {
  function test_THEN_itReverts(address _caller) external {
    vm.assume(_caller != factoryDeployer);
    vm.expectRevert(IBFactory.BFactory_NotBLabs.selector);
    vm.prank(_caller);
    factory.collect(IBPool(makeAddr('pool')));
  }
}

contract BFactoryTest_Collect_WHEN_SenderIsBLabs_Base is BFactoryTest_Base {
  address public mockPool = makeAddr('pool');
  uint256 public factoryBalance = 10e18;

  function setUp() public virtual override {
    super.setUp();
    vm.mockCall(mockPool, abi.encodeCall(IERC20.balanceOf, address(factory)), abi.encode(factoryBalance));
    vm.mockCall(mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, factoryBalance)), abi.encode(true));
  }
}

contract BFactoryTest_Collect_WHEN_SenderIsBLabs is BFactoryTest_Collect_WHEN_SenderIsBLabs_Base {
  function test_THEN_BTokenBalanceOfIsCalled() external {
    vm.expectCall(mockPool, abi.encodeCall(IERC20.balanceOf, address(factory)));
    vm.prank(factoryDeployer);
    factory.collect(IBPool(mockPool));
  }

  function test_THEN_BTokenIsTransferred() external {
    vm.expectCall(mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, factoryBalance)));
    vm.prank(factoryDeployer);
    factory.collect(IBPool(mockPool));
  }
}

contract BFactoryTest_Collect_WHEN_ERC20TransferFails is BFactoryTest_Collect_WHEN_SenderIsBLabs_Base {
  function setUp() public virtual override {
    super.setUp();
    vm.mockCall(mockPool, abi.encodeCall(IERC20.transfer, (factoryDeployer, factoryBalance)), abi.encode(false));
  }

  function test_THEN_ItReverts() external {
    vm.expectRevert(abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, mockPool));
    vm.prank(factoryDeployer);
    factory.collect(IBPool(mockPool));
  }
}
