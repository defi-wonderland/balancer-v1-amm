// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {BMath, BNum} from 'contracts/BMath.sol';
import {Test} from 'forge-std/Test.sol';

// Main test contract
contract BMathTest is Test {
  BMath bMath;

  uint256 BONE; // The fixed-point unit for BMath and BNum

  function setUp() external {
    bMath = new BMath();

    BONE = bMath.BONE();
  }

  function test_CalcSpotPriceWhenSwapFeeEqualsBONE() external {
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceIn = BONE;
    uint256 _tokenBalanceOut = BONE;

    uint256 _swapFee = BONE;

    // it should revert
    //     division by zero
    vm.expectRevert(BNum.BNum_DivZero.selector);

    // Action
    bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);
  }

  function test_CalcSpotPriceWhenTokenBalanceInTooBig(uint256 _tokenBalanceIn) external {
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceOut = BONE;
    uint256 _swapFee = BONE / 2;

    _tokenBalanceIn = bound(_tokenBalanceIn, type(uint256).max / BONE + 1, type(uint256).max);

    // it should revert
    //     bo * BONE > uint256 max
    vm.expectRevert(BNum.BNum_DivInternal.selector);

    bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);
  }

  function test_CalcSpotPriceWhenTokenBalanceOutTooBig(uint256 _tokenBalanceOut) external {
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceIn = BONE;
    uint256 _swapFee = BONE / 2;

    _tokenBalanceOut = bound(_tokenBalanceOut, type(uint256).max / BONE + 1, type(uint256).max);

    // it should revert
    //     bo * BONE > uint256 max
    vm.expectRevert(BNum.BNum_DivInternal.selector);

    // Action
    bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);
  }

  function test_CalcSpotPriceWhenWeightedTokenBalanceInOverflows(
    uint256 _tokenBalanceIn,
    uint256 _tokenWeightIn
  ) external {
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceOut = BONE;
    uint256 _swapFee = BONE / 2;

    _tokenWeightIn = bound(_tokenWeightIn, BONE, type(uint256).max);
    _tokenBalanceIn = bound(_tokenBalanceIn, (type(uint256).max - _tokenWeightIn / 2), type(uint256).max);

    // it should revert
    //     bi * BONE + (wi / 2) > uint256 max
    vm.expectRevert(BNum.BNum_DivInternal.selector);

    bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);
  }

  function test_CalcSpotPriceWhenWeightedTokenBalanceOutOverflows(
    uint256 _tokenBalanceOut,
    uint256 _tokenWeightOut
  ) external {
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenBalanceIn = BONE;
    uint256 _swapFee = BONE / 2;

    _tokenWeightOut = bound(_tokenWeightOut, BONE, type(uint256).max);
    _tokenBalanceOut = bound(_tokenBalanceOut, (type(uint256).max - _tokenWeightOut / 2), type(uint256).max);

    // it should revert
    //     bo * BONE + (wo / 2) > uint256 max
    vm.expectRevert(BNum.BNum_DivInternal.selector);

    bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);
  }

  function test_CalcSpotPriceWhenUsingASwapFeeOfZero() external {
    // it should return correct value
    //     bi/wi * wo/bo
    //     100/10 * 20/30 = 20/3 + 1 = 6.666..667 (rounds up)
    uint256 _swapFee = 0;
    uint256 _tokenWeightIn = 10 * BONE; // 10
    uint256 _tokenWeightOut = 20 * BONE; // 20
    uint256 _tokenBalanceIn = 100 * BONE; // 100
    uint256 _tokenBalanceOut = 30 * BONE; // 30

    uint256 _spotPrice =
      bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);

    assertEq(_spotPrice, 20 * BONE / 3 + 1);
  }

  function test_CalcSpotPriceWhenUsingKnownValues() external {
    // it should return correct value
    //     (bi/wi * wo/bo) * (1 / (1 - sf))
    //     100/10 * 20/30 * 1/(1 - 0.5) = (20/3 + 1) / 0.5 = 13.333..334
    uint256 _swapFee = BONE / 2;
    uint256 _tokenWeightIn = 10 * BONE; // 10
    uint256 _tokenWeightOut = 20 * BONE; // 20
    uint256 _tokenBalanceIn = 100 * BONE; // 100
    uint256 _tokenBalanceOut = 30 * BONE; // 30

    uint256 _spotPrice =
      bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);

    assertEq(_spotPrice, (20 * BONE / 3 + 1) * 2);
  }

  function test_CalcOutGivenInWhenTokenWeightOutIsZero() external {
    uint256 _swapFee = 0;
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenWeightOut = 0;
    uint256 _tokenBalanceIn = BONE;
    uint256 _tokenBalanceOut = BONE;
    uint256 _tokenAmountIn = BONE;

    // it should revert
    //     division by zero
    vm.expectRevert(BNum.BNum_DivZero.selector);

    bMath.calcOutGivenIn(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _tokenAmountIn, _swapFee);
  }

  function test_CalcOutGivenInWhenTokenAmountInIsZero() external {
    // it should revert
    //     TODO: why?
  }

  function test_CalcOutGivenInWhenTokenBalanceInTooSmall() external {
    vm.skip(true);
    // TODO: why?

    uint256 _swapFee = 0;
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceIn = 1;
    uint256 _tokenBalanceOut = BONE;
    uint256 _tokenAmountIn = BONE;

    // it should revert
    //     bi + (BONE - swapFee) = 0
    vm.expectRevert(BNum.BNum_DivInternal.selector);

    bMath.calcOutGivenIn(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _tokenAmountIn, _swapFee);
  }

  function test_CalcOutGivenInWhenTokenWeightInIsZero() external {
    uint256 _swapFee = 0;
    uint256 _tokenWeightIn = 0;
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceIn = BONE;
    uint256 _tokenBalanceOut = BONE;
    uint256 _tokenAmountIn = BONE;

    // it should return zero
    uint256 _tokenAmountOut =
      bMath.calcOutGivenIn(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _tokenAmountIn, _swapFee);

    assertEq(_tokenAmountOut, 0);
  }

  function test_CalcOutGivenInWhenTokenWeightInEqualsTokenWeightOut() external {
    uint256 _swapFee = BONE / 2;
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceIn = 2 * BONE;
    uint256 _tokenBalanceOut = 3 * BONE;
    uint256 _tokenAmountIn = BONE;

    // it should return correct value
    //     bo * (1 - (bi / (bi + (ai * (1-sf)))))
    //     3 * (1 - (2 / (2 + (1 * (1 - 0.5))))) = 0.6
    uint256 _tokenAmountOut =
      bMath.calcOutGivenIn(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _tokenAmountIn, _swapFee);

    assertEq(_tokenAmountOut, 3 * BONE / 5);
  }

  function test_CalcOutGivenInWhenUsingKnownValues() external {
    uint256 _swapFee = BONE / 2;
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenWeightOut = 2 * BONE;
    uint256 _tokenBalanceIn = 2 * BONE;
    uint256 _tokenBalanceOut = 3 * BONE;
    uint256 _tokenAmountIn = BONE;

    // it should return correct value
    //     b0 * (1 - (bi / ((bi + (ai * (1 - sf))))^(wi/wo))
    //     3 * (1 - (2 / (2 + (1 * (1 - 0.5))))^(1/2)) = 0.316718...

    uint256 _tokenAmountOut =
      bMath.calcOutGivenIn(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _tokenAmountIn, _swapFee);

    assertEq(_tokenAmountOut, 0.316718426981698245e18);
  }

  function test_CalcInGivenOutWhenTokenWeightInIsZero() external {
    uint256 _swapFee = 0;
    uint256 _tokenWeightIn = 0;
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceIn = BONE;
    uint256 _tokenBalanceOut = BONE;
    uint256 _tokenAmountIn = BONE;

    // it should revert
    //     division by zero
    vm.expectRevert(BNum.BNum_DivZero.selector);

    bMath.calcInGivenOut(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _tokenAmountIn, _swapFee);
  }

  function test_CalcInGivenOutWhenTokenAmountOutEqualsTokenBalanceOut() external {
    uint256 _swapFee = 0;
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceIn = BONE;
    uint256 _tokenBalanceOut = 10 * BONE;
    uint256 _tokenAmountOut = 10 * BONE;

    // it should revert
    //     division by zero
    vm.expectRevert(BNum.BNum_DivZero.selector);

    bMath.calcInGivenOut(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _tokenAmountOut, _swapFee);
  }

  function test_CalcInGivenOutWhenTokenWeightOutIsZero() external {
    uint256 _swapFee = 0;
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenWeightOut = 0;
    uint256 _tokenBalanceIn = BONE;
    uint256 _tokenBalanceOut = 10 * BONE;
    uint256 _tokenAmountOut = BONE;

    uint256 _tokenAmountIn = bMath.calcInGivenOut(
      _tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _tokenAmountOut, _swapFee
    );

    // it should return zero
    assertEq(_tokenAmountIn, 0);
  }

  modifier whenTokenWeightInEqualsTokenWeightOut() {
    _;
  }

  function test_CalcInGivenOutWhenSwapFeeIsZero() external whenTokenWeightInEqualsTokenWeightOut {
    // it should return correct value
    //     bi((bo/(bo-ao) - 1)))
  }

  function test_CalcInGivenOutWhenSwapFeeIsNotZero() external whenTokenWeightInEqualsTokenWeightOut {
    // it should return correct value
    //     bi((bo/(bo-ao) - 1))) / (1 - sf)
  }

  function test_CalcInGivenOutWhenUsingKnownValues() external {
    // it should return correct value
    //     bi * ((bo/(bo-ao)^(wo/wi) - 1))) / (1 - sf)
  }

  function test_CalcPoolOutGivenSingleInWhenTokenBalanceInIsZero() external {
    // it should revert
    //     TODO: why?
  }

  function test_CalcPoolOutGivenSingleInWhenTokenWeightInIsZero() external {
    // it should return zero
  }

  function test_CalcPoolOutGivenSingleInWhenUsingKnownValues() external {
    // it should return correct value
  }

  function test_CalcSingleInGivenPoolOutWhenTotalWeightIsZero() external {
    // it should revert
    //     TODO: why
  }

  function test_CalcSingleInGivenPoolOutWhenSwapFeeIsZero() external {
    // it should revert
    //     TODO: why
  }

  function test_CalcSingleInGivenPoolOutWhenUsingKnownValues() external {
    // it should return correct value
  }

  function test_CalcSingleOutGivenPoolInWhenPoolSupplyIsZero() external {
    // it should revert
    //     TODO: why
  }

  function test_CalcSingleOutGivenPoolInWhenTotalWeightIsZero() external {
    // it should revert
    //     TODO: why
  }

  function test_CalcSingleOutGivenPoolInWhenTokenBalanceOutIsZero() external {
    // it should return zero
  }

  function test_CalcSingleOutGivenPoolInWhenUsingKnownValues() external {
    // it should return correct value
  }

  function test_CalcPoolInGivenSingleOutRevertWhen_TokenBalanceOutIsZero() external {
    // it should revert
  }

  function test_CalcPoolInGivenSingleOutRevertWhen_SwapFeeIs1AndTokenWeightOutIsZero() external {
    // it should revert
  }

  function test_CalcPoolInGivenSingleOutRevertWhen_PoolSupplyIsZero() external {
    // it should revert
  }

  function test_CalcPoolInGivenSingleOutWhenUsingKnownValues() external {
    // it should return correct value
  }
}
