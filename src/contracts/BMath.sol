// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import {BConst} from './BConst.sol';
import {BNum} from './BNum.sol';

/**
 * @title BMath
 * @notice Includes functions for calculating the BPool related math.
 */
contract BMath is BConst, BNum {
  /**
   * @notice Calculate the spot price of a token in terms of another one
   * @dev The price denomination depends on the decimals of the tokens.
   * @dev To obtain the price with 18 decimals the next formula should be applied to the result
   * @dev spotPrice = spotPrice ÷ (10^tokenInDecimals) × (10^tokenOutDecimals)
   * @param tokenBalanceIn The balance of the input token in the pool
   * @param tokenWeightIn The weight of the input token in the pool
   * @param tokenBalanceOut The balance of the output token in the pool
   * @param tokenWeightOut The weight of the output token in the pool
   * @param swapFee The swap fee of the pool
   * @return spotPrice The spot price of a token in terms of another one
   * @dev Formula:
   * sP = spotPrice
   * bI = tokenBalanceIn                ( bI / wI )         1
   * bO = tokenBalanceOut         sP =  -----------  *  ----------
   * wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )
   * wO = tokenWeightOut
   * sF = swapFee
   */
  function calcSpotPrice(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 swapFee
  ) public pure returns (uint256 spotPrice) {
    uint256 numer = bdiv(tokenBalanceIn, tokenWeightIn);
    uint256 denom = bdiv(tokenBalanceOut, tokenWeightOut);
    uint256 ratio = bdiv(numer, denom);
    uint256 scale = bdiv(BONE, bsub(BONE, swapFee));
    return (spotPrice = bmul(ratio, scale));
  }

  /**
   * @notice Calculate the amount of token out given the amount of token in for a swap
   * @param tokenBalanceIn The balance of the input token in the pool
   * @param tokenWeightIn The weight of the input token in the pool
   * @param tokenBalanceOut The balance of the output token in the pool
   * @param tokenWeightOut The weight of the output token in the pool
   * @param tokenAmountIn The amount of the input token
   * @param swapFee The swap fee of the pool
   * @return tokenAmountOut The amount of token out given the amount of token in for a swap
   * @dev Formula:
   * aO = tokenAmountOut
   * bO = tokenBalanceOut
   * bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \
   * aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |
   * wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /
   * wO = tokenWeightOut
   * sF = swapFee
   */
  function calcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) public pure returns (uint256 tokenAmountOut) {
    uint256 weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
    uint256 adjustedIn = bsub(BONE, swapFee);
    adjustedIn = bmul(tokenAmountIn, adjustedIn);
    uint256 y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
    uint256 foo = bpow(y, weightRatio);
    uint256 bar = bsub(BONE, foo);
    tokenAmountOut = bmul(tokenBalanceOut, bar);
    return tokenAmountOut;
  }

  /**
   * @notice Calculate the amount of token in given the amount of token out for a swap
   * @param tokenBalanceIn The balance of the input token in the pool
   * @param tokenWeightIn The weight of the input token in the pool
   * @param tokenBalanceOut The balance of the output token in the pool
   * @param tokenWeightOut The weight of the output token in the pool
   * @param tokenAmountOut The amount of the output token
   * @param swapFee The swap fee of the pool
   * @return tokenAmountIn The amount of token in given the amount of token out for a swap
   * @dev Formula:
   * aI = tokenAmountIn
   * bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \
   * bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |
   * aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /
   * wI = tokenWeightIn           --------------------------------------------
   * wO = tokenWeightOut                          ( 1 - sF )
   * sF = swapFee
   */
  function calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) public pure returns (uint256 tokenAmountIn) {
    uint256 weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
    uint256 diff = bsub(tokenBalanceOut, tokenAmountOut);
    uint256 y = bdiv(tokenBalanceOut, diff);
    uint256 foo = bpow(y, weightRatio);
    foo = bsub(foo, BONE);
    tokenAmountIn = bsub(BONE, swapFee);
    tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
    return tokenAmountIn;
  }

  /**
   * @notice Calculate the amount of pool tokens that should be minted,
   * given a single token in when joining a pool
   * @param tokenBalanceIn The balance of the input token in the pool
   * @param tokenWeightIn The weight of the input token in the pool
   * @param poolSupply The total supply of the pool tokens
   * @param totalWeight The total weight of the pool
   * @param tokenAmountIn The amount of the input token
   * @param swapFee The swap fee of the pool
   * @return poolAmountOut The amount of balancer pool tokens that will be minted
   * @dev Formula:
   * pAo = poolAmountOut         /                                              \
   * tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \
   * wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \
   * tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS
   * tBi = tokenBalanceIn      \\  ------------------------------------- /        /
   * pS = poolSupply            \\                    tBi               /        /
   * sF = swapFee                \                                              /
   */
  function calcPoolOutGivenSingleIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) public pure returns (uint256 poolAmountOut) {
    // Charge the trading fee for the proportion of tokenAi
    ///  which is implicitly traded to the other pool tokens.
    // That proportion is (1- weightTokenIn)
    // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
    uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
    uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
    uint256 tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));

    uint256 newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
    uint256 tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

    // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
    uint256 poolRatio = bpow(tokenInRatio, normalizedWeight);
    uint256 newPoolSupply = bmul(poolRatio, poolSupply);
    poolAmountOut = bsub(newPoolSupply, poolSupply);
    return poolAmountOut;
  }

  /**
   * @notice Given amount of pool tokens out, calculate the amount of tokens in that should be sent
   * @param tokenBalanceIn The balance of the input token in the pool
   * @param tokenWeightIn The weight of the input token in the pool
   * @param poolSupply The current total supply
   * @param totalWeight The sum of the weight of all tokens in the pool
   * @param poolAmountOut The expected amount of pool tokens
   * @param swapFee The swap fee of the pool
   * @return tokenAmountIn The amount of token in requred to mint poolAmountIn token pools
   * @dev Formula:
   * tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\
   * pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI
   * pAo = poolAmountOut              \\    pS    /     \(wI / tW)//
   * bI = balanceIn          tAi =  --------------------------------------------
   * wI = weightIn                              /      wI       \
   * tW = totalWeight                          |  1 - ---- * sF  |
   * sF = swapFee                               \      tW       /
   */
  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) public pure returns (uint256 tokenAmountIn) {
    uint256 normalizedWeight = bdiv(tokenWeightIn, totalWeight);
    uint256 newPoolSupply = badd(poolSupply, poolAmountOut);
    uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

    //uint newBalTi = poolRatio^(1/weightTi) * balTi;
    uint256 boo = bdiv(BONE, normalizedWeight);
    uint256 tokenInRatio = bpow(poolRatio, boo);
    uint256 newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
    uint256 tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
    // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
    //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
    //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
    uint256 zar = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
    return tokenAmountIn;
  }

  /**
   * @notice Calculate the amount of token out given the amount of pool tokens in
   * @param tokenBalanceOut The balance of the output token in the pool
   * @param tokenWeightOut The weight of the output token in the pool
   * @param poolSupply The total supply of the pool tokens
   * @param totalWeight The total weight of the pool
   * @param poolAmountIn The amount of pool tokens
   * @param swapFee The swap fee of the pool
   * @return tokenAmountOut The amount of underlying token out from burning
   * poolAmountIn pool tokens
   * @dev Formula:
   * tAo = tokenAmountOut            /      /                                             \\
   * bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\
   * pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 ||
   * ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //
   * wI = tokenWeightIn      tAo =   \      \                                             //
   * tW = totalWeight                    /     /      wO \       \
   * sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |
   * eF = exitFee                        \     \      tW /       /
   */
  function calcSingleOutGivenPoolIn(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountIn,
    uint256 swapFee
  ) public pure returns (uint256 tokenAmountOut) {
    uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
    // charge exit fee on the pool token side
    // pAiAfterExitFee = pAi*(1-exitFee)
    uint256 poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
    uint256 newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
    uint256 poolRatio = bdiv(newPoolSupply, poolSupply);

    // newBalTo = poolRatio^(1/weightTo) * balTo;
    uint256 tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
    uint256 newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

    uint256 tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);

    // charge swap fee on the output token side
    //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
    uint256 zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
    tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
    return tokenAmountOut;
  }

  /**
   * @notice Calculate the amount of pool tokens in given an amount of single token out
   * @param tokenBalanceOut The balance of the output token in the pool
   * @param tokenWeightOut The weight of the output token in the pool
   * @param poolSupply The total supply of the pool tokens
   * @param totalWeight The total weight of the pool
   * @param tokenAmountOut The amount of the output token
   * @param swapFee The swap fee of the pool
   * @return poolAmountIn The amount of pool tokens to burn in order to receive
   * `tokeAmountOut` underlying tokens
   * @dev Formula:
   * pAi = poolAmountIn               // /               tAo             \\     / wO \     \
   * bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \
   * tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (w0 / tW)) * sF)/  | ^ \ tW /  * pS |
   * ps = poolSupply                 \\ -----------------------------------/                /
   * wO = tokenWeightOut  pAi =       \\               bO                 /                /
   * tW = totalWeight           -------------------------------------------------------------
   * sF = swapFee                                        ( 1 - eF )
   * eF = exitFee
   */
  function calcPoolInGivenSingleOut(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) public pure returns (uint256 poolAmountIn) {
    // charge swap fee on the output token side
    uint256 normalizedWeight = bdiv(tokenWeightOut, totalWeight);
    //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
    uint256 zoo = bsub(BONE, normalizedWeight);
    uint256 zar = bmul(zoo, swapFee);
    uint256 tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));

    uint256 newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
    uint256 tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

    //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
    uint256 poolRatio = bpow(tokenOutRatio, normalizedWeight);
    uint256 newPoolSupply = bmul(poolRatio, poolSupply);
    uint256 poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

    // charge exit fee on the pool token side
    // pAi = pAiAfterExitFee/(1-exitFee)
    poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, EXIT_FEE));
    return poolAmountIn;
  }
}
