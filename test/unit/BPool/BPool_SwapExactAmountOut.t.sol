// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BPoolBase} from './BPoolBase.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {BNum} from 'contracts/BNum.sol';
import {IBPool} from 'interfaces/IBPool.sol';

contract BPoolSwapExactAmountOut is BPoolBase, BNum {
  function test_RevertWhen_ReentrancyLockIsSet() external {
    // it should revert
  }

  function test_RevertWhen_PoolIsNotFinalized() external {
    // it should revert
  }

  function test_RevertWhen_TokenInIsNotBound() external {
    // it should revert
  }

  function test_RevertWhen_TokenOutIsNotBound() external {
    // it should revert
  }

  function test_RevertWhen_TokenOutExceedsMaxAllowedRatio() external {
    // it should revert
  }

  function test_RevertWhen_SpotPriceBeforeSwapExceedsMaxPrice() external {
    // it should revert
  }

  function test_RevertWhen_SpotPriceAfterSwapExceedsMaxPrice() external {
    // it should revert
  }

  function test_RevertWhen_RequiredTokenInIsMoreThanMaxAmountIn() external {
    // it should revert
  }

  function test_RevertWhen_TokenRatioAfterSwapExceedsSpotPriceBeforeSwap() external {
    // it should revert
  }

  function test_WhenPreconditionsAreMet() external {
    // it emits a LOG_CALL event
    // it sets the reentrancy lock
    // it emits a LOG_SWAP event
    // it calls _pullUnderlying for tokenIn
    // it calls _pushUnderlying for tokenOut
    // it returns the tokenIn amount swapped
    // it returns the spot price after the swap
    // it clears the reeentrancy lock
  }
}
