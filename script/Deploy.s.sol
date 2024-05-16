// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BFactory} from 'contracts/BFactory.sol';
import {Params} from 'script/Params.s.sol';

import {Script} from 'forge-std/Script.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract Deploy is Script, Params {
  function run() public {
    DeploymentParams memory _params = _deploymentParams[block.chainid];

    vm.startBroadcast();
    BFactory bFactory = new BFactory(_params.cowSwap);
    bFactory.setBLabs(_params.bLabs);
    vm.stopBroadcast();
  }
}
