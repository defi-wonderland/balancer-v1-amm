// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {HalmosTest} from '../helpers/AdvancedTestsUtils.sol';
import {BMath} from 'contracts/BMath.sol';

contract SymbolicBMath is BMath, HalmosTest {
// todo crashes (pow -> loop...)
// calcOutGivenIn should be inv with calcInGivenOut
// function check_calcOutGivenInEquiv() public {
//     uint256 tokenBalanceIn = svm.createUint256('tokenBalanceIn');
//     uint256 tokenWeightIn = svm.createUint256('tokenWeightIn');
//     uint256 tokenBalanceOut = svm.createUint256('tokenBalanceOut');
//     uint256 tokenWeightOut = svm.createUint256('tokenWeightOut');
//     uint256 tokenAmountIn = svm.createUint256('tokenAmountIn');
//     uint256 swapFee = svm.createUint256('swapFee');

//     vm.assume(tokenWeightIn != 0);
//     vm.assume(tokenWeightOut != 0);
//     vm.assume(tokenAmountIn != 0);
//     vm.assume(tokenBalanceIn > BONE - swapFee);

//     uint256 tokenAmountOut = calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee);
//     vm.assume(tokenAmountOut != tokenBalanceOut);

//     uint256 tokenAmountIn2 = calcInGivenOut(tokenBalanceOut, tokenWeightOut, tokenBalanceIn, tokenWeightIn, tokenAmountOut, swapFee);

//     assert(tokenAmountIn == tokenAmountIn2);
// }
// calcPoolOutGivenSingleIn should be inv with calcSingleInGivenPoolOut
// calcSingleOutGivenPoolIn should be inv with calcPoolInGivenSingleOut
}
