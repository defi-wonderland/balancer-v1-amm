// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import {BBronze} from './BColor.sol';
import {BPool} from './BPool.sol';
import {IBFactory} from 'interfaces/IBFactory.sol';
import {IBPool} from 'interfaces/IBPool.sol';

import {IERC20} from './BToken.sol';

/**
 * @title BFactory
 * @notice Creates new BPools, logging their addresses and acting as a registry of pools.
 */
contract BFactory is BBronze, IBFactory {
  mapping(address => bool) internal _isBPool;
  address internal _blabs;

  constructor() {
    _blabs = msg.sender;
  }

  function newBPool() external returns (IBPool _pool) {
    IBPool bpool = IBPool(address(new BPool()));
    _isBPool[address(bpool)] = true;
    emit LOG_NEW_POOL(msg.sender, address(bpool));
    bpool.setController(msg.sender);
    return bpool;
  }

  function setBLabs(address b) external {
    require(msg.sender == _blabs, 'ERR_NOT_BLABS');
    emit LOG_BLABS(msg.sender, b);
    _blabs = b;
  }

  function collect(address pool) external {
    require(msg.sender == _blabs, 'ERR_NOT_BLABS');
    uint256 collected = IERC20(pool).balanceOf(address(this));
    bool xfer = IERC20(pool).transfer(_blabs, collected);
    require(xfer, 'ERR_ERC20_FAILED');
  }

  function isBPool(address b) external view returns (bool) {
    return _isBPool[b];
  }

  function getBLabs() external view returns (address) {
    return _blabs;
  }
}
