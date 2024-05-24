// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BFactory} from 'contracts/BFactory.sol';

contract TestnetDeployment {
  BFactory public bFactory;

  constructor() {
    bFactory = BFactory(0x822CA05014A815Eba5349e625D6D1CA984Bbcf9B);

    // tokenA = ERC20ForTest(0x016e12e047000018968deAc699bD3b8687b4f6Fe)
    // tokenB = ERC20ForTest(0xEB9F3Df5A9b93E50F205cbCEd0b8C32AF053af75)
    // tokenC = ERC20ForTest(0xd80f2Dd0D8617571b26015f6814941A3BEeaA367)
  }
}
