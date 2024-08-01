// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import {BCoWPoolForTest} from './BCoWPoolForTest.sol';
import {BCoWFactory} from 'contracts/BCoWFactory.sol';
import {IBPool} from 'interfaces/IBPool.sol';

contract BCoWFactoryForTest is BCoWFactory {
  constructor(address cowSolutionSettler, bytes32 appData) BCoWFactory(cowSolutionSettler, appData) {}

  function _newBPool(string memory, string memory) internal virtual override returns (IBPool bCoWPool) {
    bCoWPool = new BCoWPoolForTest(SOLUTION_SETTLER, APP_DATA, 'name', 'symbol');
  }
}
