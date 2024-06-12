// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import {GPv2Order} from '@cowprotocol/libraries/GPv2Order.sol';
import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';

interface IBCoWPool is IERC1271, IBPool {
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
   * @notice thrown when a CoW order has a non-zero fee
   */
  error BCoWPool_FeeMustBeZero();

  /**
   * @notice thrown when a CoW order is executed after its deadline
   */
  error BCoWPool_OrderValidityTooLong();

  /**
   * @notice thrown when a CoW order has an unkown type (must be GPv2Order.KIND_SELL)
   */
  error BCoWPool_InvalidOperation();

  /**
   * @notice thrown when a CoW order has an invalid balance marker. BCoWPool
   * only supports BALANCE_ERC20, instructing to use the underlying ERC20
   * balance directly instead of balancer's internal accounting
   */
  error BCoWPool_InvalidBalanceMarker();

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

  function enableTrading(bytes32 appData) external;

  function disableTrading() external;

  function commit(bytes32 orderHash) external;

  function EMPTY_COMMITMENT() external view returns (bytes32 _emptyCommitment);

  function NO_TRADING() external view returns (bytes32 _noTrading);

  function MAX_ORDER_DURATION() external view returns (uint32 _maxOrderDuration);

  function COMMITMENT_SLOT() external view returns (uint256 _commitmentSlot);

  function VAULT_RELAYER() external view returns (address _vaultRelayer);

  function SOLUTION_SETTLER_DOMAIN_SEPARATOR() external view returns (bytes32 _solutionSettlerDomainSeparator);

  function SOLUTION_SETTLER() external view returns (ISettlement _solutionSettler);

  function appDataHash() external view returns (bytes32 _appDataHash);

  function commitment() external view returns (bytes32 _commitment);

  function verify(GPv2Order.Data memory order) external view;
}
