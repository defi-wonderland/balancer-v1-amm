// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BPool, IBPool} from 'contracts/BPool.sol';
import {StdStorage, Test, stdStorage} from 'forge-std/Test.sol';

// For test contract: execute a reentering call to an arbitrary function
contract BPoolReentering is BPool {
  event HAS_REENTERED();

  function TestTryToReenter(bytes calldata _calldata) external _lock_ {
    (bool success, bytes memory ret) = address(this).call(_calldata);

    if (!success) {
      assembly {
        revert(add(ret, 0x20), mload(ret))
      }
    }
  }
}

// For test contract: expose and modify the internal state variables of BPool
contract BPoolExposed is BPool {
  function forTest_setFinalize(bool _isFinalized) external {
    _finalized = _isFinalized;
  }
}

// Main test contract
contract BPoolTest is Test {
  using stdStorage for StdStorage;

  BPool pool;

  address deployer = makeAddr('deployer');

  function setUp() external {
    vm.prank(deployer);
    pool = new BPool();
  }

  function test_SetSwapFeeRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.setSwapFee, 1));
  }

  function test_SetSwapFeeRevertWhen_PoolIsFinalized() external {
    // Pre condition
    BPoolExposed poolExposed = new BPoolExposed();
    poolExposed.forTest_setFinalize(true);

    // Post condition
    // it should revert
    vm.expectRevert('ERR_IS_FINALIZED');

    // Action
    vm.prank(deployer);
    poolExposed.setSwapFee(1);
  }

  function test_SetSwapFeeRevertWhen_CalledByANon_controller(address _caller) external {
    // Pre condition
    vm.assume(_caller != deployer);

    // Post condition
    // it should revert
    vm.expectRevert('ERR_NOT_CONTROLLER');

    // Action
    vm.prank(_caller);
    pool.setSwapFee(1);
  }

  modifier whenCalledByTheController() {
    vm.startPrank(deployer);
    _;
  }

  function test_SetSwapFeeRevertWhen_TheFeeIsSetLteMIN_FEE(uint256 _fee) external whenCalledByTheController {
    // Pre condition
    _fee = bound(_fee, 0, pool.MIN_FEE() - 1);

    // Post condition
    // it should revert
    vm.expectRevert('ERR_MIN_FEE');

    // Action
    pool.setSwapFee(_fee);
  }

  function test_SetSwapFeeRevertWhen_TheFeeIsSetGteMAX_FEE(uint256 _fee) external whenCalledByTheController {
    // Pre condition
    _fee = bound(_fee, pool.MAX_FEE() + 1, type(uint256).max);

    // Post condition
    // it should revert
    vm.expectRevert('ERR_MAX_FEE');

    // Action
    pool.setSwapFee(_fee);
  }

  function test_SetSwapFeeWhenTheFeeIsSetBetweenMIN_FEEAndMAX_FEE(uint256 _fee) external whenCalledByTheController {
    // Pre condition
    _fee = bound(_fee, pool.MIN_FEE(), pool.MAX_FEE());

    // Post condition
    // it should emit LOG_CALL
    vm.expectEmit(address(pool));
    emit IBPool.LOG_CALL(pool.setSwapFee.selector, deployer, abi.encodeCall(pool.setSwapFee, _fee));

    // Action
    pool.setSwapFee(_fee);

    // Post condition
    // it should set the fee
    assertEq(pool.getSwapFee(), _fee);
  }

  function test_SetControllerRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.setController, makeAddr('manager')));
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
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.finalize, ()));
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
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.bind, (makeAddr('token'), 1, 1)));
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
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.unbind, makeAddr('token')));
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
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();
    uint256[] memory _arr = new uint256[](1);
    _arr[0] = 1;

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.joinPool, (1, _arr)));
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

  function test_JoinPoolRevertWhen_TheTokenAmountInOfOneOfThePoolTokenExceedsTheCorrespondingMaxAmountsIn() external {
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

  function test_JoinPoolRevertWhen_OneOfTheUnderlyingTokenTransfersFails() external whenTheFunctionRequirementsAreMet {
    // it should revert
    vm.skip(true);
  }

  function test_ExitPoolRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();
    uint256[] memory _arr = new uint256[](1);
    _arr[0] = 1;

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.exitPool, (1, _arr)));
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

  function test_ExitPoolRevertWhen_OneOfTheUnderlyingTokenTransferFails() external whenTheFunctionRequirementsAreMet {
    // it should revert
    vm.skip(true);
  }

  function test_SwapExactAmountInRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(
      abi.encodeCall(poolReentering.swapExactAmountIn, (makeAddr('tokenIn'), 1, makeAddr('tokenOut'), 1, 1))
    );
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
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(
      abi.encodeCall(poolReentering.swapExactAmountOut, (makeAddr('tokenIn'), 1, makeAddr('tokenOut'), 1, 1))
    );
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

  function test_SwapExactAmountOutRevertWhen_TheSpotPriceAfterTheSwapIsGtTokenAmountInDivByTokenAmountOut() external {
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
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.joinswapExternAmountIn, (makeAddr('tokenIn'), 1, 1)));
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
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.joinswapPoolAmountOut, (makeAddr('tokenIn'), 1, 1)));
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
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.exitswapPoolAmountIn, (makeAddr('tokenIn'), 1, 1)));
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
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.exitswapExternAmountOut, (makeAddr('tokenIn'), 1, 1)));
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
