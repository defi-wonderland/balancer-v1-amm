// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import {IERC20} from '@cowprotocol/interfaces/IERC20.sol';
import {GetTradeableOrder} from 'contracts/GetTradeableOrder.sol';
import {IBCoWFactory} from 'interfaces/IBCoWFactory.sol';
import {IBCoWPool} from 'interfaces/IBCoWPool.sol';
import {IBFactory} from 'interfaces/IBFactory.sol';
import {GPv2Interaction, GPv2Order, ICOWAMMPoolHelper} from 'interfaces/ICOWAMMPoolHelper.sol';

/**
 * @title BCoWHelper
 * @notice Helper contract that allows to trade on CoW Swap Protocol.
 * @dev This contract supports only 2-token pools.
 */
contract BCoWHelper is ICOWAMMPoolHelper {
  using GPv2Order for GPv2Order.Data;

  address public factory;
  bytes32 public immutable APP_DATA;

  constructor(address factory_) {
    factory = factory_;
    APP_DATA = IBCoWFactory(factory_).APP_DATA();
  }

  function tokens(address pool) public view returns (address[] memory tokens_) {
    if (!IBFactory(factory).isBPool(pool)) revert PoolDoesNotExist();
    // NOTE: reverts in case pool is not finalized
    tokens_ = IBCoWPool(pool).getFinalTokens();
    if (tokens_.length != 2) revert PoolDoesNotExist();

    return tokens_;
  }

  function order(
    address pool,
    uint256[] calldata prices
  )
    external
    view
    returns (
      GPv2Order.Data memory order_,
      GPv2Interaction.Data[] memory preInteractions,
      GPv2Interaction.Data[] memory, /* postInteractions */
      bytes memory sig
    )
  {
    address[] memory tokens_ = tokens(pool);

    GetTradeableOrder.GetTradeableOrderParams memory params = GetTradeableOrder.GetTradeableOrderParams({
      pool: pool,
      token0: IERC20(tokens_[0]),
      token1: IERC20(tokens_[1]),
      weightToken0: IBCoWPool(pool).getNormalizedWeight(tokens_[0]),
      weightToken1: IBCoWPool(pool).getNormalizedWeight(tokens_[1]),
      // The price of this function is expressed as amount of
      // token1 per amount of token0. The `prices` vector is
      // expressed the other way around.
      priceNumerator: prices[1],
      priceDenominator: prices[0],
      appData: APP_DATA
    });

    order_ = GetTradeableOrder.getTradeableOrder(params);

    bytes memory eip1271sig;
    eip1271sig = abi.encode(order_);
    bytes32 domainSeparator = IBCoWPool(pool).SOLUTION_SETTLER_DOMAIN_SEPARATOR();
    bytes32 orderCommitment = order_.hash(domainSeparator);

    // A ERC-1271 signature on CoW Protocol is composed of two parts: the
    // signer address and the valid ERC-1271 signature data for that signer.
    sig = abi.encodePacked(pool, eip1271sig);

    preInteractions = new GPv2Interaction.Data[](1);
    preInteractions[0] = GPv2Interaction.Data({
      target: pool,
      value: 0,
      callData: abi.encodeWithSelector(IBCoWPool.commit.selector, orderCommitment)
    });
  }
}
