pragma solidity 0.8.25;

import './BMath.sol';
import './BToken.sol';

import {GPv2Order} from '../cow-swap/GPv2Order.sol';
import {IERC1271} from 'interfaces/IERC1271.sol';

import {BPool} from './BPool.sol';
import {BaseBCoWPool, ISettlement} from './BaseBCoWPool.sol';

contract BCoWPool is BaseBCoWPool, BPool {
  constructor(address cowSwap) BaseBCoWPool(ISettlement(cowSwap)) BPool() {}

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

    // NOTE: struct is just to temporarily display the information inside GPv2Order.Data
    GPv2Order.Data({
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

  function _afterFinalize() internal override {
    for (uint256 i; i < _tokens.length; i++) {
      address token = _tokens[i];
      approveUnlimited(IERC20(token), vaultRelayer);
    }

    // sets BPool controller as BaseBCoWPool manager
    manager = _controller;
  }
}
