// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {EchidnaTest} from '../helpers/AdvancedTestsUtils.sol';
import {BMath} from 'contracts/BMath.sol';

contract FuzzBMath is EchidnaTest {
  BMath bMath;

  uint256 immutable MIN_WEIGHT;
  uint256 immutable MAX_WEIGHT;
  uint256 immutable MIN_FEE;
  uint256 immutable MAX_FEE;

  uint256 constant MAX_BALANCE = 1_000_000e18;
  uint256 constant MIN_BALANCE = 1e18;
  uint256 constant MAX_TOLERANCE = 1e12;

  constructor() {
    bMath = new BMath();

    MIN_WEIGHT = bMath.MIN_WEIGHT();
    MAX_WEIGHT = bMath.MAX_WEIGHT();
    MIN_FEE = bMath.MIN_FEE();
    MAX_FEE = bMath.MAX_FEE();
  }

  // calcOutGivenIn should be inverse of calcInGivenOut
  function testCalcInGivenOut_InvCalcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) public view {
    tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT);
    tokenWeightOut = clamp(tokenWeightOut, MIN_WEIGHT, MAX_WEIGHT);
    tokenAmountIn = clamp(tokenAmountIn, MIN_BALANCE, MAX_BALANCE);
    tokenBalanceOut = clamp(tokenBalanceOut, MIN_BALANCE, MAX_BALANCE);
    tokenBalanceIn = clamp(tokenBalanceIn, MIN_BALANCE, MAX_BALANCE);
    swapFee = clamp(swapFee, MIN_FEE, MAX_FEE);

    uint256 calc_tokenAmountOut =
      bMath.calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee);

    uint256 calc_tokenAmountIn =
      bMath.calcInGivenOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, calc_tokenAmountOut, swapFee);

    assert(
      calc_tokenAmountOut < MIN_BALANCE // return amount too small
        || tokenAmountIn == calc_tokenAmountIn // exact match
        || tokenAmountIn > calc_tokenAmountIn // within tolerance
        ? (tokenAmountIn * 1e18 / calc_tokenAmountIn) - 1e18 <= MAX_TOLERANCE
        : (calc_tokenAmountIn * 1e18 / tokenAmountIn) - 1e18 <= MAX_TOLERANCE
    );
  }

  // calcInGivenOut should be inverse of calcOutGivenIn
  function testCalcOutGivenIn_InvCalcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) public view {
    tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT);
    tokenWeightOut = clamp(tokenWeightOut, MIN_WEIGHT, MAX_WEIGHT);
    tokenAmountOut = clamp(tokenAmountOut, MIN_BALANCE, MAX_BALANCE);
    tokenBalanceOut = clamp(tokenBalanceOut, MIN_BALANCE, MAX_BALANCE);
    tokenBalanceIn = clamp(tokenBalanceIn, MIN_BALANCE, MAX_BALANCE);
    swapFee = clamp(swapFee, MIN_FEE, MAX_FEE);

    uint256 calc_tokenAmountIn =
      bMath.calcInGivenOut(tokenBalanceOut, tokenWeightOut, tokenBalanceIn, tokenWeightIn, tokenAmountOut, swapFee);

    uint256 calc_tokenAmountOut =
      bMath.calcOutGivenIn(tokenBalanceOut, tokenWeightOut, tokenBalanceIn, tokenWeightIn, calc_tokenAmountIn, swapFee);

    assert(
      calc_tokenAmountIn < MIN_BALANCE // return amount too small
        || tokenAmountOut == calc_tokenAmountOut // exact match
        || tokenAmountOut > calc_tokenAmountOut // within tolerance
        ? (tokenAmountOut * 1e18 / calc_tokenAmountOut) - 1e18 <= MAX_TOLERANCE
        : (calc_tokenAmountOut * 1e18 / tokenAmountOut) - 1e18 <= MAX_TOLERANCE
    );
  }
}
