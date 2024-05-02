// SPDX-License-Identifier: MIT
pragma solidity 0.6.2;

import {Test, Vm} from 'forge-std/Test.sol';

abstract contract Base is Test {
  function setUp() public {}
}

contract BFactory_Unit_Constructor is Base {
  function test_constructor() public {
    assertTrue(true);
  }
}