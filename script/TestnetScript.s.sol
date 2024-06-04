// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BCoWPool, IBCoWPool, IERC20} from 'contracts/BCoWPool.sol';
import {BPool} from 'contracts/BPool.sol';
import {ERC20ForTest} from 'test/for-test/ERC20ForTest.sol';

import {Script} from 'forge-std/Script.sol';
import {TestnetDeployment} from 'script/TestnetDeployment.s.sol';

contract TestnetScript is Script, TestnetDeployment {
  function run() public {
    vm.startBroadcast();
    (, address caller,) = vm.readCallers();

    ERC20ForTest tokenA = new ERC20ForTest('TokenA', 'TKA', 18);
    ERC20ForTest tokenB = new ERC20ForTest('TokenB', 'TKB', 18);
    ERC20ForTest tokenC = new ERC20ForTest('TokenC', 'TKC', 18);

    tokenA.mint(caller, 1e18);
    tokenB.mint(caller, 1e18);
    tokenC.mint(caller, 1e18);

    BPool bPool = bFactory.newBPool();

    tokenA.approve(address(bPool), 1e18);
    tokenB.approve(address(bPool), 1e18);
    tokenC.approve(address(bPool), 1e18);

    bPool.bind(address(tokenA), 1e18, 1e18);
    bPool.bind(address(tokenB), 1e18, 1e18);
    bPool.bind(address(tokenC), 1e18, 1e18);

    bPool.finalize();

    // NOTE: using BCoWPool functions
    BCoWPool bCowPool = BCoWPool(address(bPool));

    bytes32 appData = '';
    bCowPool.enableTrading(appData);

    vm.stopBroadcast();
  }
}
