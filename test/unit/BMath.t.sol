// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {BMath, BNum} from 'contracts/BMath.sol';
import {Test} from 'forge-std/Test.sol';

// Main test contract
contract BMathTest is Test {
  BMath bMath;

  uint256 constant BONE = 1e18; // The fixed-point unit for BMath and BNum

  // valid scenario
  uint256 constant weightIn = BONE;
  uint256 constant weightOut = 2 * BONE;
  uint256 constant balanceIn = 20 * BONE;
  uint256 constant balanceOut = 30 * BONE;
  uint256 constant swapFee = BONE / 10;
  uint256 constant amountIn = 5 * BONE;
  uint256 constant amountOut = 7 * BONE;

  function setUp() external {
    bMath = new BMath();
  }

  function test_CalcSpotPriceWhenSwapFeeEqualsBONE() external {
    uint256 _swapFee = BONE;

    // it should revert
    //     division by zero
    vm.expectRevert(BNum.BNum_DivZero.selector);

    // Action
    bMath.calcSpotPrice(balanceIn, weightIn, balanceOut, weightOut, _swapFee);
  }

  function test_CalcSpotPriceWhenTokenBalanceInTooBig(uint256 _balanceIn) external {
    _balanceIn = bound(_balanceIn, type(uint256).max / BONE + 1, type(uint256).max);

    // it should revert
    //     bo * BONE > uint256 max
    vm.expectRevert(BNum.BNum_DivInternal.selector);

    bMath.calcSpotPrice(_balanceIn, weightIn, balanceOut, weightOut, swapFee);
  }

  function test_CalcSpotPriceWhenTokenBalanceOutTooBig(uint256 _balanceOut) external {
    _balanceOut = bound(_balanceOut, type(uint256).max / BONE + 1, type(uint256).max);

    // it should revert
    //     bo * BONE > uint256 max
    vm.expectRevert(BNum.BNum_DivInternal.selector);

    bMath.calcSpotPrice(balanceIn, weightIn, _balanceOut, weightOut, swapFee);
  }

  function test_CalcSpotPriceWhenWeightedTokenBalanceInOverflows(uint256 _balanceIn, uint256 _weightIn) external {
    _weightIn = bound(_weightIn, BONE, type(uint256).max);
    _balanceIn = bound(_balanceIn, (type(uint256).max - weightIn / 2), type(uint256).max);

    // it should revert
    //     bi * BONE + (wi / 2) > uint256 max
    vm.expectRevert(BNum.BNum_DivInternal.selector);

    bMath.calcSpotPrice(_balanceIn, _weightIn, balanceOut, weightOut, swapFee);
  }

  function test_CalcSpotPriceWhenWeightedTokenBalanceOutOverflows(uint256 _balanceOut, uint256 _weightOut) external {
    _weightOut = bound(_weightOut, BONE, type(uint256).max);
    _balanceOut = bound(_balanceOut, (type(uint256).max - weightOut / 2), type(uint256).max);

    // it should revert
    //     bo * BONE + (wo / 2) > uint256 max
    vm.expectRevert(BNum.BNum_DivInternal.selector);

    bMath.calcSpotPrice(balanceIn, weightIn, _balanceOut, _weightOut, swapFee);
  }

  function test_CalcSpotPriceWhenUsingASwapFeeOfZero() external {
    // it should return correct value
    //     bi/wi * wo/bo
    //     20/1 * 2/30 = 1.333333...
    uint256 _swapFee = 0;

    uint256 _spotPrice = bMath.calcSpotPrice(balanceIn, weightIn, balanceOut, weightOut, _swapFee);

    assertEq(_spotPrice, 1.333333333333333333e18);
  }

  function test_CalcSpotPriceWhenUsingKnownValues() external {
    // it should return correct value
    //     (bi/wi * wo/bo) * (1 / (1 - sf))
    //     (20/1 * 2/30) * (1 / (1 - 0.1)) = 1.481481481...

    uint256 _spotPrice = bMath.calcSpotPrice(balanceIn, weightIn, balanceOut, weightOut, swapFee);

    assertEq(_spotPrice, 1.481481481481481481e18);
  }

  function test_CalcOutGivenInWhenTokenWeightOutIsZero() external {
    uint256 _weightOut = 0;

    // it should revert
    //     division by zero
    vm.expectRevert(BNum.BNum_DivZero.selector);

    bMath.calcOutGivenIn(balanceIn, weightIn, balanceOut, _weightOut, amountIn, swapFee);
  }

  function test_CalcOutGivenInWhenTokenAmountInIsZero() external {
    // it should revert
    //     TODO: why?
  }

  function test_CalcOutGivenInWhenTokenBalanceInTooSmall() external {
    vm.skip(true);
    // TODO: how?

    uint256 _balanceIn = 1;

    // it should revert
    //     bi + (BONE - swapFee) = 0
    vm.expectRevert(BNum.BNum_DivInternal.selector);

    bMath.calcOutGivenIn(_balanceIn, weightIn, balanceOut, weightOut, amountIn, swapFee);
  }

  function test_CalcOutGivenInWhenTokenWeightInIsZero() external {
    uint256 _weightIn = 0;

    // it should return zero
    uint256 _amountOut = bMath.calcOutGivenIn(balanceIn, _weightIn, balanceOut, weightOut, amountIn, swapFee);

    assertEq(_amountOut, 0);
  }

  function test_CalcOutGivenInWhenTokenWeightInEqualsTokenWeightOut(uint256 _weight) external {
    _weight = bound(_weight, BONE, 50 * BONE);

    // it should return correct value
    //     bo * (1 - (bi / (bi + (ai * (1-sf)))))
    //     30 * (1 - (20 / (20 + (5 * (1 - 0.1)))) = 5.5102040816...
    uint256 _amountOut = bMath.calcOutGivenIn(balanceIn, _weight, balanceOut, _weight, amountIn, swapFee);

    assertEq(_amountOut, 5.51020408163265306e18);
  }

  function test_CalcOutGivenInWhenUsingKnownValues() external {
    // it should return correct value
    //     b0 * (1 - (bi / ((bi + (ai * (1 - sf)))))^(wi/wo))
    //     30 * (1 - (20 / ((20 + (5 * (1 - 0.1)))))^(1/2)) = 2.8947629128...

    uint256 _amountOut = bMath.calcOutGivenIn(balanceIn, weightIn, balanceOut, weightOut, amountIn, swapFee);

    assertEq(_amountOut, 2.89476291247227984e18);
  }

  function test_CalcInGivenOutWhenTokenWeightInIsZero() external {
    uint256 _weightIn = 0;

    // it should revert
    //     division by zero
    vm.expectRevert(BNum.BNum_DivZero.selector);

    bMath.calcInGivenOut(balanceIn, _weightIn, balanceOut, weightOut, amountIn, swapFee);
  }

  function test_CalcInGivenOutWhenTokenAmountOutEqualsTokenBalanceOut(uint256 _amount) external {
    _amount = bound(_amount, 1, type(uint256).max / BONE);

    // it should revert
    //     division by zero
    vm.expectRevert(BNum.BNum_DivZero.selector);

    bMath.calcInGivenOut(balanceIn, weightIn, _amount, weightOut, _amount, swapFee);
  }

  function test_CalcInGivenOutWhenTokenWeightOutIsZero() external {
    uint256 _weightOut = 0;

    uint256 _amountIn = bMath.calcInGivenOut(balanceIn, weightIn, balanceOut, _weightOut, amountOut, swapFee);

    // it should return zero
    assertEq(_amountIn, 0);
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
