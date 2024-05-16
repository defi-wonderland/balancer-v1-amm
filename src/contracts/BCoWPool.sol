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

  function verify(TradingParams memory tradingParams, GPv2Order.Data memory order) public view override {}

  function matchFreeOrderParams(
    GPv2Order.Data memory lhs,
    GPv2Order.Data memory rhs
  ) internal pure override returns (bool) {
    bool sameSellToken = lhs.sellToken == rhs.sellToken;
    bool sameBuyToken = lhs.buyToken == rhs.buyToken;
    bool sameSellAmount = lhs.sellAmount == rhs.sellAmount;
    bool sameBuyAmount = lhs.buyAmount == rhs.buyAmount;
    bool sameValidTo = lhs.validTo == rhs.validTo;
    bool sameKind = lhs.kind == rhs.kind;
    bool samePartiallyFillable = lhs.partiallyFillable == rhs.partiallyFillable;

    // The following parameters are untested:
    // - receiver
    // - appData
    // - feeAmount
    // - sellTokenBalance
    // - buyTokenBalance

    return sameSellToken && sameBuyToken && sameSellAmount && sameBuyAmount && sameValidTo && sameKind
      && samePartiallyFillable;
  }
}
