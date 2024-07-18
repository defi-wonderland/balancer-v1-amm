// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BPoolBase} from './BPoolBase.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {MockBPool} from 'test/smock/MockBPool.sol';

contract BPool is BPoolBase {
  address controller = makeAddr('controller');
  address unknownToken = makeAddr('unknown token');
  uint256 swapFee = 0.1e18;

  function setUp() public virtual override {
    super.setUp();

    bPool.set__finalized(true);
    bPool.set__tokens(tokens);
    _setRecord(tokens[0], IBPool.Record({bound: true, index: 0, denorm: tokenWeight}));
    _setRecord(tokens[1], IBPool.Record({bound: true, index: 1, denorm: tokenWeight}));
    bPool.set__totalWeight(totalWeight);
    bPool.set__swapFee(swapFee);
    bPool.set__controller(controller);
  }

  function test_ConstructorWhenCalled(address _deployer) external {
    vm.prank(_deployer);
    MockBPool _newBPool = new MockBPool();

    // it sets caller as controller
    assertEq(_newBPool.call__controller(), _deployer);
    // it sets caller as factory
    assertEq(_newBPool.FACTORY(), _deployer);
    // it sets swap fee to MIN_FEE
    assertEq(_newBPool.call__swapFee(), MIN_FEE);
    // it does NOT finalize the pool
    assertEq(_newBPool.call__finalized(), false);
  }

  function test_IsFinalizedWhenPoolIsFinalized() external view {
    // it returns true
    assertTrue(bPool.isFinalized());
  }

  function test_IsFinalizedWhenPoolIsNOTFinalized() external {
    bPool.set__finalized(false);
    // it returns false
    assertFalse(bPool.isFinalized());
  }

  function test_IsBoundWhenTokenIsBound(address _token) external {
    _setRecord(_token, IBPool.Record({bound: true, index: 0, denorm: 0}));
    // it returns true
    assertTrue(bPool.isBound(_token));
  }

  function test_IsBoundWhenTokenIsNOTBound(address _token) external {
    _setRecord(_token, IBPool.Record({bound: false, index: 0, denorm: 0}));
    // it returns false
    assertFalse(bPool.isBound(_token));
  }

  function test_GetNumTokensWhenCalled(uint256 _tokensToAdd) external {
    _tokensToAdd = bound(_tokensToAdd, 0, MAX_BOUND_TOKENS);
    _setRandomTokens(_tokensToAdd);
    // it returns number of tokens
    assertEq(bPool.getNumTokens(), _tokensToAdd);
  }

  function test_GetFinalTokensRevertWhen_ReentrancyLockIsSet() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    // it should revert
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    bPool.getFinalTokens();
  }

  function test_GetFinalTokensRevertWhen_PoolIsNotFinalized() external {
    bPool.set__finalized(false);
    // it should revert
    vm.expectRevert(IBPool.BPool_PoolNotFinalized.selector);
    bPool.getFinalTokens();
  }

  function test_GetFinalTokensWhenPreconditionsAreMet() external view {
    // it returns pool tokens
    address[] memory _tokens = bPool.getFinalTokens();
    assertEq(_tokens.length, tokens.length);
    assertEq(_tokens[0], tokens[0]);
    assertEq(_tokens[1], tokens[1]);
  }

  function test_GetCurrentTokensRevertWhen_ReentrancyLockIsSet() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    // it should revert
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    bPool.getCurrentTokens();
  }

  function test_GetCurrentTokensWhenPreconditionsAreMet() external view {
    // it returns pool tokens
    address[] memory _tokens = bPool.getCurrentTokens();
    assertEq(_tokens.length, tokens.length);
    assertEq(_tokens[0], tokens[0]);
    assertEq(_tokens[1], tokens[1]);
  }

  function test_GetDenormalizedWeightRevertWhen_ReentrancyLockIsSet() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    // it should revert
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    bPool.getDenormalizedWeight(tokens[0]);
  }

  function test_GetDenormalizedWeightRevertWhen_TokenIsNotBound() external {
    // it should revert
    vm.expectRevert(IBPool.BPool_TokenNotBound.selector);
    bPool.getDenormalizedWeight(unknownToken);
  }

  function test_GetDenormalizedWeightWhenPreconditionsAreMet() external view {
    // it returns token weight
    uint256 _tokenWeight = bPool.getDenormalizedWeight(tokens[0]);
    assertEq(_tokenWeight, tokenWeight);
  }

  function test_GetTotalDenormalizedWeightRevertWhen_ReentrancyLockIsSet() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    // it should revert
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    bPool.getTotalDenormalizedWeight();
  }

  function test_GetTotalDenormalizedWeightWhenPreconditionsAreMet() external view {
    // it returns total weight
    uint256 _totalWeight = bPool.getTotalDenormalizedWeight();
    assertEq(_totalWeight, totalWeight);
  }

  function test_GetNormalizedWeightRevertWhen_ReentrancyLockIsSet() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    // it should revert
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    bPool.getNormalizedWeight(tokens[0]);
  }

  function test_GetNormalizedWeightRevertWhen_TokenIsNotBound() external {
    // it should revert
    vm.expectRevert(IBPool.BPool_TokenNotBound.selector);
    bPool.getNormalizedWeight(unknownToken);
  }

  function test_GetNormalizedWeightWhenPreconditionsAreMet() external view {
    // it returns normalized weight
    //     normalizedWeight = tokenWeight / totalWeight
    uint256 _normalizedWeight = bPool.getNormalizedWeight(tokens[0]);
    assertEq(_normalizedWeight, 0.1e18);
  }

  function test_GetBalanceRevertWhen_ReentrancyLockIsSet() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    // it should revert
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    bPool.getBalance(tokens[0]);
  }

  function test_GetBalanceRevertWhen_TokenIsNotBound() external {
    // it should revert
    vm.expectRevert(IBPool.BPool_TokenNotBound.selector);
    bPool.getBalance(unknownToken);
  }

  function test_GetBalanceWhenPreconditionsAreMet(uint256 tokenBalance) external {
    vm.mockCall(tokens[0], abi.encodePacked(IERC20.balanceOf.selector), abi.encode(tokenBalance));
    // it queries token balance
    vm.expectCall(tokens[0], abi.encodeWithSelector(IERC20.balanceOf.selector));
    // it returns token balance
    uint256 _balance = bPool.getBalance(tokens[0]);
    assertEq(_balance, tokenBalance);
  }

  function test_GetSwapFeeRevertWhen_ReentrancyLockIsSet() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    // it should revert
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    bPool.getSwapFee();
  }

  function test_GetSwapFeeWhenPreconditionsAreMet() external view {
    // it returns swap fee
    uint256 _swapFee = bPool.getSwapFee();
    assertEq(_swapFee, swapFee);
  }

  function test_GetControllerRevertWhen_ReentrancyLockIsSet() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    // it should revert
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    bPool.getController();
  }

  function test_GetControllerWhenPreconditionsAreMet() external view {
    // it returns controller
    address _controller = bPool.getController();
    assertEq(_controller, controller);
  }
}
