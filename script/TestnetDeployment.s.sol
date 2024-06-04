// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BFactory} from 'contracts/BFactory.sol';

contract TestnetDeployment {
  BFactory public bFactory;

  constructor() {
    bFactory = BFactory(0xD689e9ba3b24D9a5Eee3d965E2681EC4d8839daE);
  }
}
