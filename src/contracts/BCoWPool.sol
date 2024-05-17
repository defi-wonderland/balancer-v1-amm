pragma solidity 0.8.25;

import './BMath.sol';
import './BToken.sol';

import {ConditionalOrdersUtilsLib as Utils} from '../cow-swap/ConditionalOrdersUtilsLib.sol';
import {GPv2Order} from '../cow-swap/GPv2Order.sol';
import {IERC1271} from 'interfaces/IERC1271.sol';

import {BPool} from './BPool.sol';
import {BaseBCoWPool, ISettlement} from './BaseBCoWPool.sol';

contract BCoWPool is BaseBCoWPool, BPool {
  constructor() BaseBCoWPool(ISettlement(address(0))) BPool() {}

  function getTradeableOrder(TradingParams memory tradingParams)
    public
    view
    override
    returns (GPv2Order.Data memory order)
  {
    // TODO: Implement logic to create order data from trading params
    // NOTE: Trading params must be whitelisted for `enableTrading` and `disableTrading` to work
  }

  function verify(TradingParams memory tradingParams, GPv2Order.Data memory order) public view override {
    Record memory inRecord = _records[address(order.sellToken)];
    Record memory outRecord = _records[address(order.buyToken)];

    uint256 tokenAmountOut = calcOutGivenIn(
      order.sellToken.balanceOf(address(this)),
      inRecord.denorm,
      order.buyToken.balanceOf(address(this)),
      outRecord.denorm,
      order.sellAmount,
      0
    );

    // TODO: Add more checks depending on the order data
    require(tokenAmountOut >= order.buyAmount, 'BCoWPool: INSUFFICIENT_OUTPUT_AMOUNT');

    order = GPv2Order.Data({
      sellToken: tradingParams.sellToken,
      buyToken: tradingParams.buyToken,
      receiver: address(0),
      sellAmount: order.sellAmount,
      buyAmount: order.buyAmount,
      validTo: uint32(0),
      appData: order.appData,
      feeAmount: uint256(0),
      kind: bytes32(0),
      partiallyFillable: false,
      sellTokenBalance: bytes32(0),
      buyTokenBalance: bytes32(0)
    });
  }

  function matchFreeOrderParams(
    GPv2Order.Data memory lhs,
    GPv2Order.Data memory rhs
  ) internal pure override returns (bool) {
    // TODO: Cross-check (trading params > order data) ~= (order data)
    // bool sameSellToken = lhs.sellToken == rhs.sellToken;
    // bool sameBuyToken = lhs.buyToken == rhs.buyToken;

    // The following parameters are untested:
    // - buyAmount
    // - sellAmount
    // - validTo
    // - kind
    // - receiver
    // - partiallyFillable
    // - appData
    // - feeAmount
    // - sellTokenBalance
    // - buyTokenBalance

    return true; // sameSellToken && sameBuyToken;
  }

  function _afterFinalize() internal override {
    for (uint256 i; i < _tokens.length; i++) {
      address token = _tokens[i];
      approveUnlimited(IERC20(token), vaultRelayer);
    }
  }
}
