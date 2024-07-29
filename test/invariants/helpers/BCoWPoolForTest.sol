// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import {BCoWPool} from 'contracts/BCoWPool.sol';

contract BCoWPoolForTest is BCoWPool {
  constructor(address cowSolutionSettler, bytes32 appData) BCoWPool(cowSolutionSettler, appData) {}

  bytes32 private _reenteringMutex;

  /// @dev workaround for hevm not supporting tload/tstore
  function _setLock(bytes32 value) internal override {
    _reenteringMutex = value;
  }

  /// @dev workaround for hevm not supporting tload/tstore
  function _getLock() internal view override returns (bytes32 value) {
    value = _reenteringMutex;
  }
}
