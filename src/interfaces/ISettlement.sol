// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import {IERC20} from 'cowprotocol/contracts/interfaces/IERC20.sol';
import {GPv2Interaction} from 'cowprotocol/contracts/libraries/GPv2Interaction.sol';
import {GPv2Trade} from 'cowprotocol/contracts/libraries/GPv2Trade.sol';

interface ISettlement {
  /**
   * @notice Settles a batch of trades.
   * @param tokens The tokens that are traded in the batch.
   * @param clearingPrices The clearing prices of the trades.
   * @param trades The trades to settle.
   * @param interactions The interactions to execute.
   */
  function settle(
    IERC20[] calldata tokens,
    uint256[] calldata clearingPrices,
    GPv2Trade.Data[] calldata trades,
    GPv2Interaction.Data[][3] calldata interactions
  ) external;

  /**
   * @return The domain separator for IERC1271 signature
   * @dev Immutable value, would not change on chain forks
   */
  function domainSeparator() external view returns (bytes32);

  /**
   * @return The address that'll use the pool liquidity in CoWprotocol swaps
   * @dev Address that will transfer and transferFrom the pool. Has an infinite allowance.
   */
  function vaultRelayer() external view returns (address);
}
