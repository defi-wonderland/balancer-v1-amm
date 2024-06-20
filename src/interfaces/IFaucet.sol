// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

/**
 * @title IFaucet
 * @notice External interface of Sepolia's Faucet contract.
 */
interface IFaucet {
  function drip(address token) external;
}
