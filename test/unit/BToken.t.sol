// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from 'forge-std/Test.sol';

contract BTokenTest is Test {
  function test_IncreaseApprovalWhenCalled() external {
    // it should increase the allowance of dst by amt
    // it should return true
    vm.skip(true);
  }

  function test_DecreaseApprovalWhenCalledWithAnAmtGreatherThanTheCurrentAllowance() external {
    // it should set the allowance to 0
    // it should return true
    vm.skip(true);
  }

  function test_DecreaseApprovalWhenCalledWithAnAmtLteAsTheCurrentAllowance() external {
    // it should decrease the allowance of dst by amt
    // it should return true
    vm.skip(true);
  }
}
