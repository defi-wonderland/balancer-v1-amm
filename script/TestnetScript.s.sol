// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BCoWPool, IBCoWPool, IERC20} from 'contracts/BCoWPool.sol';
import {BPool} from 'contracts/BPool.sol';

import {IFaucet} from 'interfaces/IFaucet.sol';
import {ERC20ForTest} from 'test/for-test/ERC20ForTest.sol';

import {Script} from 'forge-std/Script.sol';

import {SEPOLIA_BAL_TOKEN, SEPOLIA_DAI_TOKEN, SEPOLIA_FAUCET, SEPOLIA_USDC_TOKEN} from 'script/Params.s.sol';
import {TestnetDeployment} from 'script/TestnetDeployment.s.sol';

contract TestnetScript is Script, TestnetDeployment {
  function run() public {
    vm.startBroadcast();
    (, address caller,) = vm.readCallers();

    // NOTE: dripping can be called by anyone but only once a day (per address)
    IFaucet(SEPOLIA_FAUCET).drip(SEPOLIA_BAL_TOKEN);
    IFaucet(SEPOLIA_FAUCET).drip(SEPOLIA_DAI_TOKEN);
    IFaucet(SEPOLIA_FAUCET).drip(SEPOLIA_USDC_TOKEN);

    BPool bPool = bFactory.newBPool();

    IERC20(SEPOLIA_BAL_TOKEN).approve(address(bPool), type(uint256).max);
    IERC20(SEPOLIA_DAI_TOKEN).approve(address(bPool), type(uint256).max);
    IERC20(SEPOLIA_USDC_TOKEN).approve(address(bPool), type(uint256).max);

    bPool.bind(SEPOLIA_BAL_TOKEN, 4e18, 1e18);
    bPool.bind(SEPOLIA_DAI_TOKEN, 1e18, 1e18);
    bPool.bind(SEPOLIA_USDC_TOKEN, 1e6, 1e18);

    bPool.finalize();

    // NOTE: using BCoWPool functions
    BCoWPool bCowPool = BCoWPool(address(bPool));

    bytes32 appData = '';
    bCowPool.enableTrading(appData);

    vm.stopBroadcast();
  }
}
