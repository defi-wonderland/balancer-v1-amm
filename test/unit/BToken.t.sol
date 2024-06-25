// SPDX-License-Identifier: GPL-3
import "forge-std/console.sol";
pragma solidity ^0.8.25;

import {IERC20Errors} from '@openzeppelin/contracts/interfaces/draft-IERC6093.sol';
import {Test} from 'forge-std/Test.sol';
import {MockBToken} from 'test/smock/MockBToken.sol';
import {BNum} from 'contracts/BNum.sol';

contract BToken_Unit_Constructor is Test {
  function test_ConstructorParams() public {
    MockBToken btoken = new MockBToken();
    assertEq(btoken.name(), 'Balancer Pool Token');
    assertEq(btoken.symbol(), 'BPT');
    assertEq(btoken.decimals(), 18);
  }
}

abstract contract BToken_Unit_base is Test {
  MockBToken internal bToken;

  modifier assumeNonZeroAddresses(address addr1, address addr2) {
    vm.assume(addr1 != address(0));
    vm.assume(addr2 != address(0));
    _;
  }

  modifier assumeNonZeroAddress(address addr) {
    vm.assume(addr != address(0));
    _;
  }

  function setUp() public virtual {
    bToken = new MockBToken();
  }
}

contract BToken_Unit_IncreaseApproval is BToken_Unit_base, BNum {

  function test_bpow_distributiveBase(uint256 _base, uint256 _a, uint256 _b) public {
    _base = bound(_base,MIN_BPOW_BASE,MAX_BPOW_BASE);
    _a = bound(_a,0,50e18);
    _b = bound(_b,0,50e18);
    uint256 _result1 = bpow(_base, badd(_a, _b));
    uint256 _result2 = bmul(bpow(_base, _a), bpow(_base, _b));
    console.log('_base   :', _base);
    console.log('_a   :', _a);
    console.log('_b   :', _b);
    console.log('_result1   :', _result1);
    console.log('_result2   :', _result2);
    assertEq(_result1,_result2);
  }

  function test_increasesApprovalFromZero(
    address sender,
    address spender,
    uint256 amount
  ) public assumeNonZeroAddresses(sender, spender) {
    vm.prank(sender);
    bToken.increaseApproval(spender, amount);
    assertEq(bToken.allowance(sender, spender), amount);
  }

  function test_increasesApprovalFromNonZero(
    address sender,
    address spender,
    uint128 existingAllowance,
    uint128 amount
  ) public assumeNonZeroAddresses(sender, spender) {
    vm.assume(existingAllowance > 0);
    vm.startPrank(sender);
    bToken.approve(spender, existingAllowance);
    bToken.increaseApproval(spender, amount);
    vm.stopPrank();
    assertEq(bToken.allowance(sender, spender), uint256(amount) + existingAllowance);
  }
}

contract BToken_Unit_DecreaseApproval is BToken_Unit_base {
  function test_decreaseApprovalToNonZero(
    address sender,
    address spender,
    uint256 existingAllowance,
    uint256 amount
  ) public assumeNonZeroAddresses(sender, spender) {
    existingAllowance = bound(existingAllowance, 1, type(uint256).max);
    amount = bound(amount, 0, existingAllowance - 1);
    vm.startPrank(sender);
    bToken.approve(spender, existingAllowance);
    bToken.decreaseApproval(spender, amount);
    vm.stopPrank();
    assertEq(bToken.allowance(sender, spender), existingAllowance - amount);
  }

  function test_decreaseApprovalToZero(
    address sender,
    address spender,
    uint256 existingAllowance,
    uint256 amount
  ) public assumeNonZeroAddresses(sender, spender) {
    amount = bound(amount, existingAllowance, type(uint256).max);
    vm.startPrank(sender);
    bToken.approve(spender, existingAllowance);
    bToken.decreaseApproval(spender, amount);
    vm.stopPrank();
    assertEq(bToken.allowance(sender, spender), 0);
  }
}

contract BToken_Unit__push is BToken_Unit_base {
  function test_revertsOnInsufficientSelfBalance(
    address to,
    uint128 existingBalance,
    uint128 offset
  ) public assumeNonZeroAddress(to) {
    vm.assume(offset > 1);
    deal(address(bToken), address(bToken), existingBalance);
    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientBalance.selector,
        address(bToken),
        existingBalance,
        uint256(existingBalance) + offset
      )
    );
    bToken.call__push(to, uint256(existingBalance) + offset);
  }

  function test_sendsTokens(
    address to,
    uint128 existingBalance,
    uint256 transferAmount
  ) public assumeNonZeroAddress(to) {
    vm.assume(to != address(bToken));
    transferAmount = bound(transferAmount, 0, existingBalance);
    deal(address(bToken), address(bToken), existingBalance);
    bToken.call__push(to, transferAmount);
    assertEq(bToken.balanceOf(to), transferAmount);
    assertEq(bToken.balanceOf(address(bToken)), existingBalance - transferAmount);
  }
}

contract BToken_Unit__pull is BToken_Unit_base {
  function test_revertsOnInsufficientFromBalance(
    address from,
    uint128 existingBalance,
    uint128 offset
  ) public assumeNonZeroAddress(from) {
    vm.assume(offset > 1);
    deal(address(bToken), from, existingBalance);
    vm.expectRevert(
      abi.encodeWithSelector(
        IERC20Errors.ERC20InsufficientBalance.selector, from, existingBalance, uint256(existingBalance) + offset
      )
    );
    bToken.call__pull(from, uint256(existingBalance) + offset);
  }

  function test_getsTokens(
    address from,
    uint128 existingBalance,
    uint256 transferAmount
  ) public assumeNonZeroAddress(from) {
    vm.assume(from != address(bToken));
    transferAmount = bound(transferAmount, 0, existingBalance);
    deal(address(bToken), address(from), existingBalance);
    bToken.call__pull(from, transferAmount);
    assertEq(bToken.balanceOf(address(bToken)), transferAmount);
    assertEq(bToken.balanceOf(from), existingBalance - transferAmount);
  }
}
