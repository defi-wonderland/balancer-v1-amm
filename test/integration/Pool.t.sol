// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Base} from './Base.sol';
import {BPool} from 'contracts/BPool.sol';

contract IntegrationSwapExactAmountIn is Base {
  BPool public pool;

  function setUp() public override {
    super.setUp();

    vm.startPrank(lp);
    pool = factory.newBPool();

    tokenA.approve(address(pool), type(uint256).max);
    tokenB.approve(address(pool), type(uint256).max);

    pool.bind(address(tokenA), 1e18, 2e18); // 20% weight?
    pool.bind(address(tokenB), 1e18, 8e18); // 80%

    pool.finalize();
    vm.stopPrank();
  }

  function test_SwapExactAmountIn() public {
    vm.startPrank(swapper);
    uint256 _toSwap = 0.5e18;
    tokenA.approve(address(pool), type(uint256).max);

    // swap 0.5 tokenA for tokenB
    snapStart('swapExactAmountIn');
    pool.swapExactAmountIn(address(tokenA), _toSwap, address(tokenB), 0, type(uint256).max);
    snapEnd();

    assertEq(tokenA.balanceOf(address(swapper)), swapperInitialBalanceTokenA - _toSwap);

    vm.stopPrank();
  }
}
