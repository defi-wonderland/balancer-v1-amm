// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BPoolBase} from './BPoolBase.sol';
import {IBPool} from 'interfaces/IBPool.sol';

contract BPool_Bind is BPoolBase {
  function test_WhenReentrancyLockIsNOTSetRevertWhen_CallerIsNOTController(address _caller) external {
    // it should revert
    vm.assume(_caller != deployer);
    vm.prank(_caller);
    vm.expectRevert(IBPool.BPool_CallerIsNotController.selector);
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  modifier whenCallerIsController() {
    vm.startPrank(deployer);
    _;
  }

  function test_WhenReentrancyLockIsNOTSetRevertWhen_TokenIsAlreadyBound() external whenCallerIsController {
    _setRecord(token, IBPool.Record({bound: true, index: 0, denorm: tokenWeight}));
    // it should revert
    vm.expectRevert(IBPool.BPool_TokenAlreadyBound.selector);
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  function test_WhenReentrancyLockIsNOTSetRevertWhen_PoolIsFinalized() external whenCallerIsController {
    bPool.set__finalized(true);
    // it should revert
    vm.expectRevert(IBPool.BPool_PoolIsFinalized.selector);
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  function test_WhenReentrancyLockIsNOTSetRevertWhen_MAX_BOUND_TOKENSTokensAreAlreadyBound()
    external
    whenCallerIsController
  {
    _setRandomTokens(MAX_BOUND_TOKENS);
    // it should revert
    vm.expectRevert(IBPool.BPool_TokensAboveMaximum.selector);
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  function test_WhenReentrancyLockIsNOTSetRevertWhen_TokenWeightIsTooLow() external whenCallerIsController {
    // it should revert
    vm.expectRevert(IBPool.BPool_WeightBelowMinimum.selector);
    bPool.bind(token, tokenBindBalance, MIN_WEIGHT - 1);
  }

  function test_WhenReentrancyLockIsNOTSetRevertWhen_TokenWeightIsTooHigh() external whenCallerIsController {
    // it should revert
    vm.expectRevert(IBPool.BPool_WeightAboveMaximum.selector);
    bPool.bind(token, tokenBindBalance, MAX_WEIGHT + 1);
  }

  function test_WhenReentrancyLockIsNOTSetRevertWhen_TooLittleBalanceIsProvided() external whenCallerIsController {
    // it should revert
    vm.expectRevert(IBPool.BPool_BalanceBelowMinimum.selector);
    bPool.bind(token, MIN_BALANCE - 1, tokenWeight);
  }

  function test_WhenReentrancyLockIsNOTSetRevertWhen_WeightSumExceedsMAX_TOTAL_WEIGHT() external whenCallerIsController {
    bPool.set__totalWeight(2 * MAX_TOTAL_WEIGHT / 3);
    // it should revert
    vm.expectRevert(IBPool.BPool_TotalWeightAboveMaximum.selector);
    bPool.bind(token, tokenBindBalance, MAX_TOTAL_WEIGHT / 2);
  }

  function test_WhenReentrancyLockIsNOTSetWhenTokenCanBeBound() external whenCallerIsController {
    uint256 _startTotalWeight = 1e18;
    bPool.set__totalWeight(_startTotalWeight);
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
    // use a starting value to ensure it's decreased and not cleared
    assertEq(bPool.call__totalWeight(), tokenWeight + _startTotalWeight);
  }

  function test_WhenReentrancyLockIsSetShouldRevert() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    // it should revert
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }
}
