// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import {BCoWPool} from './BCoWPool.sol';

import {BFactory} from './BFactory.sol';
import {IBFactory} from 'interfaces/IBFactory.sol';
import {IBPool} from 'interfaces/IBPool.sol';

/**
 * @title BCoWFactory
 * @notice Creates new BCoWPools, logging their addresses and acting as a registry of pools.
 */
contract BCoWFactory is BFactory {
  address public immutable SOLUTION_SETTLER;
  bytes32 public immutable APP_DATA;

  constructor(address _solutionSettler, bytes32 _appData) BFactory() {
    SOLUTION_SETTLER = _solutionSettler;
    APP_DATA = _appData;
  }

  /**
   * @dev Deploys a BCoWPool instead of a regular BPool.
   */
  function _newBPool() internal virtual override returns (IBPool _pool) {
    return new BCoWPool(SOLUTION_SETTLER, APP_DATA);
  }
}
