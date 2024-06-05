// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import {IBPool} from 'interfaces/IBPool.sol';

interface IBFactory {
  event LOG_NEW_POOL(address indexed _caller, address indexed _pool);

  event LOG_BLABS(address indexed _caller, address indexed _bLabs);

  function newBPool() external returns (IBPool _pool);

  function setBLabs(address _b) external;

  function collect(address _pool) external;

  function isBPool(address _b) external view returns (bool _isBPool);

  function getBLabs() external view returns (address _bLabs);
}
