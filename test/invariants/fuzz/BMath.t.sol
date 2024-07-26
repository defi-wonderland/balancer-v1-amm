// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {EchidnaTest} from '../helpers/AdvancedTestsUtils.sol';

import {BMath} from 'contracts/BMath.sol';

contract FuzzBMath is EchidnaTest {
  event Log(string label, uint256 number);

  BMath bmath;

  uint256 BONE = 10 ** 18;
  uint256 MIN_WEIGHT;
  uint256 MAX_WEIGHT;
  uint256 MAX_TOTAL_WEIGHT;
  uint256 MIN_FEE;
  uint256 MAX_FEE;

  constructor() {
    bmath = new BMath();

    MIN_WEIGHT = bmath.MIN_WEIGHT();
    MAX_WEIGHT = bmath.MAX_WEIGHT();
    MAX_TOTAL_WEIGHT = bmath.MAX_TOTAL_WEIGHT();
    MIN_FEE = 0.25e18; //bmath.MIN_FEE();
    MAX_FEE = bmath.MAX_FEE();
  }

  // // calcOutGivenIn should be inverse of calcInGivenOut
  // function testCalcInGivenOut_InvCalcInGivenOut(
  //   uint256 tokenBalanceIn,
  //   uint256 tokenWeightIn,
  //   uint256 tokenBalanceOut,
  //   uint256 tokenWeightOut,
  //   uint256 tokenAmountIn,
  //   uint256 swapFee
  // ) public {
  //   tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT);
  //   tokenWeightOut = clamp(tokenWeightOut, MIN_WEIGHT, MAX_WEIGHT);
  //   tokenAmountIn = clamp(tokenAmountIn, BONE, 1_000_000 ether);
  //   tokenBalanceIn = clamp(tokenBalanceIn, BONE, type(uint256).max);
  //   tokenBalanceOut = clamp(tokenBalanceOut, BONE, type(uint256).max);
  //   swapFee = clamp(swapFee, MIN_FEE, MAX_FEE);

  //   emit Log('tokenAmountIn', tokenAmountIn);

  //   uint256 calc_tokenAmountOut =
  //     bmath.calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee);
  //   emit Log('calc_tokenAmountOut', calc_tokenAmountOut);

  //   uint256 calc_tokenAmountIn =
  //     bmath.calcInGivenOut(tokenBalanceOut, tokenWeightOut, tokenBalanceIn, tokenWeightIn, calc_tokenAmountOut, swapFee);
  //   emit Log('calc_tokenAmountIn', calc_tokenAmountIn);

  //   assert(
  //     tokenAmountIn == calc_tokenAmountIn || tokenAmountIn > calc_tokenAmountIn
  //       ? tokenAmountIn - calc_tokenAmountIn < BONE
  //       : calc_tokenAmountIn - tokenAmountIn < BONE
  //   );
  // }

  // // calcInGivenOut should be inverse of calcOutGivenIn
  // function testCalcOutGivenIn_InvCalcOutGivenIn(
  //   uint256 tokenBalanceIn,
  //   uint256 tokenWeightIn,
  //   uint256 tokenBalanceOut,
  //   uint256 tokenWeightOut,
  //   uint256 tokenAmountOut,
  //   uint256 swapFee
  // ) public {
  //   tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT);
  //   tokenWeightOut = clamp(tokenWeightOut, MIN_WEIGHT, MAX_WEIGHT);
  //   tokenAmountOut = clamp(tokenAmountOut, BONE, 1_000_000 ether);
  //   tokenBalanceIn = clamp(tokenBalanceIn, BONE, type(uint256).max);
  //   tokenBalanceOut = clamp(tokenBalanceOut, BONE, type(uint256).max);

  //   emit Log('tokenAmountOut', tokenAmountOut);

  //   uint256 calc_tokenAmountIn =
  //     bmath.calcInGivenOut(tokenBalanceOut, tokenWeightOut, tokenBalanceIn, tokenWeightIn, tokenAmountOut, swapFee);
  //   emit Log('calc_tokenAmountIn', calc_tokenAmountIn);

  //   uint256 calc_tokenAmountOut =
  //     bmath.calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, calc_tokenAmountIn, swapFee);
  //   emit Log('calc_tokenAmountOut', calc_tokenAmountOut);

  //   assert(tokenAmountOut == calc_tokenAmountOut);
  // }

  // // calcSingleInGivenPoolOut should be inverse of calcPoolOutGivenSingleIn
  // function testCalcSingleInGivenPoolOut_InvCalcPoolOutGivenSingle(
  //   uint256 tokenBalanceIn,
  //   uint256 tokenWeightIn,
  //   uint256 poolSupply,
  //   uint256 totalWeight,
  //   uint256 tokenAmountOut,
  //   uint256 swapFee
  // ) public {
  //   tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT);
  //   totalWeight = clamp(totalWeight, MIN_WEIGHT, MAX_TOTAL_WEIGHT);
  //   tokenBalanceIn = clamp(tokenBalanceIn, BONE, type(uint256).max);

  //   emit Log('tokenAmountOut', tokenAmountOut);

  //   uint256 calc_tokenAmountIn =
  //     bmath.calcSingleInGivenPoolOut(tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, tokenAmountOut, swapFee);
  //   emit Log('calc_tokenAmountIn', calc_tokenAmountIn);

  //   uint256 calc_poolAmountOut = bmath.calcPoolOutGivenSingleIn(
  //     tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, calc_tokenAmountIn, swapFee
  //   );
  //   emit Log('calc_poolAmountOut', calc_poolAmountOut);

  //   assert(tokenAmountOut >= calc_poolAmountOut);
  // }

  // // calcPoolOutGivenSingleIn should be inverse of calcSingleInGivenPoolOut
  // function testCalcPoolOutGivenSingle_InvCalcSingleInGivenPoolOut(
  //   uint256 tokenBalanceIn,
  //   uint256 tokenWeightIn,
  //   uint256 poolSupply,
  //   uint256 totalWeight,
  //   uint256 tokenAmountIn,
  //   uint256 swapFee
  // ) public {
  //   tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT);
  //   totalWeight = clamp(totalWeight, MIN_WEIGHT, MAX_TOTAL_WEIGHT);
  //   tokenBalanceIn = clamp(tokenBalanceIn, BONE, type(uint256).max);

  //   emit Log('tokenAmountIn', tokenAmountIn);

  //   uint256 calc_poolAmountOut =
  //     bmath.calcPoolOutGivenSingleIn(tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, tokenAmountIn, swapFee);
  //   emit Log('calc_poolAmountOut', calc_poolAmountOut);

  //   uint256 calc_tokenAmountIn = bmath.calcSingleInGivenPoolOut(
  //     tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, calc_poolAmountOut, swapFee
  //   );
  //   emit Log('calc_tokenAmountIn', calc_tokenAmountIn);

  //   assert(tokenAmountIn <= calc_tokenAmountIn);
  // }

  uint256 FEE_DISCOUNT = 0; // compare against no fee

  // calcPoolOutGivenSingleIn * calcSingleOutGivenPoolIn should be equal to calcOutGivenIn
  function fuzz_testIndirectSwaps_CalcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 swapFee
  ) public {
    tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT - MIN_WEIGHT);
    tokenWeightOut = clamp(tokenWeightOut, MIN_WEIGHT, MAX_TOTAL_WEIGHT - tokenWeightIn);
    totalWeight = clamp(totalWeight, tokenWeightIn + tokenWeightOut, MAX_TOTAL_WEIGHT);
    totalWeight = tokenWeightIn + tokenWeightOut;
    tokenBalanceIn = clamp(tokenBalanceIn, BONE, type(uint256).max);
    tokenBalanceOut = clamp(tokenBalanceOut, BONE, type(uint256).max);
    tokenAmountIn = clamp(tokenAmountIn, BONE, type(uint256).max);
    poolSupply = clamp(poolSupply, 100 * BONE, type(uint256).max);
    swapFee = clamp(swapFee, MIN_FEE, MAX_FEE);

    emit Log('tokenWeightIn', tokenWeightIn);
    emit Log('tokenWeightOut', tokenWeightOut);
    emit Log('totalWeight', totalWeight);
    emit Log('tokenBalanceIn', tokenBalanceIn);
    emit Log('tokenBalanceOut', tokenBalanceOut);
    emit Log('tokenAmountIn', tokenAmountIn);
    emit Log('poolSupply', poolSupply);
    emit Log('swapFee', swapFee);

    uint256 calc_tokenAmountOut = bmath.calcOutGivenIn(
      tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee * FEE_DISCOUNT / BONE
    );
    emit Log('calc_tokenAmountOut', calc_tokenAmountOut);

    uint256 calc_inv_poolAmountOut =
      bmath.calcPoolOutGivenSingleIn(tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, tokenAmountIn, swapFee);
    emit Log('calc_inv_poolAmountOut', calc_inv_poolAmountOut);

    uint256 calc_inv_tokenAmountOut = bmath.calcSingleOutGivenPoolIn(
      tokenBalanceOut, tokenWeightOut, poolSupply + calc_inv_poolAmountOut, totalWeight, calc_inv_poolAmountOut, swapFee
    );
    emit Log('calc_inv_tokenAmountOut', calc_inv_tokenAmountOut);

    assert(
      calc_tokenAmountOut >= calc_inv_tokenAmountOut // direct path should be greater or equal to indirect path
        || tokenAmountIn > tokenBalanceIn / 2 // max in ratio
        || calc_inv_tokenAmountOut > tokenBalanceOut / 3 + 1 // max out ratio
    );
  }

  // calcPoolInGivenSingleOut * calcSingleInGivenPoolOut should be equal to calcInGivenOut
  function fuzz_testIndirectSwaps_CalcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 swapFee
  ) public {
    tokenWeightIn = clamp(tokenWeightIn, MIN_WEIGHT, MAX_WEIGHT - MIN_WEIGHT);
    tokenWeightOut = clamp(tokenWeightOut, MIN_WEIGHT, MAX_TOTAL_WEIGHT - tokenWeightIn);
    totalWeight = clamp(totalWeight, tokenWeightIn + tokenWeightOut, MAX_TOTAL_WEIGHT);
    totalWeight = tokenWeightIn + tokenWeightOut;
    tokenBalanceIn = clamp(tokenBalanceIn, BONE, type(uint256).max);
    tokenBalanceOut = clamp(tokenBalanceOut, BONE, type(uint256).max);
    poolSupply = clamp(poolSupply, 100 * BONE, type(uint256).max);
    tokenAmountOut = clamp(tokenAmountOut, BONE, type(uint256).max);
    swapFee = clamp(swapFee, MIN_FEE, MAX_FEE);

    emit Log('tokenWeightIn', tokenWeightIn);
    emit Log('tokenWeightOut', tokenWeightOut);
    emit Log('totalWeight', totalWeight);
    emit Log('tokenBalanceIn', tokenBalanceIn);
    emit Log('tokenBalanceOut', tokenBalanceOut);
    emit Log('poolSupply', poolSupply);
    emit Log('tokenAmountOut', tokenAmountOut);
    emit Log('swapFee', swapFee);

    uint256 calc_tokenAmountIn = bmath.calcInGivenOut(
      tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut, swapFee * FEE_DISCOUNT / BONE
    );
    emit Log('calc_tokenAmountIn', calc_tokenAmountIn);

    uint256 calc_inv_poolAmountOut = bmath.calcPoolOutGivenSingleIn(
      tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, calc_tokenAmountIn, swapFee
    );
    emit Log('calc_inv_poolAmountOut', calc_inv_poolAmountOut);

    uint256 calc_inv_tokenAmountOut = bmath.calcSingleOutGivenPoolIn(
      tokenBalanceOut, tokenWeightOut, poolSupply + calc_inv_poolAmountOut, totalWeight, calc_inv_poolAmountOut, swapFee
    );
    emit Log('calc_inv_tokenAmountOut', calc_inv_tokenAmountOut);

    assert(
      tokenAmountOut >= calc_inv_tokenAmountOut // direct path should be greater or equal to indirect path
        || calc_tokenAmountIn > tokenBalanceIn / 2 // max in ratio
        || calc_inv_tokenAmountOut > tokenBalanceOut / 3 + 1 // max out ratio
    );
  }
}
