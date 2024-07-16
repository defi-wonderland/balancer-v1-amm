// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EchidnaTest} from '../helpers/AdvancedTestsUtils.sol';

import {BMath} from 'contracts/BMath.sol';

contract EchidnaBMath is BMath, EchidnaTest {
  // calcOutGivenIn should be inverse of calcInGivenOut
  function testCalcInGivenOut_InvCalcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) public {
    tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT);
    tokenWeightOut = clamp(tokenWeightOut, MIN_WEIGHT, MAX_WEIGHT);
    tokenBalanceIn = clamp(tokenBalanceIn, 1, type(uint256).max);

    uint256 calc_tokenAmountOut =
      calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee);

    uint256 calc_tokenAmountIn =
      calcInGivenOut(tokenBalanceOut, tokenWeightOut, tokenBalanceIn, tokenWeightIn, calc_tokenAmountOut, swapFee);

    assert(tokenAmountIn == calc_tokenAmountIn);
  }

  event log_uint(uint256 value);

  function test_debug() public {
    uint256 tokenBalanceIn = 0;
    uint256 tokenWeightIn = 0;
    uint256 tokenBalanceOut = 0;
    uint256 tokenWeightOut = 0;
    uint256 tokenAmountIn = 1;
    uint256 swapFee = 0;

    tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT);
    tokenWeightOut = clamp(tokenWeightOut, MIN_WEIGHT, MAX_WEIGHT);
    tokenAmountIn = clamp(tokenAmountIn, 1, type(uint256).max);
    tokenBalanceOut = clamp(tokenBalanceOut, 1, type(uint256).max);
    tokenBalanceIn = clamp(tokenBalanceIn, 1, type(uint256).max);
    swapFee = clamp(swapFee, MIN_FEE, MAX_FEE);

    emit log_uint(tokenWeightIn);
    emit log_uint(tokenWeightOut);
    emit log_uint(tokenAmountIn);
    emit log_uint(tokenBalanceOut);
    emit log_uint(tokenBalanceIn);
    emit log_uint(swapFee);

    uint256 calc_tokenAmountOut =
      calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee);
    emit log_uint(calc_tokenAmountOut);

    uint256 calc_tokenAmountIn =
      calcInGivenOut(tokenBalanceOut, tokenWeightOut, tokenBalanceIn, tokenWeightIn, calc_tokenAmountOut, swapFee);

    emit log_uint(calc_tokenAmountIn);
    assert(calc_tokenAmountOut == calc_tokenAmountIn);
  }

  // calcInGivenOut should be inverse of calcOutGivenIn
  function testCalcOutGivenIn_InvCalcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) public {
    tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT);
    tokenWeightOut = clamp(tokenWeightOut, MIN_WEIGHT, MAX_WEIGHT);

    uint256 calc_tokenAmountIn =
      calcInGivenOut(tokenBalanceOut, tokenWeightOut, tokenBalanceIn, tokenWeightIn, tokenAmountOut, swapFee);

    uint256 calc_tokenAmountOut =
      calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, calc_tokenAmountIn, swapFee);

    assert(tokenAmountOut == calc_tokenAmountOut);
  }

  // calcSingleInGivenPoolOut should be inverse of calcPoolOutGivenSingleIn
  function testCalcSingleInGivenPoolOut_InvCalcPoolOutGivenSingle(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) public {
    tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT);
    totalWeight = clamp(totalWeight, MIN_WEIGHT, MAX_TOTAL_WEIGHT);
    tokenBalanceIn = clamp(tokenBalanceIn, 1, type(uint256).max);

    uint256 calc_tokenAmountIn =
      calcSingleInGivenPoolOut(tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, tokenAmountOut, swapFee);

    uint256 calc_poolAmountOut =
      calcPoolOutGivenSingleIn(tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, calc_tokenAmountIn, swapFee);

    assert(tokenAmountOut == calc_poolAmountOut);
  }

  // calcPoolOutGivenSingleIn should be inverse of calcSingleInGivenPoolOut
  function testCalcPoolOutGivenSingle_InvCalcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) public {
    tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT);
    totalWeight = clamp(totalWeight, MIN_WEIGHT, MAX_TOTAL_WEIGHT);
    tokenBalanceIn = clamp(tokenBalanceIn, 1, type(uint256).max);

    uint256 calc_poolAmountIn =
      calcPoolOutGivenSingleIn(tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, poolAmountOut, swapFee);

    uint256 calc_tokenAmountOut =
      calcSingleInGivenPoolOut(tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, calc_poolAmountIn, swapFee);

    assert(poolAmountOut == calc_tokenAmountOut);
  }
}
