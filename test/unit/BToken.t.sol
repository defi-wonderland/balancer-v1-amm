// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BToken} from 'contracts/BToken.sol';
import {StdStorage, Test, stdStorage} from 'forge-std/Test.sol';

contract BTokenTest is Test {
  using stdStorage for StdStorage;

  BToken token;
  address caller = makeAddr('caller');
  address spender = makeAddr('spender');

  function setUp() public {
    token = new BToken();
  }

  function test_IncreaseApprovalWhenCalled() external {
    // Pre Condition
    vm.prank(caller);

    // Action
    bool result = token.increaseApproval(spender, 100);

    // it should increase the allowance of dst by amt
    assertEq(token.allowance(caller, spender), 100);

    // it should return true
    assertTrue(result);
  }

  function test_DecreaseApprovalWhenCalledWithAnAmtGreatherThanTheCurrentAllowance() external {
    // Pre Condition
    stdstore.target(address(token)).sig('allowance(address,address)').with_key(caller).with_key(spender).checked_write(
      120
    );

    vm.prank(caller);

    // Action
    bool result = token.decreaseApproval(spender, 200);

    // it should set the allowance to 0
    assertEq(token.allowance(caller, spender), 0);
    // it should return true
    assertTrue(result);
  }

  function test_DecreaseApprovalWhenCalledWithAnAmtLteAsTheCurrentAllowance() external {
    // Pre Condition
    stdstore.target(address(token)).sig('allowance(address,address)').with_key(caller).with_key(spender).checked_write(
      120
    );

    vm.prank(caller);

    // Action
    bool result = token.decreaseApproval(spender, 20);

    // it should decrease the allowance of dst by amt
    assertEq(token.allowance(caller, spender), 100);
    // it should return true
    assertTrue(result);
  }
}
