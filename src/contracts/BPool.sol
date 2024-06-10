// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import {BMath} from './BMath.sol';
import {BToken} from './BToken.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IBPool} from 'interfaces/IBPool.sol';

/**
 * @title BPool
 * @notice Pool contract that holds tokens, allows to swap, add and remove liquidity.
 */
contract BPool is BToken, BMath, IBPool {
  /// @dev True if a call to the contract is in progress, False otherwise
  bool internal _mutex;
  /// @dev BFactory address to push token exitFee to
  address internal _factory;
  /// @dev Has CONTROL role
  address internal _controller;
  /// @dev Fee for swapping
  uint256 internal _swapFee;
  /// @dev Status of the pool. True if finalized, False otherwise
  bool internal _finalized;
  /// @dev Array of bound tokens
  address[] internal _tokens;
  /// @dev Metadata for each bound token
  mapping(address => Record) internal _records;
  /// @dev Sum of all token weights
  uint256 internal _totalWeight;

  /// @dev Logs the call data
  modifier _logs_() {
    emit LOG_CALL(msg.sig, msg.sender, msg.data);
    _;
  }

  /// @dev Prevents reentrancy in non-view functions
  modifier _lock_() {
    if (_mutex) {
      revert BPool_Reentrancy();
    }
    _mutex = true;
    _;
    _mutex = false;
  }

  /// @dev Prevents reentrancy in view functions
  modifier _viewlock_() {
    if (_mutex) {
      revert BPool_Reentrancy();
    }
    _;
  }

  constructor() {
    _controller = msg.sender;
    _factory = msg.sender;
    _swapFee = MIN_FEE;
    _finalized = false;
  }

  /// @inheritdoc IBPool
  function setSwapFee(uint256 swapFee) external _logs_ _lock_ {
    if (_finalized) {
      revert BPool_PoolIsFinalized();
    }
    if (msg.sender != _controller) {
      revert BPool_CallerIsNotController();
    }
    if (swapFee < MIN_FEE) {
      revert BPool_FeeBelowMinimum();
    }
    if (swapFee > MAX_FEE) {
      revert BPool_FeeAboveMaximum();
    }
    _swapFee = swapFee;
  }

  /// @inheritdoc IBPool
  function setController(address manager) external _logs_ _lock_ {
    if (msg.sender != _controller) {
      revert BPool_CallerIsNotController();
    }
    _controller = manager;
  }

  /// @inheritdoc IBPool
  function finalize() public virtual _logs_ _lock_ {
    if (msg.sender != _controller) {
      revert BPool_CallerIsNotController();
    }
    if (_finalized) {
      revert BPool_PoolIsFinalized();
    }
    if (_tokens.length < MIN_BOUND_TOKENS) {
      revert BPool_TokensBelowMinimum();
    }

    _finalized = true;

    _mintPoolShare(INIT_POOL_SUPPLY);
    _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
  }

  /// @inheritdoc IBPool
  function bind(address token, uint256 balance, uint256 denorm) external _logs_ _lock_ {
    if (msg.sender != _controller) {
      revert BPool_CallerIsNotController();
    }
    if (_records[token].bound) {
      revert BPool_TokenAlreadyBound();
    }
    if (_finalized) {
      revert BPool_PoolIsFinalized();
    }

    if (_tokens.length >= MAX_BOUND_TOKENS) {
      revert BPool_TokensAboveMaximum();
    }

    if (denorm < MIN_WEIGHT) {
      revert BPool_WeightBelowMinimum();
    }
    if (denorm > MAX_WEIGHT) {
      revert BPool_WeightAboveMaximum();
    }
    if (balance < MIN_BALANCE) {
      revert BPool_BalanceBelowMinimum();
    }

    _totalWeight = badd(_totalWeight, denorm);
    if (_totalWeight > MAX_TOTAL_WEIGHT) {
      revert BPool_TotalWeightAboveMaximum();
    }

    _records[token] = Record({bound: true, index: _tokens.length, denorm: denorm});
    _tokens.push(token);

    _pullUnderlying(token, msg.sender, balance);
  }

  /// @inheritdoc IBPool
  function unbind(address token) external _logs_ _lock_ {
    if (msg.sender != _controller) {
      revert BPool_CallerIsNotController();
    }
    if (!_records[token].bound) {
      revert BPool_TokenNotBound();
    }
    if (_finalized) {
      revert BPool_PoolIsFinalized();
    }

    _totalWeight = bsub(_totalWeight, _records[token].denorm);

    // Swap the token-to-unbind with the last token,
    // then delete the last token
    uint256 index = _records[token].index;
    uint256 last = _tokens.length - 1;
    _tokens[index] = _tokens[last];
    _records[_tokens[index]].index = index;
    _tokens.pop();
    _records[token] = Record({bound: false, index: 0, denorm: 0});

    _pushUnderlying(token, msg.sender, IERC20(token).balanceOf(address(this)));
  }

  /// @inheritdoc IBPool
  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external _logs_ _lock_ {
    if (!_finalized) {
      revert BPool_PoolNotFinalized();
    }

    uint256 poolTotal = totalSupply();
    uint256 ratio = bdiv(poolAmountOut, poolTotal);
    if (ratio == 0) {
      revert BPool_InvalidPoolRatio();
    }

    for (uint256 i = 0; i < _tokens.length; i++) {
      address t = _tokens[i];
      uint256 bal = IERC20(t).balanceOf(address(this));
      uint256 tokenAmountIn = bmul(ratio, bal);
      if (tokenAmountIn == 0) {
        revert BPool_InvalidTokenAmountIn();
      }
      if (tokenAmountIn > maxAmountsIn[i]) {
        revert BPool_TokenAmountInAboveMaxAmountIn();
      }
      emit LOG_JOIN(msg.sender, t, tokenAmountIn);
      _pullUnderlying(t, msg.sender, tokenAmountIn);
    }
    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
  }

  /// @inheritdoc IBPool
  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external _logs_ _lock_ {
    if (!_finalized) {
      revert BPool_PoolNotFinalized();
    }

    uint256 poolTotal = totalSupply();
    uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
    uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
    uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);
    if (ratio == 0) {
      revert BPool_InvalidPoolRatio();
    }

    _pullPoolShare(msg.sender, poolAmountIn);
    _pushPoolShare(_factory, exitFee);
    _burnPoolShare(pAiAfterExitFee);

    for (uint256 i = 0; i < _tokens.length; i++) {
      address t = _tokens[i];
      uint256 bal = IERC20(t).balanceOf(address(this));
      uint256 tokenAmountOut = bmul(ratio, bal);
      if (tokenAmountOut == 0) {
        revert BPool_InvalidTokenAmountOut();
      }
      if (tokenAmountOut < minAmountsOut[i]) {
        revert BPool_TokenAmountOutBelowMinAmountOut();
      }
      emit LOG_EXIT(msg.sender, t, tokenAmountOut);
      _pushUnderlying(t, msg.sender, tokenAmountOut);
    }
  }

  /// @inheritdoc IBPool
  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external _logs_ _lock_ returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
    if (!_records[tokenIn].bound) {
      revert BPool_TokenNotBound();
    }
    if (!_records[tokenOut].bound) {
      revert BPool_TokenNotBound();
    }
    if (!_finalized) {
      revert BPool_PoolNotFinalized();
    }

    Record storage inRecord = _records[address(tokenIn)];
    Record storage outRecord = _records[address(tokenOut)];

    uint256 tokenInBalance = IERC20(tokenIn).balanceOf(address(this));
    uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));

    if (tokenAmountIn > bmul(tokenInBalance, MAX_IN_RATIO)) {
      revert BPool_TokenAmountInAboveMaxIn();
    }

    uint256 spotPriceBefore =
      calcSpotPrice(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, _swapFee);
    if (spotPriceBefore > maxPrice) {
      revert BPool_SpotPriceAboveMaxPrice();
    }

    tokenAmountOut =
      calcOutGivenIn(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, tokenAmountIn, _swapFee);
    if (tokenAmountOut < minAmountOut) {
      revert BPool_TokenAmountOutBelowMinOut();
    }

    tokenInBalance = badd(tokenInBalance, tokenAmountIn);
    tokenOutBalance = bsub(tokenOutBalance, tokenAmountOut);

    spotPriceAfter = calcSpotPrice(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, _swapFee);
    if (spotPriceAfter < spotPriceBefore) {
      revert BPool_SpotPriceAfterBelowSpotPriceBefore();
    }
    if (spotPriceAfter > maxPrice) {
      revert BPool_SpotPriceAfterBelowMaxPrice();
    }
    if (spotPriceBefore > bdiv(tokenAmountIn, tokenAmountOut)) {
      revert BPool_SpotPriceBeforeAboveTokenRatio();
    }

    emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return (tokenAmountOut, spotPriceAfter);
  }

  /// @inheritdoc IBPool
  function swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice
  ) external _logs_ _lock_ returns (uint256 tokenAmountIn, uint256 spotPriceAfter) {
    if (!_records[tokenIn].bound) {
      revert BPool_TokenNotBound();
    }
    if (!_records[tokenOut].bound) {
      revert BPool_TokenNotBound();
    }
    if (!_finalized) {
      revert BPool_PoolNotFinalized();
    }

    Record storage inRecord = _records[address(tokenIn)];
    Record storage outRecord = _records[address(tokenOut)];

    uint256 tokenInBalance = IERC20(tokenIn).balanceOf(address(this));
    uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));

    if (tokenAmountOut > bmul(tokenOutBalance, MAX_OUT_RATIO)) {
      revert BPool_TokenAmountOutAboveMaxOut();
    }

    uint256 spotPriceBefore =
      calcSpotPrice(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, _swapFee);
    if (spotPriceBefore > maxPrice) {
      revert BPool_SpotPriceAboveMaxPrice();
    }

    tokenAmountIn =
      calcInGivenOut(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, tokenAmountOut, _swapFee);
    if (tokenAmountIn > maxAmountIn) {
      revert BPool_TokenAmountInAboveMaxAmountIn();
    }

    tokenInBalance = badd(tokenInBalance, tokenAmountIn);
    tokenOutBalance = bsub(tokenOutBalance, tokenAmountOut);

    spotPriceAfter = calcSpotPrice(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, _swapFee);
    if (spotPriceAfter < spotPriceBefore) {
      revert BPool_SpotPriceAfterBelowSpotPriceBefore();
    }
    if (spotPriceAfter > maxPrice) {
      revert BPool_SpotPriceAfterBelowMaxPrice();
    }
    if (spotPriceBefore > bdiv(tokenAmountIn, tokenAmountOut)) {
      revert BPool_SpotPriceBeforeAboveTokenRatio();
    }

    emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return (tokenAmountIn, spotPriceAfter);
  }

  /// @inheritdoc IBPool
  function joinswapExternAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    uint256 minPoolAmountOut
  ) external _logs_ _lock_ returns (uint256 poolAmountOut) {
    if (!_finalized) {
      revert BPool_PoolNotFinalized();
    }
    if (!_records[tokenIn].bound) {
      revert BPool_TokenNotBound();
    }

    Record storage inRecord = _records[tokenIn];
    uint256 tokenInBalance = IERC20(tokenIn).balanceOf(address(this));
    if (tokenAmountIn > bmul(tokenInBalance, MAX_IN_RATIO)) {
      revert BPool_TokenAmountInAboveMaxIn();
    }

    poolAmountOut =
      calcPoolOutGivenSingleIn(tokenInBalance, inRecord.denorm, totalSupply(), _totalWeight, tokenAmountIn, _swapFee);
    if (poolAmountOut < minPoolAmountOut) {
      revert BPool_PoolAmountOutBelowMinPoolAmountOut();
    }

    emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

    return poolAmountOut;
  }

  /// @inheritdoc IBPool
  function joinswapPoolAmountOut(
    address tokenIn,
    uint256 poolAmountOut,
    uint256 maxAmountIn
  ) external _logs_ _lock_ returns (uint256 tokenAmountIn) {
    if (!_finalized) {
      revert BPool_PoolNotFinalized();
    }
    if (!_records[tokenIn].bound) {
      revert BPool_TokenNotBound();
    }

    Record storage inRecord = _records[tokenIn];
    uint256 tokenInBalance = IERC20(tokenIn).balanceOf(address(this));

    tokenAmountIn =
      calcSingleInGivenPoolOut(tokenInBalance, inRecord.denorm, totalSupply(), _totalWeight, poolAmountOut, _swapFee);

    if (tokenAmountIn == 0) {
      revert BPool_InvalidTokenAmountIn();
    }
    if (tokenAmountIn > maxAmountIn) {
      revert BPool_TokenAmountInAboveMaxAmountIn();
    }
    if (tokenAmountIn > bmul(tokenInBalance, MAX_IN_RATIO)) {
      revert BPool_TokenAmountInAboveMaxIn();
    }

    emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

    return tokenAmountIn;
  }

  /// @inheritdoc IBPool
  function exitswapPoolAmountIn(
    address tokenOut,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) external _logs_ _lock_ returns (uint256 tokenAmountOut) {
    if (!_finalized) {
      revert BPool_PoolNotFinalized();
    }
    if (!_records[tokenOut].bound) {
      revert BPool_TokenNotBound();
    }

    Record storage outRecord = _records[tokenOut];
    uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));

    tokenAmountOut =
      calcSingleOutGivenPoolIn(tokenOutBalance, outRecord.denorm, totalSupply(), _totalWeight, poolAmountIn, _swapFee);

    if (tokenAmountOut < minAmountOut) {
      revert BPool_TokenAmountOutBelowMinAmountOut();
    }
    if (tokenAmountOut > bmul(tokenOutBalance, MAX_OUT_RATIO)) {
      revert BPool_TokenAmountOutAboveMaxOut();
    }

    uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);

    emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

    _pullPoolShare(msg.sender, poolAmountIn);
    _burnPoolShare(bsub(poolAmountIn, exitFee));
    _pushPoolShare(_factory, exitFee);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return tokenAmountOut;
  }

  /// @inheritdoc IBPool
  function exitswapExternAmountOut(
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPoolAmountIn
  ) external _logs_ _lock_ returns (uint256 poolAmountIn) {
    if (!_finalized) {
      revert BPool_PoolNotFinalized();
    }
    if (!_records[tokenOut].bound) {
      revert BPool_TokenNotBound();
    }

    Record storage outRecord = _records[tokenOut];
    uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));
    if (tokenAmountOut > bmul(tokenOutBalance, MAX_OUT_RATIO)) {
      revert BPool_TokenAmountOutAboveMaxOut();
    }

    poolAmountIn =
      calcPoolInGivenSingleOut(tokenOutBalance, outRecord.denorm, totalSupply(), _totalWeight, tokenAmountOut, _swapFee);
    if (poolAmountIn == 0) {
      revert BPool_InvalidPoolAmountIn();
    }
    if (poolAmountIn > maxPoolAmountIn) {
      revert BPool_PoolAmountInAboveMaxPoolAmountIn();
    }

    uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);

    emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

    _pullPoolShare(msg.sender, poolAmountIn);
    _burnPoolShare(bsub(poolAmountIn, exitFee));
    _pushPoolShare(_factory, exitFee);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return poolAmountIn;
  }

  /// @inheritdoc IBPool
  function getSpotPrice(address tokenIn, address tokenOut) external view _viewlock_ returns (uint256 spotPrice) {
    if (!_records[tokenIn].bound) {
      revert BPool_TokenNotBound();
    }
    if (!_records[tokenOut].bound) {
      revert BPool_TokenNotBound();
    }
    Record storage inRecord = _records[tokenIn];
    Record storage outRecord = _records[tokenOut];
    return calcSpotPrice(
      IERC20(tokenIn).balanceOf(address(this)),
      inRecord.denorm,
      IERC20(tokenOut).balanceOf(address(this)),
      outRecord.denorm,
      _swapFee
    );
  }

  /// @inheritdoc IBPool
  function getSpotPriceSansFee(address tokenIn, address tokenOut) external view _viewlock_ returns (uint256 spotPrice) {
    if (!_records[tokenIn].bound) {
      revert BPool_TokenNotBound();
    }
    if (!_records[tokenOut].bound) {
      revert BPool_TokenNotBound();
    }
    Record storage inRecord = _records[tokenIn];
    Record storage outRecord = _records[tokenOut];
    return calcSpotPrice(
      IERC20(tokenIn).balanceOf(address(this)),
      inRecord.denorm,
      IERC20(tokenOut).balanceOf(address(this)),
      outRecord.denorm,
      0
    );
  }

  /// @inheritdoc IBPool
  function isFinalized() external view returns (bool) {
    return _finalized;
  }

  /// @inheritdoc IBPool
  function isBound(address t) external view returns (bool) {
    return _records[t].bound;
  }

  /// @inheritdoc IBPool
  function getNumTokens() external view returns (uint256) {
    return _tokens.length;
  }

  /// @inheritdoc IBPool
  function getCurrentTokens() external view _viewlock_ returns (address[] memory tokens) {
    return _tokens;
  }

  /// @inheritdoc IBPool
  function getFinalTokens() external view _viewlock_ returns (address[] memory tokens) {
    if (!_finalized) {
      revert BPool_PoolNotFinalized();
    }
    return _tokens;
  }

  /// @inheritdoc IBPool
  function getDenormalizedWeight(address token) external view _viewlock_ returns (uint256) {
    if (!_records[token].bound) {
      revert BPool_TokenNotBound();
    }
    return _records[token].denorm;
  }

  /// @inheritdoc IBPool
  function getTotalDenormalizedWeight() external view _viewlock_ returns (uint256) {
    return _totalWeight;
  }

  /// @inheritdoc IBPool
  function getNormalizedWeight(address token) external view _viewlock_ returns (uint256) {
    if (!_records[token].bound) {
      revert BPool_TokenNotBound();
    }
    uint256 denorm = _records[token].denorm;
    return bdiv(denorm, _totalWeight);
  }

  /// @inheritdoc IBPool
  function getBalance(address token) external view _viewlock_ returns (uint256) {
    if (!_records[token].bound) {
      revert BPool_TokenNotBound();
    }
    return IERC20(token).balanceOf(address(this));
  }

  /// @inheritdoc IBPool
  function getSwapFee() external view _viewlock_ returns (uint256) {
    return _swapFee;
  }

  /// @inheritdoc IBPool
  function getController() external view _viewlock_ returns (address) {
    return _controller;
  }

  /**
   * @dev Pulls tokens from the sender. Tokens needs to be approved first. Calls are not locked.
   * @param erc20 address of the token to pull
   * @param from address to pull the tokens from
   * @param amount amount of tokens to pull
   */
  function _pullUnderlying(address erc20, address from, uint256 amount) internal virtual {
    bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
    if (!xfer) {
      revert BPool_ERC20TransferFailed();
    }
  }

  /**
   * @dev Pushes tokens to the receiver. Calls are not locked.
   * @param erc20 address of the token to push
   * @param to address to push the tokens to
   * @param amount amount of tokens to push
   */
  function _pushUnderlying(address erc20, address to, uint256 amount) internal virtual {
    bool xfer = IERC20(erc20).transfer(to, amount);
    if (!xfer) {
      revert BPool_ERC20TransferFailed();
    }
  }

  /**
   * @dev Pulls pool tokens from the sender.
   * @param from address to pull the pool tokens from
   * @param amount amount of pool tokens to pull
   */
  function _pullPoolShare(address from, uint256 amount) internal {
    _pull(from, amount);
  }

  /**
   * @dev Pushes pool tokens to the receiver.
   * @param to address to push the pool tokens to
   * @param amount amount of pool tokens to push
   */
  function _pushPoolShare(address to, uint256 amount) internal {
    _push(to, amount);
  }

  /**
   * @dev Mints an amount of pool tokens.
   * @param amount amount of pool tokens to mint
   */
  function _mintPoolShare(uint256 amount) internal {
    _mint(address(this), amount);
  }

  /**
   * @dev Burns an amount of pool tokens.
   * @param amount amount of pool tokens to burn
   */
  function _burnPoolShare(uint256 amount) internal {
    _burn(address(this), amount);
  }
}
