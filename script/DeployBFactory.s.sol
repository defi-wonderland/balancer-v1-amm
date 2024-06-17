// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BFactory} from 'contracts/BFactory.sol';
import {Script} from 'forge-std/Script.sol';
import {Params} from 'script/Params.s.sol';

contract DeployBFactory is Script, Params {
  function run() public {
    BFactoryDeploymentParams memory _params = _bFactoryDeploymentParams[block.chainid];

    vm.startBroadcast(_deployer[block.chainid]);
    BFactory bFactory = new BFactory();
    bFactory.setBLabs(_params.bLabs);
    vm.stopBroadcast();
  }
}
