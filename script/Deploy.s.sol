// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BCoWFactory} from 'contracts/BCoWFactory.sol';
import {BFactory} from 'contracts/BFactory.sol';
import {IBFactory} from 'interfaces/IBFactory.sol';

import {Script} from 'forge-std/Script.sol';
import {Params} from 'script/Params.s.sol';

abstract contract DeployBaseFactory is Script, Params {
  function run() public {
    vm.startBroadcast();
    _deployFactory();
    vm.stopBroadcast();
  }

  function _deployFactory() internal virtual returns (IBFactory);
}

contract DeployBFactory is DeployBaseFactory {
  function _deployFactory() internal override returns (IBFactory bFactory) {
    BFactoryDeploymentParams memory bParams = _bFactoryDeploymentParams[block.chainid];
    bFactory = new BFactory();
    bFactory.setBLabs(bParams.bLabs);
  }
}

contract DeployBCoWFactory is DeployBaseFactory {
  function _deployFactory() internal override returns (IBFactory bFactory) {
    BFactoryDeploymentParams memory bParams = _bFactoryDeploymentParams[block.chainid];
    BCoWFactoryDeploymentParams memory bCoWParams = _bCoWFactoryDeploymentParams[block.chainid];
    bFactory = new BCoWFactory(bCoWParams.settlement, bCoWParams.appData);
    bFactory.setBLabs(bParams.bLabs);
  }
}
