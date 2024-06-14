// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import {BCoWPool} from './BCoWPool.sol';

import {BFactory} from './BFactory.sol';
import {IBFactory} from 'interfaces/IBFactory.sol';
import {IBPool} from 'interfaces/IBPool.sol';

/**
 * @title BCoWFactory
 * @notice Creates new BPools, logging their addresses and acting as a registry of pools.
 */
contract BCoWFactory is BFactory {
  address public solutionSettler;

  constructor(address _solutionSettler) BFactory() {
    solutionSettler = _solutionSettler;
  }

  /**
   * @inheritdoc IBFactory
   * @dev deploys a BCoWPool instead of a regular BPool, maintains the interface
   * to minimize required changes to existing tooling
   */
  function newBPool() external override returns (IBPool _pool) {
    IBPool bpool = new BCoWPool(solutionSettler);
    _isBPool[address(bpool)] = true;
    emit LOG_NEW_POOL(msg.sender, address(bpool));
    bpool.setController(msg.sender);
    return bpool;
  }
}
