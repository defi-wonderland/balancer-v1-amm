// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BCoWFactory} from 'contracts/BCoWFactory.sol';
import {BFactory} from 'contracts/BFactory.sol';

import {Params} from 'script/Params.s.sol';

contract Registry is Params {
  BFactory public bFactory;
  BCoWFactory public bCoWFactory;

  constructor(uint256 chainId) Params(chainId) {
    if (chainId == 1) {
      // Ethereum Mainnet
      bFactory = BFactory(0xaD0447be7BDC80cf2e6DA20B13599E5dc859b667);
      bCoWFactory = BCoWFactory(0x21Cd97D70f8475DF3d62917880aF9f41D9a9dCeF);
    } else if (chainId == 11_155_111) {
      // Ethereum Sepolia [Testnet]
      bFactory = BFactory(0x2bfA24B26B85DD812b2C69E3B1cb4C85C886C8E2);
      bCoWFactory = BCoWFactory(0xe8587525430fFC9193831e1113a672f3133C1B8A);
    }
  }
}
