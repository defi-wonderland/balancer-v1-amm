// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Test} from 'forge-std/Test.sol';
import {MockBToken} from 'test/smock/MockBToken.sol';

contract BTokenTest is Test {
  MockBToken public bToken;
  uint256 public initialApproval = 100e18;
  uint256 public initialBalance = 100e18;
  address public caller = makeAddr('caller');
  address public spender = makeAddr('spender');
  address public target = makeAddr('target');

  function setUp() external {
    bToken = new MockBToken();

    vm.startPrank(caller);
    // sets initial approval (cannot be mocked)
    bToken.approve(spender, initialApproval);
  }

  function test_ConstructorWhenCalled() external {
    MockBToken _bToken = new MockBToken();
    // it sets token name
    assertEq(_bToken.name(), 'Balancer Pool Token');
    // it sets token symbol
    assertEq(_bToken.symbol(), 'BPT');
  }

  function test_IncreaseApprovalWhenCalled() external {
    bToken.increaseApproval(spender, 100e18);
    // it increases spender approval
    assertEq(bToken.allowance(caller, spender), 200e18);
  }

  function test_DecreaseApprovalWhenDecrementIsBiggerThanCurrentApproval() external {
    bToken.decreaseApproval(spender, 200e18);
    // it decreases spender approval to 0
    assertEq(bToken.allowance(caller, spender), 0);
  }

  function test_DecreaseApprovalWhenCalled() external {
    bToken.decreaseApproval(spender, 50e18);
    // it decreases spender approval
    assertEq(bToken.allowance(caller, spender), 50e18);
  }

  function test__pushWhenCalled() external {
    deal(address(bToken), address(bToken), initialBalance);
    bToken.call__push(target, 50e18);

    // it transfers tokens to recipient
    assertEq(bToken.balanceOf(address(bToken)), 50e18);
    assertEq(bToken.balanceOf(target), 50e18);
  }

  function test__pullWhenCalled() external {
    deal(address(bToken), address(target), initialBalance);
    bToken.call__pull(target, 50e18);

    // it transfers tokens from sender
    assertEq(bToken.balanceOf(target), 50e18);
    assertEq(bToken.balanceOf(address(bToken)), 50e18);
  }
}
