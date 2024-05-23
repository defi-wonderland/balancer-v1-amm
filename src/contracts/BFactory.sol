// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

// Builds new BPools, logging their addresses and providing `isBPool(address) -> (bool)`

// TODO: create a separate factory contract for BCoWPool
import {BCoWPool as BPool} from './BCoWPool.sol';
import {BBronze} from './BColor.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import 'interfaces/IBFactory.sol';

contract BFactory is IBFactory, BBronze {
  mapping(address => bool) internal _isBPool;

  function isBPool(address b) external view returns (bool) {
    return _isBPool[b];
  }

  function newBPool() external returns (BPool) {
    BPool bPool = new BPool(_cowSwap);
    _isBPool[address(bPool)] = true;
    emit LOG_NEW_POOL(msg.sender, address(bPool));
    bPool.setController(msg.sender);
    return bPool;
  }

  address internal _bLabs;
  address internal _cowSwap;

  constructor(address cowSwap) {
    _bLabs = msg.sender;
    _cowSwap = cowSwap;
  }

  function getBLabs() external view returns (address) {
    return _bLabs;
  }

  function getCowSwap() external view returns (address) {
    return _cowSwap;
  }

  function setBLabs(address b) external {
    require(msg.sender == _bLabs, 'ERR_NOT_BLABS');
    emit LOG_BLABS(msg.sender, b);
    _bLabs = b;
  }

  function collect(BPool pool) external {
    require(msg.sender == _bLabs, 'ERR_NOT_BLABS');
    uint256 collected = IERC20(address(pool)).balanceOf(address(this));
    bool xfer = pool.transfer(_bLabs, collected);
    require(xfer, 'ERR_ERC20_FAILED');
  }
}
