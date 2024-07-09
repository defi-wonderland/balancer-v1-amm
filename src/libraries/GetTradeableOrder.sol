// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.24;

import {IERC20} from '@cowprotocol/interfaces/IERC20.sol';
import {GPv2Order} from '@cowprotocol/libraries/GPv2Order.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

// TODO: vendor library from cowprotocol/cow-amm repo when available
library GetTradeableOrder {
  /**
   * @notice Parameters for the `getTradeableOrder` function.
   * @param pool The address of the pool to query.
   * @param token0 The first token of the pool.
   * @param token1 The second token of the pool.
   * @param priceNumerator The numerator of the pricing vector.
   * @param priceDenominator The denominator of the pricing vector.
   * @param appData The app data identifier to include in the order.
   * @dev Avoid stack too deep errors with `getTradeableOrder`.
   */
  struct GetTradeableOrderParams {
    address pool;
    IERC20 token0;
    IERC20 token1;
    /// @dev The numerator of the price, expressed in amount of token1 per
    /// amount of token0. For example, if token0 is DAI and the price is
    /// 1 WETH (token1) for 3000 DAI, then this could be 1 (and the
    /// denominator would be 3000).
    uint256 priceNumerator;
    /// @dev The denominator of the price, expressed in amount of token1 per
    /// amount of token0. For example, if token0 is DAI and the price is
    /// 1 WETH (token1) for 3000 DAI, then this could be 3000 (and the
    /// denominator would be 1).
    uint256 priceDenominator;
    bytes32 appData;
  }

  /// @notice The largest possible duration of any AMM order, starting from the current block timestamp.
  uint32 public constant MAX_ORDER_DURATION = 5 * 60;

  /**
   * @notice Method to calculate the canonical order of a pool given a pricing vector.
   * @param params Encoded parameters for the order.
   * @return order_ The canonical order of the pool.
   */
  function getTradeableOrder(GetTradeableOrderParams memory params)
    internal
    view
    returns (GPv2Order.Data memory order_)
  {
    (uint256 selfReserve0, uint256 selfReserve1) =
      (params.token0.balanceOf(params.pool), params.token1.balanceOf(params.pool));

    IERC20 sellToken;
    IERC20 buyToken;
    uint256 sellAmount;
    uint256 buyAmount;
    // Note on rounding: we want to round down the sell amount and up the
    // buy amount. This is because the math for the order makes it lie
    // precisely on the AMM curve, and a rounding error to the other way
    // could cause a valid order to become invalid.
    // Note on the if condition: it guarantees that sellAmount is positive
    // in the corresponding branch (it would be negative in the other). This
    // excludes rounding errors: in this case, the function could revert but
    // the amounts involved would be just a few atoms, so we accept that no
    // order will be available.
    // Note on the order price: The buy amount is not optimal for the AMM
    // given the sell amount. This is intended because we want to force
    // solvers to maximize the surplus for this order with the price that
    // isn't the AMM best price.
    uint256 selfReserve0TimesPriceDenominator = selfReserve0 * params.priceDenominator;
    uint256 selfReserve1TimesPriceNumerator = selfReserve1 * params.priceNumerator;
    if (selfReserve1TimesPriceNumerator < selfReserve0TimesPriceDenominator) {
      sellToken = params.token0;
      buyToken = params.token1;
      sellAmount = selfReserve0 / 2 - Math.ceilDiv(selfReserve1TimesPriceNumerator, 2 * params.priceDenominator);
      buyAmount = Math.mulDiv(sellAmount, selfReserve1, selfReserve0 - sellAmount, Math.Rounding.Ceil);
    } else {
      sellToken = params.token1;
      buyToken = params.token0;
      sellAmount = selfReserve1 / 2 - Math.ceilDiv(selfReserve0TimesPriceDenominator, 2 * params.priceNumerator);
      buyAmount = Math.mulDiv(sellAmount, selfReserve0, selfReserve1 - sellAmount, Math.Rounding.Ceil);
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
