// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {BConst} from 'contracts/BConst.sol';
import {BPool, IBPool, IERC20} from 'contracts/BPool.sol';
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
  function forTest_getRecord(address token) external view returns (IBPool.Record memory) {
    return _records[token];
  }

  function forTest_setFinalize(bool _isFinalized) external {
    _finalized = _isFinalized;
  }

  function forTest_setTokens(address[] memory __tokens) external {
    _tokens = __tokens;
  }

  function forTest_setRecords(address _token, bool _bound, uint256 _index, uint256 _denorm) external {
    _records[_token].bound = _bound;
    _records[_token].index = _index;
    _records[_token].denorm = _denorm;
  }

  function forTest_setTotalWeight(uint256 __totalWeight) external {
    _totalWeight = __totalWeight;
  }
}

// Main test contract
contract BPoolTest is Test, BConst {
  using stdStorage for StdStorage;

  BPool pool;

  address deployer = makeAddr('deployer');

  function setUp() external {
    vm.prank(deployer);
    pool = new BPool();
  }

  modifier whenTheFunctionRequirementsAreMet() {
    _;
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
}
