// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BPoolBase} from './BPoolBase.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {BNum} from 'contracts/BNum.sol';
import {IBPool} from 'interfaces/IBPool.sol';

contract BPoolSwapExactAmountIn is BPoolBase, BNum {
  // Valid scenario
  address public tokenIn = token;
  uint256 public tokenAmountIn = 3e18;

  uint256 public tokenInBalance = 10e18;
  uint256 public tokenOutBalance = 40e18;
  // pool is expected to keep 2X the value of tokenIn than tokenOut
  uint256 public tokenInWeight = 2e18;
  uint256 public tokenOutWeight = 1e18;

  address public tokenOut = secondToken;
  // (tokenInBalance / tokenInWeight) / (tokenOutBalance/ tokenOutWeight)
  uint256 public spotPriceBeforeSwapWithoutFee = 0.125e18;
  uint256 public spotPriceBeforeSwap = bmul(spotPriceBeforeSwapWithoutFee, bdiv(BONE, bsub(BONE, MIN_FEE)));
  // from bmath: 40*(1-(10/(10+3*(1-10^-6)))^2)
  uint256 public expectedAmountOut = 16.3313500227545254e18;
  // (tokenInBalance / tokenInWeight) / (tokenOutBalance/ tokenOutWeight)
  // (13 / 2) / (40-expectedAmountOut/ 1)
  uint256 public spotPriceAfterSwapWithoutFee = 0.274624873250014625e18;
  uint256 public spotPriceAfterSwap = bmul(spotPriceAfterSwapWithoutFee, bdiv(BONE, bsub(BONE, MIN_FEE)));

  function setUp() public virtual override {
    super.setUp();
    bPool.set__finalized(true);
    address[] memory _tokens = new address[](2);
    _tokens[0] = tokenIn;
    _tokens[1] = tokenOut;
    bPool.set__tokens(_tokens);
    _setRecord(tokenIn, IBPool.Record({bound: true, index: 0, denorm: tokenInWeight}));
    _setRecord(tokenOut, IBPool.Record({bound: true, index: 1, denorm: tokenOutWeight}));

    vm.mockCall(tokenIn, abi.encodePacked(IERC20.balanceOf.selector), abi.encode(uint256(tokenInBalance)));
    vm.mockCall(tokenOut, abi.encodePacked(IERC20.balanceOf.selector), abi.encode(uint256(tokenOutBalance)));
  }

  function test_RevertWhen_ReentrancyLockIsSet() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    // it should revert
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    bPool.swapExactAmountIn(tokenIn, tokenAmountIn, tokenOut, expectedAmountOut, spotPriceAfterSwap);
  }

  function test_RevertWhen_PoolIsNotFinalized() external {
    bPool.set__finalized(false);
    // it should revert
    vm.expectRevert(IBPool.BPool_PoolNotFinalized.selector);
    bPool.swapExactAmountIn(tokenIn, tokenAmountIn, tokenOut, expectedAmountOut, spotPriceAfterSwap);
  }

  function test_RevertWhen_TokenInIsNotBound() external {
    // it should revert
    vm.expectRevert(IBPool.BPool_TokenNotBound.selector);
    bPool.swapExactAmountIn(makeAddr('unknown token'), tokenAmountIn, tokenOut, expectedAmountOut, spotPriceAfterSwap);
  }

  function test_RevertWhen_TokenOutIsNotBound() external {
    // it should revert
    vm.expectRevert(IBPool.BPool_TokenNotBound.selector);
    bPool.swapExactAmountIn(tokenIn, tokenAmountIn, makeAddr('unknown token'), expectedAmountOut, spotPriceAfterSwap);
  }

  function test_RevertWhen_TokenAmountInExceedsMaxAllowedRatio(uint256 tokenAmountIn_) external {
    tokenAmountIn_ = bound(tokenAmountIn_, bmul(tokenInBalance, MAX_IN_RATIO) + 1, type(uint256).max);
    // it should revert
    vm.expectRevert(IBPool.BPool_TokenAmountInAboveMaxRatio.selector);
    bPool.swapExactAmountIn(tokenIn, tokenAmountIn_, tokenOut, 0, 0);
  }

  function test_RevertWhen_SpotPriceBeforeSwapExceedsMaxPrice() external {
    // it should revert
    vm.expectRevert(IBPool.BPool_SpotPriceAboveMaxPrice.selector);
    bPool.swapExactAmountIn(tokenIn, tokenAmountIn, tokenOut, expectedAmountOut, spotPriceBeforeSwap - 1);
  }

  function test_RevertWhen_CalculatedTokenAmountOutIsLessThanMinAmountOut() external {
    // it should revert
    vm.expectRevert(IBPool.BPool_TokenAmountOutBelowMinOut.selector);
    bPool.swapExactAmountIn(tokenIn, tokenAmountIn, tokenOut, expectedAmountOut + 1, spotPriceAfterSwap);
  }

  function test_RevertWhen_SpotPriceAfterSwapExceedsMaxPrice() external {
    // it should revert
    vm.expectRevert(IBPool.BPool_SpotPriceAboveMaxPrice.selector);
    bPool.swapExactAmountIn(tokenIn, tokenAmountIn, tokenOut, expectedAmountOut, spotPriceAfterSwap - 1);
  }

  function test_RevertWhen_SpotPriceBeforeSwapExceedsTokenRatioAfterSwap() external {
    // it should revert
    vm.skip(true);
  }

  function test_WhenPreconditionsAreMet() external {
    // it sets reentrancy lock
    bPool.expectCall__setLock(_MUTEX_TAKEN);
    // it calls _pullUnderlying for tokenIn
    bPool.mock_call__pullUnderlying(tokenIn, address(this), tokenAmountIn);
    bPool.expectCall__pullUnderlying(tokenIn, address(this), tokenAmountIn);
    // it calls _pushUnderlying for tokenOut
    bPool.mock_call__pushUnderlying(tokenOut, address(this), expectedAmountOut);
    bPool.expectCall__pushUnderlying(tokenOut, address(this), expectedAmountOut);
    // it emits a LOG_CALL event
    bytes memory _data = abi.encodeCall(
      IBPool.swapExactAmountIn, (tokenIn, tokenAmountIn, tokenOut, expectedAmountOut, spotPriceAfterSwap)
    );
    vm.expectEmit();
    emit IBPool.LOG_CALL(IBPool.swapExactAmountIn.selector, address(this), _data);
    // it emits a LOG_SWAP event
    vm.expectEmit();
    emit IBPool.LOG_SWAP(address(this), tokenIn, tokenOut, tokenAmountIn, expectedAmountOut);

    // it returns the tokenOut amount swapped
    // it returns the spot price after the swap
    (uint256 out, uint256 priceAfter) =
      bPool.swapExactAmountIn(tokenIn, tokenAmountIn, tokenOut, expectedAmountOut, spotPriceAfterSwap);
    assertEq(out, expectedAmountOut);
    assertEq(priceAfter, spotPriceAfterSwap);
    // it clears the reeentrancy lock
    assertEq(bPool.call__getLock(), _MUTEX_FREE);
  }
}
