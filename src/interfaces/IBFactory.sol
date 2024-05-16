// SPDX-License-Identifier: GPL-3.0 or later
pragma solidity 0.8.25;

// TODO: Complete the interface and add natspec
interface IBFactory {
  event LOG_NEW_POOL(address indexed caller, address indexed pool);

  event LOG_BLABS(address indexed caller, address indexed blabs);

  function getCowSwap() external view returns (address);
}
