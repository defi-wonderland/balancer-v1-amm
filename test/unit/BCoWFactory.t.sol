// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BCoWPool} from 'contracts/BCoWPool.sol';
import {Test} from 'forge-std/Test.sol';
import {IBCoWFactory} from 'interfaces/IBCoWFactory.sol';
import {IBCoWPool} from 'interfaces/IBCoWPool.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';
import {MockBCoWFactory} from 'test/manual-smock/MockBCoWFactory.sol';

contract BCoWFactoryTest is Test {
  address public factoryDeployer = makeAddr('factoryDeployer');
  address public solutionSettler = makeAddr('solutionSettler');
  bytes32 public appData = bytes32('appData');

  MockBCoWFactory factory;

  function setUp() external {
    vm.prank(factoryDeployer);
    factory = new MockBCoWFactory(solutionSettler, appData);
    vm.mockCall(solutionSettler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(bytes32(0)));
    vm.mockCall(
      solutionSettler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(makeAddr('vault relayer'))
    );
  }

  function test_ConstructorWhenCalled(address _blabs, address _newSettler, bytes32 _appData) external {
    vm.prank(_blabs);
    MockBCoWFactory _newFactory = new MockBCoWFactory(_newSettler, _appData);
    // it should set solution settler
    assertEq(_newFactory.SOLUTION_SETTLER(), _newSettler);
    // it should set app data
    assertEq(_newFactory.APP_DATA(), _appData);
    // it should set blabs
    assertEq(_newFactory.getBLabs(), _blabs);
  }

  function test__newBPoolWhenCalled() external {
    bytes memory _expectedCode = address(new BCoWPool(solutionSettler, appData)).code;
    IBCoWPool _newPool = IBCoWPool(address(factory.call__newBPool()));
    // it should set the new BCoWPool solution settler
    assertEq(address(_newPool.SOLUTION_SETTLER()), solutionSettler);
    // it should set the new BCoWPool app data
    assertEq(_newPool.APP_DATA(), appData);
    // it should deploy a new BCoWPool
    assertEq(address(_newPool).code, _expectedCode);
  }

  function test_LogBCowPoolRevertWhen_TheSenderIsNotAValidPool(address _caller) external {
    // it should revert
    vm.expectRevert(IBCoWFactory.BCoWFactory_NotValidBCoWPool.selector);
    vm.prank(_caller);
    factory.logBCoWPool();
  }

  function test_LogBCowPoolWhenTheSenderIsAValidPool(address _pool) external {
    factory.set__isBPool(address(_pool), true);
    // it should emit a COWAMMPoolCreated event
    vm.expectEmit(address(factory));
    emit IBCoWFactory.COWAMMPoolCreated(_pool);
    vm.prank(_pool);
    IBCoWFactory(address(factory)).logBCoWPool();
  }
}
