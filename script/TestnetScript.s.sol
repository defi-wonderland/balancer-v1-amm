// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IBPool} from 'contracts/BPool.sol';
import {IBFactory} from 'interfaces/IBFactory.sol';
import {IFaucet} from 'interfaces/IFaucet.sol';

import {Script} from 'forge-std/Script.sol';
import {Params} from 'script/Params.s.sol';

contract TestnetScript is Script, Params {
  /// @notice BFactory contract deployment address
  IBFactory public bFactory = IBFactory(address(0xb024fC7EAB6707A094c06C646be343a54096EB98));

  function run() public {
    vm.startBroadcast();
    // NOTE: dripping can be called by anyone but only once a day (per address)
    IFaucet(_SEPOLIA_FAUCET).drip(_SEPOLIA_BAL_TOKEN);
    IFaucet(_SEPOLIA_FAUCET).drip(_SEPOLIA_DAI_TOKEN);
    IFaucet(_SEPOLIA_FAUCET).drip(_SEPOLIA_USDC_TOKEN);

    IBPool bPool = bFactory.newBPool();

    IERC20(_SEPOLIA_BAL_TOKEN).approve(address(bPool), type(uint256).max);
    IERC20(_SEPOLIA_DAI_TOKEN).approve(address(bPool), type(uint256).max);
    IERC20(_SEPOLIA_USDC_TOKEN).approve(address(bPool), type(uint256).max);

    bPool.bind(_SEPOLIA_BAL_TOKEN, 4e18, 1e18);
    bPool.bind(_SEPOLIA_DAI_TOKEN, 1e18, 1e18);
    bPool.bind(_SEPOLIA_USDC_TOKEN, 1e6, 1e18);

    bPool.finalize();
    vm.stopBroadcast();
  }
}
