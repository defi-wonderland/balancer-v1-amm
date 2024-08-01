// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {BCoWPool} from 'contracts/BCoWPool.sol';

contract BCoWPoolForTest is BCoWPool {
  constructor(
    address cowSolutionSettler,
    bytes32 appData,
    string memory name,
    string memory symbol
  ) BCoWPool(cowSolutionSettler, appData, name, symbol) {}

  bytes32 private _reenteringMutex;

  /// @dev workaround for hevm not supporting tload/tstore
  function _setLock(bytes32 value) internal override {
    _reenteringMutex = value;
  }

  /// @dev workaround for hevm not supporting tload/tstore
  function _getLock() internal view override returns (bytes32 value) {
    value = _reenteringMutex;
  }

  /// @dev workaround for hevm not supporting mcopy
  function _pullUnderlying(address token, address from, uint256 amount) internal override {
    IERC20(token).transferFrom(from, address(this), amount);
  }

  /// @dev workaround for hevm not supporting mcopy
  function _pushUnderlying(address token, address to, uint256 amount) internal override {
    IERC20(token).transfer(to, amount);
  }
}
