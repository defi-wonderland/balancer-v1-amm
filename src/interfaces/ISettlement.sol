// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

interface ISettlement {
  function domainSeparator() external view returns (bytes32);
}
