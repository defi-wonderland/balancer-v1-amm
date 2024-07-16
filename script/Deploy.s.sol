// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BCoWFactory} from 'contracts/BCoWFactory.sol';
import {BFactory} from 'contracts/BFactory.sol';
import {IBFactory} from 'interfaces/IBFactory.sol';

import {Script} from 'forge-std/Script.sol';
import {Params} from 'script/Params.s.sol';

abstract contract DeployBaseFactory is Script, Params {
  constructor() Params(block.chainid) {}

  function run() public {
    vm.startBroadcast();
    IBFactory bFactory = _deployFactory();
    bFactory.setBDao(_bFactoryDeploymentParams.bDao);
    vm.stopBroadcast();
  }

  function _deployFactory() internal virtual returns (IBFactory);
}

contract DeployBFactory is DeployBaseFactory {
  function _deployFactory() internal override returns (IBFactory bFactory) {
    bFactory = new BFactory();
  }
}

contract DeployBCoWFactory is DeployBaseFactory {
  function _deployFactory() internal override returns (IBFactory bFactory) {
    bFactory = new BCoWFactory({
      solutionSettler: _bCoWFactoryDeploymentParams.settlement,
      appData: _bCoWFactoryDeploymentParams.appData
    });
  }
}
