// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import {BCoWPool} from './BCoWPool.sol';

import {BFactory} from './BFactory.sol';
import {IBFactory} from 'interfaces/IBFactory.sol';
import {IBPool} from 'interfaces/IBPool.sol';

/**
 * @title BCoWFactory
 * @notice Creates new BCoWPools, logging their addresses and acting as a registry of pools.
 * @dev Inherits BFactory contract functionalities, but deploys BCoWPools instead of BPool.
 */
contract BCoWFactory is BFactory {
  /**
   * @notice The address of the SolutionSettler contract, which is the source of truth
   * for the configuration of the BCoWPool contract.
   */
  address public immutable SOLUTION_SETTLER;

  constructor(address _solutionSettler) BFactory() {
    SOLUTION_SETTLER = _solutionSettler;
  }

  /**
   * @inheritdoc IBFactory
   * @dev Deploys a BCoWPool instead of a regular BPool, maintains the interface
   * to minimize required changes to existing tooling
   */
  function newBPool() external override returns (IBPool _pool) {
    IBPool bpool = new BCoWPool(SOLUTION_SETTLER);
    _isBPool[address(bpool)] = true;
    emit LOG_NEW_POOL(msg.sender, address(bpool));
    bpool.setController(msg.sender);
    return bpool;
  }
}
