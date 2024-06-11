// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";

contract BPool is Test {
    function test_SetSwapFeeRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_SetSwapFeeRevertWhen_PoolIsntFinalized() external {
        // it should revert
        vm.skip(true);
    }

    function test_SetSwapFeeRevertWhen_CalledByANon_controller() external {
        // it should revert
        vm.skip(true);
    }

    modifier whenCalledByTheController() {
        _;
    }

    function test_SetSwapFeeRevertWhen_TheFeeIsSetLteMIN_FEE() external whenCalledByTheController {
        // it should revert
        vm.skip(true);
    }

    function test_SetSwapFeeRevertWhen_TheFeeIsSetGteMAX_FEE() external whenCalledByTheController {
        // it should revert
        vm.skip(true);
    }

    function test_SetSwapFeeWhenTheFeeIsSetBetweenMIN_FEEAndMAX_FEE() external whenCalledByTheController {
        // it should set the fee
        // it should emit LOG_CALL
        vm.skip(true);
    }

    function test_SetControllerRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_SetControllerRevertWhen_CalledByANon_controller() external {
        // it should revert
        vm.skip(true);
    }

    function test_SetControllerWhenCalledByTheController() external {
        // it should set the controller
        // it should emit LOG_CALL
        vm.skip(true);
    }

    function test_FinalizeRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_FinalizeRevertWhen_CalledByANon_controller() external {
        // it should revert
        vm.skip(true);
    }

    function test_FinalizeRevertWhen_PoolIsFinalized() external {
        // it should revert
        vm.skip(true);
    }

    function test_FinalizeRevertWhen_ThereAreLessTokensThanMIN_BOUND_TOKENS() external {
        // it should revert
        vm.skip(true);
    }

    function test_FinalizeWhenCalledByTheController() external {
        // it should mint the initial BToken supply
        // it should send the initial BToken supply to the caller
        // it should set the pool as finalized
        // it should emit LOG_CALL
        vm.skip(true);
    }

    function test_BindRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_BindRevertWhen_CalledByANon_controller() external {
        // it should revert
        vm.skip(true);
    }

    function test_BindRevertWhen_TheTokenToBindIsAlreadyBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_BindRevertWhen_ThePoolIsFinalized() external {
        // it should revert
        vm.skip(true);
    }

    function test_BindRevertWhen_ThereAreAlreadyMAX_BOUNDTokens() external {
        // it should revert
        vm.skip(true);
    }

    function test_BindRevertWhen_TheDenormIsLteMIN_WEIGHT() external {
        // it should revert
        vm.skip(true);
    }

    function test_BindRevertWhen_TheDenormIsGteMAX_WEIGHT() external {
        // it should revert
        vm.skip(true);
    }

    function test_BindRevertWhen_TheBalanceToSendIsLessThanMIN_BALANCE() external {
        // it should revert
        vm.skip(true);
    }

    function test_BindRevertWhen_TheNewTotalWeightIsGtMAX_TOTAL_WEIGHT() external {
        // it should revert
        vm.skip(true);
    }

    modifier whenTheFunctionRequirementsAreMet() {
        _;
    }

    function test_BindWhenTheFunctionRequirementsAreMet() external whenTheFunctionRequirementsAreMet {
        // it should set the token as bound,
        // it should set the token's index
        // it should set the token's denorm,
        // it should add the token to the tokens array
        // it should transfer the amount from the caller to the pool
        // it should emit LOG_CALL
        vm.skip(true);
    }

    function test_BindRevertWhen_TheTokenTransferFails() external whenTheFunctionRequirementsAreMet {
        // it should revert
        vm.skip(true);
    }

    function test_UnbindRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_UnbindRevertWhen_CalledByANon_controller() external {
        // it should revert
        vm.skip(true);
    }

    function test_UnbindRevertWhen_TheTokenToUnbindIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_UnbindRevertWhen_ThePoolIsFinalized() external {
        // it should revert
        vm.skip(true);
    }

    function test_UnbindWhenTheFunctionRequirementsAreMet() external whenTheFunctionRequirementsAreMet {
        // it should update the total weight
        // it should remove the token from the token array
        // it should update the token record to unbound
        // it should transfer the token balance to the caller
        // it should emit LOG_CALL
        vm.skip(true);
    }

    function test_UnbindRevertWhen_TheTokenTransferFails() external whenTheFunctionRequirementsAreMet {
        // it should revert
        vm.skip(true);
    }

    function test_JoinPoolRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinPoolRevertWhen_ThePoolIsNotFinalized() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinPoolRevertWhen_TheRatioPoolAmountOutToPoolTotalIsZero() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinPoolRevertWhen_OneOfTheTokenAmountInIsZero() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinPoolRevertWhen_TheTokenAmountInOfOneOfThePoolTokenExceedsTheCorrespondingMaxAmountsIn()
        external
    {
        // it should revert
        vm.skip(true);
    }

    function test_JoinPoolWhenTheFunctionRequirementsAreMet() external whenTheFunctionRequirementsAreMet {
        // it should emit LOG_JOIN for each token
        // it should transfer the token amount in from the caller to the pool, for each token
        // it should mint pool shares for the caller
        // it should emit LOG_CALL
        vm.skip(true);
    }

    function test_JoinPoolRevertWhen_OneOfTheUnderlyingTokenTransfersFails()
        external
        whenTheFunctionRequirementsAreMet
    {
        // it should revert
        vm.skip(true);
    }

    function test_ExitPoolRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_ExitPoolRevertWhen_ThePoolIsNotFinalized() external {
        // it should revert
        vm.skip(true);
    }

    function test_ExitPoolWhenNetPoolShareIsZero() external {
        // it should revert
        //     poolAmountIn - poolAmountIn * exit fee / pooltotal is zero
        vm.skip(true);
    }

    function test_ExitPoolWhenTheFunctionRequirementsAreMet() external whenTheFunctionRequirementsAreMet {
        // it should transfer the btoken from the caller to the pool
        // it should transfer the exit fee (poolAmountIn*exit fee) to the factory
        // it should burn the rest of the btoken
        // it should transfer the pool tokens to the caller
        // it should emit LOG_CALL
        // it should emit LOG_EXIT for each token
        vm.skip(true);
    }

    function test_ExitPoolRevertWhen_OneOfTheUnderlyingTokenTransferIsAZeroAmount()
        external
        whenTheFunctionRequirementsAreMet
    {
        // it should revert
        vm.skip(true);
    }

    function test_ExitPoolRevertWhen_OneOfTheUnderlyingTokenTransferAmountIsLessThanTheMinAmountsOut()
        external
        whenTheFunctionRequirementsAreMet
    {
        // it should revert
        vm.skip(true);
    }

    function test_ExitPoolRevertWhen_OneOfTheUnderlyingTokenTransferFails()
        external
        whenTheFunctionRequirementsAreMet
    {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountInRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountInRevertWhen_TheTokenInIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountInRevertWhen_TheTokenOutIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountInRevertWhen_ThePoolIsNotFinalized() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountInWhenTheTokenAmountInIsTooSmall() external {
        // it should revert
        //     tokenAmountIn is lte tokenInBalance * MAX_IN_RATIO
        vm.skip(true);
    }

    function test_SwapExactAmountInRevertWhen_TheSpotPriceBeforeTheSwapIsGtMaxPrice() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountInRevertWhen_TheTokenAmountOutIsLessThanMinAmountOut() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountInRevertWhen_TheSpotPriceDecreasesAfterTheSwap() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountInRevertWhen_TheSpotPriceAfterTheSwapIsGtMaxPrice() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountInRevertWhen_TheSpotPriceAfterTheSwapIsGtTokenAmountInDivByTokenAmountOut() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountInWhenTheFunctionRequirementsAreMet() external whenTheFunctionRequirementsAreMet {
        // it should transfer tokenAmountIn tokenIn from the caller to the pool
        // it should transfer tokenAmountOut tokenOut from the pool to the caller
        // it should emit LOG_CALL
        vm.skip(true);
    }

    function test_SwapExactAmountInRevertWhen_OneOfTheUnderlyingTokenTransferFails()
        external
        whenTheFunctionRequirementsAreMet
    {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountOutRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountOutRevertWhen_TheTokenInIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountOutRevertWhen_TheTokenOutIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountOutRevertWhen_ThePoolIsNotFinalized() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountOutRevertWhen_TheTokenAmountOutIsLteTokenInBalanceMulByMAX_OUT_RATIO() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountOutRevertWhen_TheSpotPriceBeforeTheSwapIsGtMaxPrice() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountOutRevertWhen_TheTokenAmountInIsGtMaxAmountIn() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountOutRevertWhen_TheSpotPriceDecreasesAfterTheSwap() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountOutRevertWhen_TheSpotPriceAfterTheSwapIsGtMaxPrice() external {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountOutRevertWhen_TheSpotPriceAfterTheSwapIsGtTokenAmountInDivByTokenAmountOut()
        external
    {
        // it should revert
        vm.skip(true);
    }

    function test_SwapExactAmountOutWhenTheFunctionRequirementsAreMet() external whenTheFunctionRequirementsAreMet {
        // it should transfer the tokenIn from the caller to the pool
        // it should transfer the tokenOut from the pool to the caller
        // it should emit LOG_CALL
        vm.skip(true);
    }

    function test_SwapExactAmountOutRevertWhen_OneOfTheUnderlyingTokenTransferFails()
        external
        whenTheFunctionRequirementsAreMet
    {
        // it should revert
        vm.skip(true);
    }

    function test_JoinswapExternAmountInRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinswapExternAmountInRevertWhen_TheTokenIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinswapExternAmountInRevertWhen_ThePoolIsNotFinalized() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinswapExternAmountInRevertWhen_TheTokenAmountInIsLteTokenInBalanceMulByMAX_IN_RATIO() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinswapExternAmountInRevertWhen_ThePoolAmountOutIsLtMinPoolAmountOut() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinswapExternAmountInWhenTheFunctionRequirementsAreMet() external {
        // it should mint pool amount out
        // it should transfer the pool amount out to the caller
        // it should transfer the token amount in from the caller to the pool
        // it should emit LOG_CALL
        vm.skip(true);
    }

    function test_JoinswapPoolAmountOutRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinswapPoolAmountOutRevertWhen_TheTokenIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinswapPoolAmountOutRevertWhen_ThePoolIsNotFinalized() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinswapPoolAmountOutRevertWhen_TheCalculatedTokenAmountInEquals0() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinswapPoolAmountOutRevertWhen_TheCalculatedTokenAmountInIsGtMaxAmountIn() external {
        // it should revert
        vm.skip(true);
    }

    function test_JoinswapPoolAmountOutRevertWhen_TheCalculatedTokenAmountInIsGtTokenInBalanceMulByMAX_IN_RATIO()
        external
    {
        // it should revert
        vm.skip(true);
    }

    function test_JoinswapPoolAmountOutWhenTheFunctionRequirementsAreMet() external {
        // it should mint pool amount out
        // it should transfer the pool amount out to the caller
        // it should transfer the token amount in from the caller to the pool
        // it should emit LOG_JOIN
        // it should emit LOG_CALL
        vm.skip(true);
    }

    function test_ExitswapPoolAmountInRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_ExitswapPoolAmountInRevertWhen_TheTokenIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_ExitswapPoolAmountInRevertWhen_ThePoolIsNotFinalized() external {
        // it should revert
        vm.skip(true);
    }

    function test_ExitswapPoolAmountInRevertWhen_TheCalculatedTokenAmountOutIsLtMinAmountOut() external {
        // it should revert
        vm.skip(true);
    }

    function test_ExitswapPoolAmountInRevertWhen_TheCalculatedTokenAmountOutIsGtTokenOutBalanceMulByMAX_OUT_RATIO()
        external
    {
        // it should revert
        vm.skip(true);
    }

    function test_ExitswapPoolAmountInWhenTheFunctionRequirementsAreMet() external {
        // it should pull the pool amount in
        // it should burn the pool amount in minus fee
        // it should transfer the fee to the factory
        // it should transfer the token amount out to the caller
        // it should emit LOG_EXIT
        // it should emit LOG_CALL
        vm.skip(true);
    }

    function test_ExitswapExternAmountOutRevertWhen_PoolIsTheReenteringCaller() external {
        // it should revert
        vm.skip(true);
    }

    function test_ExitswapExternAmountOutRevertWhen_TheTokenIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_ExitswapExternAmountOutRevertWhen_ThePoolIsNotFinalized() external {
        // it should revert
        vm.skip(true);
    }

    function test_ExitswapExternAmountOutRevertWhen_ThePoolAmountOutIsGtTokenOutBalanceMulByMAX_OUT_RATIO() external {
        // it should revert
        vm.skip(true);
    }

    function test_ExitswapExternAmountOutRevertWhen_TheCalculatedPoolAmountInIsZero() external {
        // it should revert
        vm.skip(true);
    }

    function test_ExitswapExternAmountOutRevertWhen_TheCalculatedPoolAmountInIsGtMaxPoolAmountIn() external {
        // it should revert
        vm.skip(true);
    }

    function test_ExitswapExternAmountOutWhenTheFunctionRequirementsAreMet() external {
        // it should pull the pool amount in
        // it should burn the pool amount in minus fee
        // it should transfer the fee to the factory
        // it should transfer the token amount out to the caller
        // it should emit LOG_EXIT
        // it should emit LOG_CALL
        vm.skip(true);
    }

    function test_GetSpotPriceRevertWhen_TheTokenInIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_GetSpotPriceRevertWhen_TheTokenOutIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_GetSpotPriceWhenBothTokenAreNotBound() external {
        // it should return the spot price
        vm.skip(true);
    }

    function test_GetSpotPriceSansFeeRevertWhen_TheTokenInIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_GetSpotPriceSansFeeRevertWhen_TheTokenOutIsNotBound() external {
        // it should revert
        vm.skip(true);
    }

    function test_GetSpotPriceSansFeeWhenBothTokenAreNotBound() external {
        // it should return the spot price without fees
        vm.skip(true);
    }
}
