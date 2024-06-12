// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BMath, BNum} from 'contracts/BMath.sol';
import {Test} from 'forge-std/Test.sol';

// For test contract: expose the internal functions of BNum
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

  function baddExposed(uint256 a, uint256 b) external pure returns (uint256) {
    return super.badd(a, b);
  }
}

// Main test contract
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
    vm.skip(true); // use a set of known in/result
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
    // Precondition
    uint256 tokenBalanceIn = 100 * BONE;
    uint256 tokenWeightIn = 0;
    uint256 tokenBalanceOut = 30 * BONE;
    uint256 tokenAmountIn = 10 * BONE;
    uint256 swapFee = BONE / 2;
    uint256 tokenWeightOut = 10 * BONE;

    // Action
    uint256 _tokenAmountOut =
      bMath.calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee);

    // Post condition
    // it should return zero
    assertEq(_tokenAmountOut, 0);
  }

  function test_CalcOutGivenInWhenTokenWeightInEqualsTokenWeightOut() external {
    // Precondition
    uint256 tokenBalanceIn = 100 * BONE;
    uint256 tokenWeightIn = 10 * BONE;
    uint256 tokenBalanceOut = 30 * BONE;
    uint256 tokenAmountIn = 10 * BONE;
    uint256 swapFee = BONE / 2;
    uint256 tokenWeightOut = tokenWeightIn;

    // expected is bo * (1 - (bi/ bi+(ai*(1-sf))))
    // computation split for the stack depth...
    // bi+(ai*(1-sf))))
    uint256 _expected =
      bNum.baddExposed(tokenBalanceIn, bNum.bmulExposed(tokenAmountIn, bNum.bsubExposed(BONE, swapFee)));

    // (1 - (bi/ bi+(ai*(1-sf))))
    _expected = bNum.bsubExposed(BONE, bNum.bdivExposed(tokenBalanceIn, _expected));

    // bo * (1 - (bi/ bi+(ai*(1-sf))))
    _expected = bNum.bmulExposed(tokenBalanceOut, _expected);

    // Action
    uint256 _tokenAmountOut =
      bMath.calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee);

    // it should return bo * (1 - (bi/ bi+(ai*(1-sf)))))
    assertEq(_tokenAmountOut, _expected, 'wrong token amount out in calcOutGivenIn');
  }

  function test_CalcOutGivenInWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_CalcInGivenOutWhenTokenWeightInIsZero() external {
    // Preconditions
    uint256 tokenBalanceIn = 100 * BONE;
    uint256 tokenWeightIn = 0;
    uint256 tokenBalanceOut = 30 * BONE;
    uint256 tokenAmountOut = 10 * BONE;
    uint256 swapFee = BONE / 2;
    uint256 tokenWeightOut = 10 * BONE;

    // Post condition
    // it revert (div by zero)
    vm.expectRevert('ERR_DIV_ZERO');

    // Action
    uint256 _tokenAmountIn =
      bMath.calcInGivenOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut, swapFee);
  }

  function test_CalcInGivenOutWhenTokenAmountOutEqualsTokenBalanceOut() external {
    // Preconditions
    uint256 tokenBalanceIn = 100 * BONE;
    uint256 tokenWeightIn = 10 * BONE;
    uint256 tokenBalanceOut = 30 * BONE;
    uint256 tokenAmountOut = tokenBalanceOut;
    uint256 swapFee = BONE / 2;
    uint256 tokenWeightOut = 10 * BONE;

    // Post condition
    // it revert (div by zero)
    vm.expectRevert('ERR_DIV_ZERO');

    // Action
    uint256 _tokenAmountIn =
      bMath.calcInGivenOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut, swapFee);
  }

  function test_CalcInGivenOutWhenTokenWeightOutIsZero() external {
    // Preconditions
    uint256 tokenBalanceIn = 100 * BONE;
    uint256 tokenWeightIn = 10 * BONE;
    uint256 tokenBalanceOut = 30 * BONE;
    uint256 tokenAmountOut = 10 * BONE;
    uint256 swapFee = BONE / 2;
    uint256 tokenWeightOut = 0;

    // Action
    uint256 _tokenAmountIn =
      bMath.calcInGivenOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut, swapFee);

    // Post condition
    // it should return zero
    assertEq(_tokenAmountIn, 0, 'wrong token amount in in calcInGivenOut');
  }

  function test_CalcInGivenOutWhenTokenWeightInEqualsTokenWeightOut() external {
    // Preconditions
    uint256 tokenBalanceIn = 100 * BONE;
    uint256 tokenWeightIn = 10 * BONE;
    uint256 tokenBalanceOut = 30 * BONE;
    uint256 tokenAmountOut = 10 * BONE;
    uint256 swapFee = BONE / 2;
    uint256 tokenWeightOut = tokenWeightIn;

    // expected is bi * ((bo/(bo-ao) - 1))) / (1 - sf)
    uint256 _expected =
      bNum.bsubExposed(bNum.bdivExposed(tokenBalanceOut, bNum.bsubExposed(tokenBalanceOut, tokenAmountOut)), BONE);

    _expected = bNum.bdivExposed(bNum.bmulExposed(tokenBalanceIn, _expected), bNum.bsubExposed(BONE, swapFee));

    // Action
    uint256 _tokenAmountIn =
      bMath.calcInGivenOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut, swapFee);

    // Post condition
    // it should return bi * ((bo/(bo-ao) - 1))) / (1 - sf)
    assertEq(_tokenAmountIn, _expected, 'wrong token amount in in calcInGivenOut');
  }

  function test_CalcInGivenOutWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_CalcPoolOutGivenSingleInWhenTokenBalanceInIsZero() external {
    // Preconditions
    uint256 tokenBalanceIn = 0;
    uint256 tokenWeightIn = 10 * BONE;
    uint256 poolSupply = 100 * BONE;
    uint256 totalWeight = 50 * BONE;
    uint256 tokenAmountIn = 10 * BONE;
    uint256 swapFee = BONE / 2;

    // Post-condition
    // it revert (div by zero)
    vm.expectRevert('ERR_DIV_ZERO');

    // Action
    uint256 _poolAmountOut =
      bMath.calcPoolOutGivenSingleIn(tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, tokenAmountIn, swapFee);
  }

  function test_CalcPoolOutGivenSingleInWhenTokenWeightInIsZero() external {
    // Preconditions
    uint256 tokenBalanceIn = 10 * BONE;
    uint256 tokenWeightIn = 0;
    uint256 poolSupply = 100 * BONE;
    uint256 totalWeight = 50 * BONE;
    uint256 tokenAmountIn = 10 * BONE;
    uint256 swapFee = BONE / 2;

    // Action
    uint256 _poolAmountOut =
      bMath.calcPoolOutGivenSingleIn(tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, tokenAmountIn, swapFee);

    // Post-condition
    // it should return zero
    assertEq(_poolAmountOut, 0, 'wrong pool amount out in calcPoolOutGivenSingleIn');
  }

  function test_CalcPoolOutGivenSingleInWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_CalcSingleInGivenPoolOutWhenTotalWeightIsZero() external {
    // Preconditions
    uint256 tokenBalanceIn = 10 * BONE;
    uint256 tokenWeightIn = 5 * BONE;
    uint256 poolSupply = 100 * BONE;
    uint256 totalWeight = 0;
    uint256 poolAmountOut = 10 * BONE;
    uint256 swapFee = BONE / 2;

    // Post-condition
    // it revert (div by zero)
    vm.expectRevert('ERR_DIV_ZERO');

    // Action
    uint256 _tokenAmountIn =
      bMath.calcSingleInGivenPoolOut(tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, poolAmountOut, swapFee);
  }

  function test_CalcSingleInGivenPoolOutWhenSwapFeeIsZero() external {
    // This should be true based on the underlying formula, *but* implementation slightly deviates (to use the same fee as
    // in joinSwap::ExternAmountIn, without this div by zero)
    vm.skip(true);
  }

  function test_CalcSingleInGivenPoolOutWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_CalcSingleOutGivenPoolInWhenPoolSupplyIsZero() external {
    // Preconditions
    uint256 tokenBalanceOut = 10 * BONE;
    uint256 tokenWeightOut = 5 * BONE;
    uint256 poolSupply = 0;
    uint256 totalWeight = 10 * BONE;
    uint256 poolAmountIn = 10 * BONE;
    uint256 swapFee = BONE / 2;

    // Post-condition
    // it revert (div by zero)
    vm.expectRevert('ERR_SUB_UNDERFLOW'); // This should be a div by zero, but the implementation is slightly different (exit fee on pool side)

    // Action
    uint256 _tokenAmountOut =
      bMath.calcSingleOutGivenPoolIn(tokenBalanceOut, tokenWeightOut, poolSupply, totalWeight, poolAmountIn, swapFee);
  }

  function test_CalcSingleOutGivenPoolInWhenTotalWeightIsZero() external {
    // Preconditions
    uint256 tokenBalanceOut = 10 * BONE;
    uint256 tokenWeightOut = 5 * BONE;
    uint256 poolSupply = 100 * BONE;
    uint256 totalWeight = 0;
    uint256 poolAmountIn = 10 * BONE;
    uint256 swapFee = BONE / 2;

    // Post-condition
    // it revert (div by zero)
    vm.expectRevert('ERR_DIV_ZERO');

    // Action
    uint256 _tokenAmountOut =
      bMath.calcSingleOutGivenPoolIn(tokenBalanceOut, tokenWeightOut, poolSupply, totalWeight, poolAmountIn, swapFee);
  }

  function test_CalcSingleOutGivenPoolInWhenTokenBalanceOutIsZero() external {
    // Preconditions
    uint256 tokenBalanceOut = 0;
    uint256 tokenWeightOut = 5 * BONE;
    uint256 poolSupply = 100 * BONE;
    uint256 totalWeight = 10 * BONE;
    uint256 poolAmountIn = 10 * BONE;
    uint256 swapFee = BONE / 2;

    // Action
    uint256 _tokenAmountOut =
      bMath.calcSingleOutGivenPoolIn(tokenBalanceOut, tokenWeightOut, poolSupply, totalWeight, poolAmountIn, swapFee);

    // Post-condition
    // it should return zero
    assertEq(_tokenAmountOut, 0, 'wrong token amount out in calcSingleOutGivenPoolIn');
  }

  function test_CalcSingleOutGivenPoolInWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_CalcPoolInGivenSingleOutRevertWhen_ExitFeeIs1() external {
    vm.skip(true);
    // Implement if exit fee isn't a constant==0 anymore
  }

  function test_CalcPoolInGivenSingleOutRevertWhen_TokenBalanceOutIsZero() external {
    // Pre-condition
    uint256 tokenBalanceOut = 0;
    uint256 tokenWeightOut = 5 * BONE;
    uint256 poolSupply = 100 * BONE;
    uint256 totalWeight = 10 * BONE;
    uint256 tokenAmountOut = 10 * BONE;
    uint256 swapFee = BONE / 2;

    // Post-condition
    // it should revert
    vm.expectRevert('ERR_SUB_UNDERFLOW'); // underflow in the nominator, div by 0 in the denominator

    // Action
    uint256 _poolAmountIn =
      bMath.calcPoolInGivenSingleOut(tokenBalanceOut, tokenWeightOut, poolSupply, totalWeight, tokenAmountOut, swapFee);
  }

  function test_CalcPoolInGivenSingleOutRevertWhen_SwapFeeIs1AndTokenWeightOutIsZero() external {
    // Precondition
    uint256 tokenBalanceOut = 10 * BONE;
    uint256 tokenWeightOut = 0;
    uint256 poolSupply = 100 * BONE;
    uint256 totalWeight = 10 * BONE;
    uint256 tokenAmountOut = 10 * BONE;
    uint256 swapFee = BONE;

    // Post-condition
    // it should revert
    vm.expectRevert('ERR_DIV_ZERO');

    // Action
    uint256 _poolAmountIn =
      bMath.calcPoolInGivenSingleOut(tokenBalanceOut, tokenWeightOut, poolSupply, totalWeight, tokenAmountOut, swapFee);
  }

  function test_CalcPoolInGivenSingleOutWhenPoolSupplyIsZero() external {
    // Pre-condition
    uint256 tokenBalanceOut = 10 * BONE;
    uint256 tokenWeightOut = 5 * BONE;
    uint256 poolSupply = 0;
    uint256 totalWeight = 10 * BONE;
    uint256 tokenAmountOut = 10 * BONE;
    uint256 swapFee = BONE / 2;

    // Post-condition
    // it should revert
    vm.expectRevert('ERR_SUB_UNDERFLOW');

    // Action
    uint256 _poolAmountIn =
      bMath.calcPoolInGivenSingleOut(tokenBalanceOut, tokenWeightOut, poolSupply, totalWeight, tokenAmountOut, swapFee);
  }

  function test_CalcPoolInGivenSingleOutWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }
}
