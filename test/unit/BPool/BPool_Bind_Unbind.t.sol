// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BPoolBase} from './BPool.t.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IBPool} from 'interfaces/IBPool.sol';

contract BPool is BPoolBase {
  address public token = makeAddr('token');
  uint256 public tokenBindBalance = 100e18;
  uint256 public tokenWeight = 1e18;

  function setUp() public virtual override {
    super.setUp();
    vm.mockCall(token, abi.encodePacked(IERC20.transferFrom.selector), abi.encode());
  }

  modifier whenReentrancyLockIsNOTSet() {
    _;
  }

  function test_BindRevertWhen_CalledNOTByController(address _caller) external whenReentrancyLockIsNOTSet {
    // it should revert
    vm.assume(_caller != deployer);
    vm.prank(_caller);
    vm.expectRevert(IBPool.BPool_CallerIsNotController.selector);
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  modifier whenCalledByController() {
    vm.startPrank(deployer);
    _;
  }

  function test_BindRevertWhen_PoolIsFinalized() external whenReentrancyLockIsNOTSet whenCalledByController {
    bPool.set__finalized(true);
    // it should revert
    vm.expectRevert(IBPool.BPool_PoolIsFinalized.selector);
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  function test_BindRevertWhen_TokenIsAlreadyBound() external whenReentrancyLockIsNOTSet whenCalledByController {
    _setRecord(token, IBPool.Record({bound: true, index: 0, denorm: tokenWeight}));

    // it should revert
    vm.expectRevert(IBPool.BPool_TokenAlreadyBound.selector);
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  function test_BindRevertWhen_MAX_BOUND_TOKENSTokensAreAlreadyBound()
    external
    whenReentrancyLockIsNOTSet
    whenCalledByController
  {
    _setRandomTokens(MAX_BOUND_TOKENS);
    // it should revert
    vm.expectRevert(IBPool.BPool_TokensAboveMaximum.selector);
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  function test_BindRevertWhen_TokenWeightIsTooLow() external whenReentrancyLockIsNOTSet whenCalledByController {
    // it should revert
    vm.expectRevert(IBPool.BPool_WeightBelowMinimum.selector);
    bPool.bind(token, tokenBindBalance, MIN_WEIGHT - 1);
  }

  function test_BindRevertWhen_TokenWeightIsTooHigh() external whenReentrancyLockIsNOTSet whenCalledByController {
    // it should revert
    vm.expectRevert(IBPool.BPool_WeightAboveMaximum.selector);
    bPool.bind(token, tokenBindBalance, MAX_WEIGHT + 1);
  }

  function test_BindRevertWhen_TooLittleBalanceIsProvided() external whenReentrancyLockIsNOTSet whenCalledByController {
    // it should revert
    vm.expectRevert(IBPool.BPool_BalanceBelowMinimum.selector);
    bPool.bind(token, MIN_BALANCE - 1, tokenWeight);
  }

  function test_BindRevertWhen_WeightSumExceedsMAX_TOTAL_WEIGHT()
    external
    whenReentrancyLockIsNOTSet
    whenCalledByController
  {
    bPool.set__totalWeight(2 * MAX_TOTAL_WEIGHT / 3);
    // it should revert
    vm.expectRevert(IBPool.BPool_TotalWeightAboveMaximum.selector);
    bPool.bind(token, tokenBindBalance, MAX_TOTAL_WEIGHT / 2);
  }

  function test_BindWhenItIsNOTFinalized() external whenReentrancyLockIsNOTSet whenCalledByController {
    // it calls _pullUnderlying
    bPool.expectCall__pullUnderlying(token, deployer, tokenBindBalance);
    // it sets reentrancy lock
    bPool.expectCall__setLock(_MUTEX_TAKEN);

    bPool.bind(token, tokenBindBalance, tokenWeight);

    // it adds token to the list
    assertEq(bPool.call__tokens()[0], token);
    // it sets the token record
    assertEq(bPool.call__records(token).bound, true);
    assertEq(bPool.call__records(token).denorm, tokenWeight);
    // it sets total weight
    assertEq(bPool.call__totalWeight(), tokenWeight);
  }

  function test_BindRevertWhen_ReentrancyLockIsSet() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    // it should revert
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }
}
