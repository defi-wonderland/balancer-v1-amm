// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BPoolBase} from './BPoolBase.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {BNum} from 'contracts/BNum.sol';
import {IBPool} from 'interfaces/IBPool.sol';

contract BPoolJoinPool is BPoolBase {
  uint256 public poolAmountOut = 10e18;
  // Assets Under Management
  uint256 public tokenAUM = 10e18;
  uint256 public secondTokenAUM = 30e18;

  // when minting n pool shares, enough amount X of every token t should be provided to statisfy
  // Xt = n/BPT.totalSupply() * t.balanceOf(BPT)
  // in this scenario n = 10, totalSupply = 100

  // for t = token -> t.balanceOf(BPT) = tokenAUM = 10
  // therefore Xt = 10/100*10 = 10
  uint256 public requiredTokenIn = 1e18;
  // for t = secondToken -> t.balanceOf(BPT) = secondTokenAUM = 30
  // therefore Xt = 10/100*30 = 30
  uint256 public requiredSecondTokenIn = 3e18;
  // put another way, if the current 100 shares represent 30 secondToken, then
  // to mint another 10, user should provide 3 secondToken so ratio stays the same.

  function setUp() public virtual override {
    super.setUp();
    bPool.set__finalized(true);
    // simulate expected finalize outcome
    bPool.call__mintPoolShare(INIT_POOL_SUPPLY);
    bPool.call__pushPoolShare(deployer, INIT_POOL_SUPPLY);
    address[] memory _tokens = new address[](2);
    _tokens[0] = token;
    _tokens[1] = secondToken;
    bPool.set__tokens(_tokens);
    // token weights are not used for all-token joins
    _setRecord(token, IBPool.Record({bound: true, index: 0, denorm: 0}));
    _setRecord(secondToken, IBPool.Record({bound: true, index: 1, denorm: 0}));
    // underlying balances are used instead
    vm.mockCall(token, abi.encodePacked(IERC20.balanceOf.selector), abi.encode(uint256(tokenAUM)));
    vm.mockCall(secondToken, abi.encodePacked(IERC20.balanceOf.selector), abi.encode(uint256(secondTokenAUM)));
  }

  function test_RevertWhen_ReentrancyLockIsSet() external {
    bPool.call__setLock(_MUTEX_TAKEN);
    // it should revert
    vm.expectRevert(IBPool.BPool_Reentrancy.selector);
    bPool.joinPool(0, new uint256[](2));
  }

  function test_RevertWhen_PoolIsNotFinalized() external {
    bPool.set__finalized(false);
    // it should revert
    vm.expectRevert(IBPool.BPool_PoolNotFinalized.selector);
    bPool.joinPool(0, new uint256[](2));
  }

  // should not happen in the real world since finalization mints 100 tokens
  // and sends them to controller
  function test_RevertWhen_TotalSupplyIsZero() external {
    // undo what was just done by setup
    bPool.call__pullPoolShare(deployer, INIT_POOL_SUPPLY);
    bPool.call__burnPoolShare(INIT_POOL_SUPPLY);
    // it should revert
    // division by zero
    vm.expectRevert(BNum.BNum_DivZero.selector);
    bPool.joinPool(0, new uint256[](2));
  }

  function test_RevertWhen_PoolAmountOutIsTooSmall(uint256 amountOut) external {
    amountOut = bound(amountOut, 0, (INIT_POOL_SUPPLY / 1e18) / 2 - 1);
    // it should revert
    vm.expectRevert(IBPool.BPool_InvalidPoolRatio.selector);
    bPool.joinPool(amountOut, new uint256[](2));
  }

  function test_RevertWhen_BalanceOfPoolInAnyTokenIsZero() external {
    uint256[] memory maxAmounts = new uint256[](2);
    maxAmounts[0] = requiredTokenIn;
    maxAmounts[1] = requiredSecondTokenIn;
    vm.mockCall(secondToken, abi.encodePacked(IERC20.balanceOf.selector), abi.encode(uint256(0)));
    // it should revert
    vm.expectRevert(IBPool.BPool_InvalidTokenAmountIn.selector);
    bPool.joinPool(poolAmountOut, maxAmounts);
  }

  function test_RevertWhen_RequiredAmountOfATokenIsMoreThanMaxAmountsIn() external {
    uint256[] memory maxAmounts = new uint256[](2);
    maxAmounts[0] = requiredTokenIn - 100;
    maxAmounts[1] = requiredSecondTokenIn;
    // it should revert
    vm.expectRevert(IBPool.BPool_TokenAmountInAboveMaxAmountIn.selector);
    bPool.joinPool(poolAmountOut, maxAmounts);
  }

  function test_WhenPreconditionsAreMet() external {
    // it sets reentrancy lock
    bPool.expectCall__setLock(_MUTEX_TAKEN);
    // it calls _pullUnderlying for every token
    bPool.mock_call__pullUnderlying(token, address(this), requiredTokenIn);
    bPool.expectCall__pullUnderlying(token, address(this), requiredTokenIn);
    bPool.mock_call__pullUnderlying(secondToken, address(this), requiredSecondTokenIn);
    bPool.expectCall__pullUnderlying(secondToken, address(this), requiredSecondTokenIn);
    // it mints the pool shares
    bPool.expectCall__mintPoolShare(poolAmountOut);
    // it sends pool shares to caller
    bPool.expectCall__pushPoolShare(address(this), poolAmountOut);
    uint256[] memory maxAmounts = new uint256[](2);
    maxAmounts[0] = requiredTokenIn;
    maxAmounts[1] = requiredSecondTokenIn;

    // it emits LOG_CALL event
    bytes memory _data = abi.encodeWithSelector(IBPool.joinPool.selector, poolAmountOut, maxAmounts);
    vm.expectEmit();
    emit IBPool.LOG_CALL(IBPool.joinPool.selector, address(this), _data);
    // it emits LOG_JOIN event for every token
    vm.expectEmit();
    emit IBPool.LOG_JOIN(address(this), token, requiredTokenIn);
    vm.expectEmit();
    emit IBPool.LOG_JOIN(address(this), secondToken, requiredSecondTokenIn);
    bPool.joinPool(poolAmountOut, maxAmounts);
    // it clears the reentrancy lock
    assertEq(_MUTEX_FREE, bPool.call__getLock());
  }
}
