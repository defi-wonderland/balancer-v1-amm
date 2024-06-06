// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BFactory} from 'contracts/BFactory.sol';

import {GasSnapshot} from 'forge-gas-snapshot/GasSnapshot.sol';
import {Test} from 'forge-std/Test.sol';

contract DeploymentIntegrationTest is Test, GasSnapshot {
  BFactory public factory;

  function setUp() public {
    factory = new BFactory();
  }

  function testFactoryDeployment() public {
    snapStart('newBFactory');
    new BFactory();
    snapEnd();
  }

  function testDeployment() public {
    snapStart('newBPool');
    factory.newBPool();
    snapEnd();
  }
}
