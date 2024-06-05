// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import {IBPool} from 'interfaces/IBPool.sol';

interface IBFactory {
  /**
   * @notice Emitted when creating a new pool
   * @param _caller The caller of the new pool function
   * @param _pool The address of the new pool
   */
  event LOG_NEW_POOL(address indexed _caller, address indexed _pool);

  /**
   * @notice Emitted when setting the BLabs address
   * @param _caller The caller of the set BLabs function
   * @param _bLabs The address of the new BLabs
   */
  event LOG_BLABS(address indexed _caller, address indexed _bLabs);

  /**
   * @notice Creates a new BPool, assigning msg.sender as the controller
   * @return _pool The new BPool
   */
  function newBPool() external returns (IBPool _pool);

  /**
   * @notice Sets the BLabs address in the factory
   * @param _b The new BLabs address
   */
  function setBLabs(address _b) external;

  /**
   * @notice Collects the balance of a pool and transfers it to BLabs address
   * @param _pool The address of the pool to collect fees from
   */
  function collect(address _pool) external;

  /**
   * @notice Checks if an address is a BPool
   * @param _b The address to check
   * @return _isBPool True if the address is a BPool, False otherwise
   */
  function isBPool(address _b) external view returns (bool _isBPool);

  /**
   * @notice Gets the BLabs address
   * @return _bLabs The address of the BLabs
   */
  function getBLabs() external view returns (address _bLabs);
}
