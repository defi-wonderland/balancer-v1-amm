// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import {GPv2Order, IERC20} from '../cow-swap/GPv2Order.sol';
import {IERC1271} from 'interfaces/IERC1271.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';

interface IBCoWPool is IERC1271 {
  /**
   * Emitted when the manager disables all trades by the AMM. Existing open
   * order will not be tradeable. Note that the AMM could resume trading with
   * different parameters at a later point.
   */
  event TradingDisabled();

  /**
   * Emitted when the manager enables the AMM to trade on CoW Protocol.
   * @param hash The hash of the trading parameters.
   * @param appData Trading has been enabled for this appData.
   */
  event TradingEnabled(bytes32 indexed hash, bytes32 appData);

  /**
   * @notice The `commit` function can only be called inside a CoW Swap
   * settlement. This error is thrown when the function is called from another
   * context.
   */
  error CommitOutsideOfSettlement();

  /**
   * @notice Error thrown when a solver tries to settle an AMM order on CoW
   * Protocol whose hash doesn't match the one that has been committed to.
   */
  error OrderDoesNotMatchCommitmentHash();

  /**
   * @notice On signature verification, the hash of the order supplied as part
   * of the signature does not match the provided message hash.
   * This usually means that the verification function is being provided a
   * signature that belongs to a different order.
   */
  error OrderDoesNotMatchMessageHash();

  /**
   * @notice The order trade parameters that were provided during signature
   * verification does not match the data stored in this contract _or_ the
   * AMM has not enabled trading.
   */
  error AppDataDoNotMatchHash();
}
