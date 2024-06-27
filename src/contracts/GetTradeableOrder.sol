// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.24;

import {IERC20} from '@cowprotocol/interfaces/IERC20.sol';
import {GPv2Order} from '@cowprotocol/libraries/GPv2Order.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

library GetTradeableOrder {
  /// @dev Avoid stack too deep errors with `getTradeableOrder`.
  struct GetTradeableOrderParams {
    address pool;
    IERC20 token0;
    IERC20 token1;
    uint256 token0Weight;
    uint256 token1Weight;
    uint256 priceNumerator;
    uint256 priceDenominator;
    bytes32 appData;
  }

  /// @notice The largest possible duration of any AMM order, starting from the current block timestamp.
  uint32 public constant MAX_ORDER_DURATION = 5 * 60;

  function getTradeableOrder(GetTradeableOrderParams memory params)
    internal
    view
    returns (GPv2Order.Data memory order_)
  {
    (uint256 selfReserve0, uint256 selfReserve1) =
      (params.token0.balanceOf(params.pool), params.token1.balanceOf(params.pool));

    selfReserve0 = Math.mulDiv(selfReserve0, 1e18, params.token0Weight);
    selfReserve1 = Math.mulDiv(selfReserve1, 1e18, params.token1Weight);

    IERC20 sellToken;
    IERC20 buyToken;
    uint256 sellAmount;
    uint256 buyAmount;
    
    uint256 selfReserve0TimesPriceDenominator = selfReserve0 * params.priceDenominator;
    uint256 selfReserve1TimesPriceNumerator = selfReserve1 * params.priceNumerator;
    uint256 tradedAmountToken0;
    if (selfReserve1TimesPriceNumerator < selfReserve0TimesPriceDenominator) {
      sellToken = params.token0;
      buyToken = params.token1;
      sellAmount = selfReserve0 / 2 - Math.ceilDiv(selfReserve1TimesPriceNumerator, 2 * params.priceDenominator);
      buyAmount = Math.mulDiv(
        sellAmount,
        selfReserve1TimesPriceNumerator + (params.priceDenominator * sellAmount),
        params.priceNumerator * selfReserve0,
        Math.Rounding.Ceil
      );
      tradedAmountToken0 = sellAmount;

      sellAmount = Math.mulDiv(sellAmount, params.token0Weight, 1e18);
      buyAmount = Math.mulDiv(buyAmount, params.token1Weight, 1e18);
    } else {
      revert('avoiding this branch in PoC');
      sellToken = params.token1;
      buyToken = params.token0;
      sellAmount = selfReserve1 / 2 - Math.ceilDiv(selfReserve0TimesPriceDenominator, 2 * params.priceNumerator);
      buyAmount = Math.mulDiv(
        sellAmount,
        selfReserve0TimesPriceDenominator + (params.priceNumerator * sellAmount),
        params.priceDenominator * selfReserve1,
        Math.Rounding.Ceil
      );
      tradedAmountToken0 = buyAmount;
    }

    order_ = GPv2Order.Data(
      sellToken,
      buyToken,
      GPv2Order.RECEIVER_SAME_AS_OWNER,
      sellAmount,
      buyAmount,
      uint32(block.timestamp) + MAX_ORDER_DURATION,
      params.appData,
      0,
      GPv2Order.KIND_SELL,
      true,
      GPv2Order.BALANCE_ERC20,
      GPv2Order.BALANCE_ERC20
    );
  }
}
