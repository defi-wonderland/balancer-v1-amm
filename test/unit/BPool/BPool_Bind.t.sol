// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BPoolBase} from './BPoolBase.t.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IBPool} from 'interfaces/IBPool.sol';

contract BPoolBind is BPoolBase {
  address public token;
  uint256 public tokenBindBalance = 100e18;
  uint256 public tokenWeight = 1e18;
  uint256 public totalWeight = 10e18;

  function setUp() public virtual override {
    super.setUp();
    token = tokens[0];

    vm.mockCall(token, abi.encodePacked(IERC20.transferFrom.selector), abi.encode());
    vm.mockCall(token, abi.encodePacked(IERC20.transfer.selector), abi.encode());
  }

  function test_RevertWhen_ReentrancyLockIsSet() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    // it should revert
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  function test_RevertWhen_CallerIsNOTController(address _caller) external {
    // it should revert
    vm.assume(_caller != address(this));
    vm.prank(_caller);
    vm.expectRevert(IBPool.BPool_CallerIsNotController.selector);
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  function test_RevertWhen_TokenIsAlreadyBound() external {
    bPool.set__records(token, IBPool.Record({bound: true, index: 0, denorm: tokenWeight}));
    // it should revert
    vm.expectRevert(IBPool.BPool_TokenAlreadyBound.selector);
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  function test_RevertWhen_PoolIsFinalized() external {
    bPool.set__finalized(true);
    // it should revert
    vm.expectRevert(IBPool.BPool_PoolIsFinalized.selector);
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  function test_RevertWhen_MAX_BOUND_TOKENSTokensAreAlreadyBound() external {
    _setRandomTokens(MAX_BOUND_TOKENS);
    // it should revert
    vm.expectRevert(IBPool.BPool_TokensAboveMaximum.selector);
    bPool.bind(token, tokenBindBalance, tokenWeight);
  }

  function test_RevertWhen_TokenWeightIsTooLow() external {
    // it should revert
    vm.expectRevert(IBPool.BPool_WeightBelowMinimum.selector);
    bPool.bind(token, tokenBindBalance, MIN_WEIGHT - 1);
  }

  function test_RevertWhen_TokenWeightIsTooHigh() external {
    // it should revert
    vm.expectRevert(IBPool.BPool_WeightAboveMaximum.selector);
    bPool.bind(token, tokenBindBalance, MAX_WEIGHT + 1);
  }

  function test_RevertWhen_TooLittleBalanceIsProvided() external {
    // it should revert
    vm.expectRevert(IBPool.BPool_BalanceBelowMinimum.selector);
    bPool.bind(token, MIN_BALANCE - 1, tokenWeight);
  }

  function test_RevertWhen_WeightSumExceedsMAX_TOTAL_WEIGHT() external {
    bPool.set__totalWeight(2 * MAX_TOTAL_WEIGHT / 3);
    // it should revert
    vm.expectRevert(IBPool.BPool_TotalWeightAboveMaximum.selector);
    bPool.bind(token, tokenBindBalance, MAX_TOTAL_WEIGHT / 2);
  }

  function test_WhenTokenCanBeBound(uint256 _existingTokens) external {
    _existingTokens = bound(_existingTokens, 0, MAX_BOUND_TOKENS - 1);
    bPool.set__tokens(_getDeterministicTokenArray(_existingTokens));

    bPool.set__totalWeight(totalWeight);
    // it calls _pullUnderlying
    bPool.expectCall__pullUnderlying(token, address(this), tokenBindBalance);
    // it sets the reentrancy lock
    bPool.expectCall__setLock(_MUTEX_TAKEN);
    // it emits LOG_CALL event
    vm.expectEmit();
    bytes memory _data = abi.encodeWithSelector(IBPool.bind.selector, token, tokenBindBalance, tokenWeight);
    emit IBPool.LOG_CALL(IBPool.bind.selector, address(this), _data);

    bPool.bind(token, tokenBindBalance, tokenWeight);

    // it clears the reentrancy lock
    assertEq(bPool.call__getLock(), _MUTEX_FREE);
    // it adds token to the tokens array
    assertEq(bPool.call__tokens()[_existingTokens], token);
    // it sets the token record
    assertEq(bPool.call__records(token).bound, true);
    assertEq(bPool.call__records(token).denorm, tokenWeight);
    assertEq(bPool.call__records(token).index, _existingTokens);
    // it sets total weight
    assertEq(bPool.call__totalWeight(), totalWeight + tokenWeight);
  }
}
