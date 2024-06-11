// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

interface ISettlement {
  /**
   * @return the domain separator for IERC1271 signature
   * @dev is an immutable value, would not change on chain forks
   */
  function domainSeparator() external view returns (bytes32);
  /**
   * @return the address that'll use the pool liquidity in CoWprotocol swaps
   * @dev will transfer and transferFrom the pool. Has an infinite allowance.
   */
  function vaultRelayer() external view returns (address);
}
