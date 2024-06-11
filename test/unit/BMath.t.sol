// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";

contract BMath is Test {
    function test_CalcSpotPriceWhenSwapFeeEqualsBONE() external {
        // it will revert (div by zero)
        vm.skip(true);
    }

    function test_CalcSpotPriceWhenTokenBalanceInTooBig() external {
        // it will revert (overflow)
        //     token balance in > uint max/BONE
        vm.skip(true);
    }

    function test_CalcSpotPriceWhenTokenBalanceOutTooBig() external {
        // it will revert (overflow)
        //     token balance out > uint max/BONE
        vm.skip(true);
    }

    function test_CalcSpotPriceWhenWeightedTokenBalanceInOverflows() external {
        // it will revert (overflow)
        //     token balance in * BONE + (token weight in/2) > uint max
        vm.skip(true);
    }

    function test_CalcSpotPriceWhenWeightedTokenBalanceOutOverflows() external {
        // it will revert (overflow)
        //     token balance out * BONE + (token weight out/2) > uint max
        vm.skip(true);
    }

    function test_CalcSpotPriceWhenUsingASwapFeeOfZero() external {
        // it should return bi/wi * wo/bo
        vm.skip(true);
    }

    function test_CalcSpotPriceWhenUsingKnownValues() external {
        // it should return correct value
        vm.skip(true);
    }

    function test_CalcOutGivenInWhenTokenWeightOutIsZero() external {
        // it revert (div by zero)
        vm.skip(true);
    }

    function test_CalcOutGivenInWhenTokenAmountInIsZero() external {
        // it revert (div by zero)
        vm.skip(true);
    }

    function test_CalcOutGivenInWhenTokenBalanceInTooSmall() external {
        // it revert (div by zero)
        //     token balance In + (BONE - swapFee) is zero
        vm.skip(true);
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
