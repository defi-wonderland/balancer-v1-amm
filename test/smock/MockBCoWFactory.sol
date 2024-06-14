// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {BCoWFactory, BCoWPool, BFactory, IBFactory, IBPool} from '../../src/contracts/BCoWFactory.sol';
import {Test} from 'forge-std/Test.sol';

contract MockBCoWFactory is BCoWFactory, Test {
  function set_solutionSettler(address _solutionSettler) public {
    solutionSettler = _solutionSettler;
  }

  function mock_call_solutionSettler(address _value) public {
    vm.mockCall(address(this), abi.encodeWithSignature('solutionSettler()'), abi.encode(_value));
  }

  constructor(address _solutionSettler) BCoWFactory(_solutionSettler) {}

  function mock_call_newBPool(IBPool _pool) public {
    vm.mockCall(address(this), abi.encodeWithSignature('newBPool()'), abi.encode(_pool));
  }
}
