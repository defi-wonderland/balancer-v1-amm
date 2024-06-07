// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

// Builds new BPools, logging their addresses and providing `isBPool(address) -> (bool)`
import {BCoWPool as BPool} from './BCoWPool.sol'; // TODO: create a separate factory for BCoWPool
import {IBFactory} from 'interfaces/IBFactory.sol';
import {IBPool} from 'interfaces/IBPool.sol';

contract BFactory is IBFactory {
  mapping(address => bool) internal _isBPool;
  address internal _bLabs;
  address internal _cowSwap;

  constructor(address cowSwap) {
    _bLabs = msg.sender;
    _cowSwap = cowSwap;
  }

  function newBPool() external returns (IBPool _pool) {
    IBPool bpool = new BPool(_cowSwap);
    _isBPool[address(bpool)] = true;
    emit LOG_NEW_POOL(msg.sender, address(bpool));
    bpool.setController(msg.sender);
    return bpool;
  }

  function setBLabs(address b) external {
    require(msg.sender == _bLabs, 'ERR_NOT_BLABS');
    emit LOG_BLABS(msg.sender, b);
    _bLabs = b;
  }

  function collect(IBPool pool) external {
    require(msg.sender == _bLabs, 'ERR_NOT_BLABS');
    uint256 collected = pool.balanceOf(address(this));
    bool xfer = pool.transfer(_bLabs, collected);
    require(xfer, 'ERR_ERC20_FAILED');
  }

  function isBPool(address b) external view returns (bool) {
    return _isBPool[b];
  }

  function getBLabs() external view returns (address) {
    return _bLabs;
  }

  function getCowSwap() external view returns (address) {
    return _cowSwap;
  }
}
