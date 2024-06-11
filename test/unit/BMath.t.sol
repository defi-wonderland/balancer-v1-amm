// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BMath, BNum} from 'contracts/BMath.sol';
import {Test} from 'forge-std/Test.sol';

contract BNumExposed is BNum {
  function bdivExposed(uint256 a, uint256 b) external pure returns (uint256) {
    return super.bdiv(a, b);
  }

  function bmulExposed(uint256 a, uint256 b) external pure returns (uint256) {
    return super.bmul(a, b);
  }

  function bsubExposed(uint256 a, uint256 b) external pure returns (uint256) {
    return super.bsub(a, b);
  }
}

contract BMathTest is Test {
  BMath bMath;
  BNumExposed bNum;

  uint256 BONE; // The fixed-point unit for BMath and BNum

  function setUp() external {
    bMath = new BMath();
    bNum = new BNumExposed();

    BONE = bMath.BONE();
  }

  function test_CalcSpotPriceWhenSwapFeeEqualsBONE() external {
    // Precondition
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceIn = BONE;
    uint256 _tokenBalanceOut = BONE;

    uint256 _swapFee = BONE;

    // Post condition
    // it will revert (div by zero)
    vm.expectRevert('ERR_DIV_ZERO');

    // Action
    bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);
  }

  function test_CalcSpotPriceWhenTokenBalanceInTooBig(uint256 _tokenBalanceIn) external {
    // Precondition
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceOut = BONE;
    uint256 _swapFee = BONE / 2;

    _tokenBalanceIn = bound(_tokenBalanceIn, type(uint256).max / BONE + 1, type(uint256).max);

    // Post condition
    // it will revert (overflow)
    //     token balance in > uint max/BONE
    vm.expectRevert('ERR_DIV_INTERNAL');

    // Action
    bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);
  }

  function test_CalcSpotPriceWhenTokenBalanceOutTooBig(uint256 _tokenBalanceOut) external {
    // Precondition
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceIn = BONE;
    uint256 _swapFee = BONE / 2;

    _tokenBalanceOut = bound(_tokenBalanceOut, type(uint256).max / BONE + 1, type(uint256).max);

    // Post condition
    // it will revert (overflow)
    //     token balance out > uint max/BONE
    vm.expectRevert('ERR_DIV_INTERNAL');

    // Action
    bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);
  }

  function test_CalcSpotPriceWhenWeightedTokenBalanceInOverflows(
    uint256 _tokenBalanceIn,
    uint256 _tokenWeightIn
  ) external {
    // Precondition
    uint256 _tokenWeightOut = BONE;
    uint256 _tokenBalanceOut = BONE;
    uint256 _swapFee = BONE / 2;

    _tokenWeightIn = bound(_tokenWeightIn, BONE, type(uint256).max);
    _tokenBalanceIn = bound(_tokenBalanceIn, (type(uint256).max - _tokenWeightIn / 2), type(uint256).max);

    // Post condition
    // it will revert (overflow)
    //     token balance in * BONE + (token weight in/2) > uint max
    vm.expectRevert('ERR_DIV_INTERNAL');

    // Action
    bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);
  }

  function test_CalcSpotPriceWhenWeightedTokenBalanceOutOverflows(
    uint256 _tokenBalanceOut,
    uint256 _tokenWeightOut
  ) external {
    // Precondition
    uint256 _tokenWeightIn = BONE;
    uint256 _tokenBalanceIn = BONE;
    uint256 _swapFee = BONE / 2;

    _tokenWeightOut = bound(_tokenWeightOut, BONE, type(uint256).max);
    _tokenBalanceOut = bound(_tokenBalanceOut, (type(uint256).max - _tokenWeightOut / 2), type(uint256).max);

    // Post condition
    // it will revert (overflow)
    //     token balance out * BONE + (token weight out/2) > uint max
    vm.expectRevert('ERR_DIV_INTERNAL');

    // Action
    bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);
  }

  function test_CalcSpotPriceWhenUsingASwapFeeOfZero() external {
    // Precondition
    uint256 _swapFee = 0;

    uint256 _tokenWeightIn = 10 * BONE;
    uint256 _tokenWeightOut = 20 * BONE;
    uint256 _tokenBalanceIn = 100 * BONE;
    uint256 _tokenBalanceOut = 30 * BONE;

    // expected is bi/wi / bo/wo
    uint256 _expected = bNum.bdivExposed(
      bNum.bdivExposed(_tokenBalanceIn, _tokenWeightIn), bNum.bdivExposed(_tokenBalanceOut, _tokenWeightOut)
    );

    // Action
    uint256 _spotPrice =
      bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);

    // Post condition
    // it should return bi/wi / bo/wo
    assertEq(_spotPrice, _expected, 'wrong spot price when fee is 0');
  }

  function test_CalcSpotPriceWhenUsingKnownValues() external {
    // Precondition
    uint256 _swapFee = BONE / 2;

    uint256 _tokenWeightIn = 10 * BONE;
    uint256 _tokenWeightOut = 20 * BONE;
    uint256 _tokenBalanceIn = 100 * BONE;
    uint256 _tokenBalanceOut = 30 * BONE;

    // expected is bi/wi / bo/wo * 1/(1 - sf)
    uint256 _expected = bNum.bmulExposed(
      bNum.bdivExposed(
        bNum.bdivExposed(_tokenBalanceIn, _tokenWeightIn), bNum.bdivExposed(_tokenBalanceOut, _tokenWeightOut)
      ),
      bNum.bdivExposed(BONE, bNum.bsubExposed(BONE, _swapFee))
    );

    // Action
    uint256 _spotPrice =
      bMath.calcSpotPrice(_tokenBalanceIn, _tokenWeightIn, _tokenBalanceOut, _tokenWeightOut, _swapFee);

    // Post condition
    // it should return correct value
    assertEq(_spotPrice, _expected, 'wrong spot price when fee is not 0');
  }

  function test_CalcOutGivenInWhenTokenWeightOutIsZero() external {
    // Precondition
    uint256 tokenBalanceIn = 100 * BONE;
    uint256 tokenWeightIn = 10 * BONE;
    uint256 tokenBalanceOut = 30 * BONE;
    uint256 tokenAmountIn = 10 * BONE;
    uint256 swapFee = BONE / 2;

    uint256 tokenWeightOut = 0;

    // Post condition
    // it revert (div by zero)
    vm.expectRevert('ERR_DIV_ZERO');

    // Action
    bMath.calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee);
  }

  function test_CalcOutGivenInWhenTokenAmountInIsZero() external {
    // Precondition
    uint256 tokenWeightIn = 10 * BONE;
    uint256 tokenBalanceOut = 30 * BONE;
    uint256 tokenWeightOut = 10 * BONE;
    uint256 swapFee = BONE / 2;

    uint256 tokenBalanceIn = 0;
    uint256 tokenAmountIn = 0;

    // Post condition
    // it revert (div by zero)
    vm.expectRevert('ERR_DIV_ZERO');

    // Action
    bMath.calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee);
  }

  function test_CalcOutGivenInWhenTokenBalanceInTooSmall(uint256 swapFee, uint256 tokenBalanceIn) external {
    // Precondition
    uint256 tokenWeightIn = 10 * BONE;
    uint256 tokenBalanceOut = 30 * BONE;
    uint256 tokenWeightOut = 10 * BONE;
    uint256 tokenAmountIn = 10 * BONE;

    swapFee = BONE;
    tokenBalanceIn = 0;

    // Post condition
    // it revert (div by zero)
    //     token balance In + (BONE - swapFee) is zero
    vm.expectRevert('ERR_DIV_ZERO');

    // Action
    bMath.calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee);
  }

  function test_CalcOutGivenInWhenTokenWeightInIsZero() external {
    // it should return zero
    vm.skip(true);
  }

  function test_CalcOutGivenInWhenTokenWeightInEqualsTokenWeightOut() external {
    // it should return bo * 1 - (bi/ bi+(ai*(1-sf))))
    vm.skip(true);
  }

  function test_CalcOutGivenInWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_CalcInGivenOutWhenTokenWeightInIsZero() external {
    // it revert (div by zero)
    vm.skip(true);
  }

  function test_CalcInGivenOutWhenTokenAmountOutEqualsTokenBalanceOut() external {
    // it revert (div by zero)
    vm.skip(true);
  }

  function test_CalcInGivenOutWhenTokenWeightOutIsZero() external {
    // it should return zero
    vm.skip(true);
  }

  function test_CalcInGivenOutWhenTokenWeightInEqualsTokenWeightOut() external {
    // it should return bi * (1 - (bo/(bo-ao) - 1)))
    vm.skip(true);
  }

  function test_CalcInGivenOutWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_CalcPoolOutGivenSingleInWhenTokenBalanceInIsZero() external {
    // it revert (div by zero)
    vm.skip(true);
  }

  function test_CalcPoolOutGivenSingleInWhenTokenWeightInIsZero() external {
    // it should return zero
    vm.skip(true);
  }

  function test_CalcPoolOutGivenSingleInWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_CalcSingleInGivenPoolOutWhenTotalWeightIsZero() external {
    // it revert (div by zero)
    vm.skip(true);
  }

  function test_CalcSingleInGivenPoolOutWhenSwapFeeIsZero() external {
    // it revert (div by zero)
    vm.skip(true);
  }

  function test_CalcSingleInGivenPoolOutWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_CalcPoolSingleOutGivenPoolInWhenPoolSupplyIsZero() external {
    // it revert (div by zero)
    vm.skip(true);
  }

  function test_CalcPoolSingleOutGivenPoolInWhenTotalWeightIsZero() external {
    // it revert (div by zero)
    vm.skip(true);
  }

  function test_CalcPoolSingleOutGivenPoolInWhenTokenBalanceOutIsZero() external {
    // it should return zero
    vm.skip(true);
  }

  function test_CalcPoolSingleOutGivenPoolInWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_CalcPoolInGivenSingleOutRevertWhen_ExitFeeIs1() external {
    // it should revert
    vm.skip(true);
  }

  function test_CalcPoolInGivenSingleOutRevertWhen_TokenBalanceOutIsZero() external {
    // it should revert
    vm.skip(true);
  }

  function test_CalcPoolInGivenSingleOutRevertWhen_SwapFeeIs1AndTokenWeightOutIsZero() external {
    // it should revert
    vm.skip(true);
  }

  function test_CalcPoolInGivenSingleOutWhenPoolSupplyIsZero() external {
    // it should return zero
    vm.skip(true);
  }

  function test_CalcPoolInGivenSingleOutWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }
}
