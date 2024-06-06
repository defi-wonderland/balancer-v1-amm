// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import {BMath} from './BMath.sol';
import {BToken, IERC20} from './BToken.sol';

contract BPool is BToken, BMath {
  struct Record {
    bool bound; // is token bound to pool
    uint256 index; // internal
    uint256 denorm; // denormalized weight
  }

  bool internal _mutex;

  address internal _factory; // BFactory address to push token exitFee to
  address internal _controller; // has CONTROL role
  bool internal _publicSwap; // true if PUBLIC can call SWAP functions

  // `setSwapFee` and `finalize` require CONTROL
  // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
  uint256 internal _swapFee;
  bool internal _finalized;

  address[] internal _tokens;
  mapping(address => Record) internal _records;
  uint256 internal _totalWeight;

  event LOG_SWAP(
    address indexed caller,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 tokenAmountIn,
    uint256 tokenAmountOut
  );

  event LOG_JOIN(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);

  event LOG_EXIT(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);

  event LOG_CALL(bytes4 indexed sig, address indexed caller, bytes data) anonymous;

  error ERR_IS_FINALIZED();
  error ERR_NOT_CONTROLLER();
  error ERR_MIN_FEE();
  error ERR_MAX_FEE();
  error ERR_IS_BOUND();
  error ERR_NOT_BOUND();
  error ERR_MIN_TOKENS();
  error ERR_MAX_TOKENS();
  error ERR_MIN_WEIGHT();
  error ERR_MAX_WEIGHT();
  error ERR_MIN_BALANCE();
  error ERR_MAX_TOTAL_WEIGHT();
  error ERR_NOT_FINALIZED();
  error ERR_SWAP_NOT_PUBLIC();
  error ERR_MAX_IN_RATIO();
  error ERR_BAD_LIMIT_PRICE();
  error ERR_LIMIT_OUT();
  error ERR_LIMIT_IN();
  error ERR_LIMIT_PRICE();
  error ERR_MATH_APPROX();
  error ERR_REENTRY();
  error ERR_ERC20_FALSE();
  error ERR_MAX_OUT_RATIO();

  constructor() {
    _controller = msg.sender;
    _factory = msg.sender;
    _swapFee = MIN_FEE;
    _publicSwap = false;
    _finalized = false;
  }

  function setSwapFee(uint256 swapFee) external _logs_ _lock_ {
    if(_finalized) revert ERR_IS_FINALIZED();
    if(!(msg.sender == _controller)) revert ERR_NOT_CONTROLLER();
    if(!(swapFee >= MIN_FEE)) revert ERR_MIN_FEE();
    if(!(swapFee <= MAX_FEE)) revert ERR_MAX_FEE();
    _swapFee = swapFee;
  }

  function setController(address manager) external _logs_ _lock_ {
    if(!(msg.sender == _controller)) revert ERR_NOT_CONTROLLER();
    _controller = manager;
  }

  function setPublicSwap(bool public_) external _logs_ _lock_ {
    if(_finalized) revert ERR_IS_FINALIZED();
    if(!(msg.sender == _controller)) revert ERR_NOT_CONTROLLER();
    _publicSwap = public_;
  }

  function finalize() external _logs_ _lock_ {
    if(!(msg.sender == _controller)) revert ERR_NOT_CONTROLLER();
    if(_finalized) revert ERR_IS_FINALIZED();
    if(!(_tokens.length >= MIN_BOUND_TOKENS)) revert ERR_MIN_TOKENS();

    _finalized = true;
    _publicSwap = true;

    _mintPoolShare(INIT_POOL_SUPPLY);
    _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
  }

  function bind(address token, uint256 balance, uint256 denorm) external _logs_ 
  // _lock_  Bind does not lock because it jumps to `rebind`, which does
  {
    if(!(msg.sender == _controller)) revert ERR_NOT_CONTROLLER();
    if(_records[token].bound) revert ERR_IS_BOUND();
    if(_finalized) revert ERR_IS_FINALIZED();

    if(!(_tokens.length < MAX_BOUND_TOKENS)) revert ERR_MAX_TOKENS();

    _records[token] = Record({
      bound: true,
      index: _tokens.length,
      denorm: 0 // denorm will be validated
    });
    _tokens.push(token);
    rebind(token, balance, denorm);
  }

  function rebind(address token, uint256 balance, uint256 denorm) public _logs_ _lock_ {
    if(!(msg.sender == _controller)) revert ERR_NOT_CONTROLLER();
    if(!_records[token].bound) revert ERR_NOT_BOUND();
    if(_finalized) revert ERR_IS_FINALIZED();

    if(!(denorm >= MIN_WEIGHT)) revert ERR_MIN_WEIGHT();
    if(!(denorm <= MAX_WEIGHT)) revert ERR_MAX_WEIGHT();
    if(!(balance >= MIN_BALANCE)) revert ERR_MIN_BALANCE();

    // Adjust the denorm and totalWeight
    uint256 oldWeight = _records[token].denorm;
    if (denorm > oldWeight) {
      _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
      if(!(_totalWeight <= MAX_TOTAL_WEIGHT)) revert ERR_MAX_TOTAL_WEIGHT();
    } else if (denorm < oldWeight) {
      _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
    }
    _records[token].denorm = denorm;

    // Adjust the balance record and actual token balance
    uint256 oldBalance = IERC20(token).balanceOf(address(this));
    if (balance > oldBalance) {
      _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
    } else if (balance < oldBalance) {
      _pushUnderlying(token, msg.sender, bsub(oldBalance, balance));
    }
  }

  // solhint-disable-next-line ordering
  function unbind(address token) external _logs_ _lock_ {
    if(!(msg.sender == _controller)) revert ERR_NOT_CONTROLLER();
    if(!_records[token].bound) revert ERR_NOT_BOUND();
    if(_finalized) revert ERR_IS_FINALIZED();

    uint256 tokenBalance = IERC20(token).balanceOf(address(this));

    _totalWeight = bsub(_totalWeight, _records[token].denorm);

    // Swap the token-to-unbind with the last token,
    // then delete the last token
    uint256 index = _records[token].index;
    uint256 last = _tokens.length - 1;
    _tokens[index] = _tokens[last];
    _records[_tokens[index]].index = index;
    _tokens.pop();
    _records[token] = Record({bound: false, index: 0, denorm: 0});

    _pushUnderlying(token, msg.sender, tokenBalance);
  }

  function getSpotPrice(address tokenIn, address tokenOut) external view _viewlock_ returns (uint256 spotPrice) {
    if(!_records[tokenIn].bound) revert ERR_NOT_BOUND();
    if(!_records[tokenOut].bound) revert ERR_NOT_BOUND();
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

  function getSpotPriceSansFee(address tokenIn, address tokenOut) external view _viewlock_ returns (uint256 spotPrice) {
    if(!_records[tokenIn].bound) revert ERR_NOT_BOUND();
    if(!_records[tokenOut].bound) revert ERR_NOT_BOUND();
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

  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external _logs_ _lock_ {
    if(!_finalized) revert ERR_NOT_FINALIZED();

    uint256 poolTotal = totalSupply();
    uint256 ratio = bdiv(poolAmountOut, poolTotal);
    if(!(ratio != 0)) revert ERR_MATH_APPROX();

    for (uint256 i = 0; i < _tokens.length; i++) {
      address t = _tokens[i];
      uint256 bal = IERC20(t).balanceOf(address(this));
      uint256 tokenAmountIn = bmul(ratio, bal);
      if(!(tokenAmountIn != 0)) revert ERR_MATH_APPROX();
      if(!(tokenAmountIn <= maxAmountsIn[i])) revert ERR_LIMIT_IN();
      emit LOG_JOIN(msg.sender, t, tokenAmountIn);
      _pullUnderlying(t, msg.sender, tokenAmountIn);
    }
    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
  }

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external _logs_ _lock_ {
    if(!_finalized) revert ERR_NOT_FINALIZED();

    uint256 poolTotal = totalSupply();
    uint256 ratio = bdiv(poolAmountIn, poolTotal);
    if(!(ratio != 0)) revert ERR_MATH_APPROX();

    _pullPoolShare(msg.sender, poolAmountIn);
    _burnPoolShare(poolAmountIn);

    for (uint256 i = 0; i < _tokens.length; i++) {
      address t = _tokens[i];
      uint256 bal = IERC20(t).balanceOf(address(this));
      uint256 tokenAmountOut = bmul(ratio, bal);
      if(!(tokenAmountOut != 0)) revert ERR_MATH_APPROX();
      if(!(tokenAmountOut >= minAmountsOut[i])) revert ERR_LIMIT_OUT();
      emit LOG_EXIT(msg.sender, t, tokenAmountOut);
      _pushUnderlying(t, msg.sender, tokenAmountOut);
    }
  }

  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external _logs_ _lock_ returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
    if(!_records[tokenIn].bound) revert ERR_NOT_BOUND();
    if(!_records[tokenOut].bound) revert ERR_NOT_BOUND();
    if(!_publicSwap) revert ERR_SWAP_NOT_PUBLIC();

    Record storage inRecord = _records[address(tokenIn)];
    Record storage outRecord = _records[address(tokenOut)];

    uint256 tokenInBalance = IERC20(tokenIn).balanceOf(address(this));
    uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));

    if(!(tokenAmountIn <= bmul(tokenInBalance, MAX_IN_RATIO))) revert ERR_MAX_IN_RATIO();

    uint256 spotPriceBefore =
      calcSpotPrice(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, _swapFee);
    if(!(spotPriceBefore <= maxPrice)) revert ERR_BAD_LIMIT_PRICE();

    tokenAmountOut =
      calcOutGivenIn(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, tokenAmountIn, _swapFee);
    if(!(tokenAmountOut >= minAmountOut)) revert ERR_LIMIT_OUT();

    tokenInBalance = badd(tokenInBalance, tokenAmountIn);
    tokenOutBalance = bsub(tokenOutBalance, tokenAmountOut);

    spotPriceAfter = calcSpotPrice(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, _swapFee);
    if(!(spotPriceAfter >= spotPriceBefore)) revert ERR_MATH_APPROX();
    if(!(spotPriceAfter <= maxPrice)) revert ERR_LIMIT_PRICE();
    if(!(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut))) revert ERR_MATH_APPROX();

    emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return (tokenAmountOut, spotPriceAfter);
  }

  function swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice
  ) external _logs_ _lock_ returns (uint256 tokenAmountIn, uint256 spotPriceAfter) {
    if(!_records[tokenIn].bound) revert ERR_NOT_BOUND();
    if(!_records[tokenOut].bound) revert ERR_NOT_BOUND();
    if(!_publicSwap) revert ERR_SWAP_NOT_PUBLIC();

    Record storage inRecord = _records[address(tokenIn)];
    Record storage outRecord = _records[address(tokenOut)];

    uint256 tokenInBalance = IERC20(tokenIn).balanceOf(address(this));
    uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));

    if(!(tokenAmountOut <= bmul(tokenOutBalance, MAX_OUT_RATIO))) revert ERR_MAX_OUT_RATIO();

    uint256 spotPriceBefore =
      calcSpotPrice(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, _swapFee);
    if(!(spotPriceBefore <= maxPrice)) revert ERR_BAD_LIMIT_PRICE();

    tokenAmountIn =
      calcInGivenOut(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, tokenAmountOut, _swapFee);
    if(!(tokenAmountIn <= maxAmountIn)) revert ERR_LIMIT_IN();

    tokenInBalance = badd(tokenInBalance, tokenAmountIn);
    tokenOutBalance = bsub(tokenOutBalance, tokenAmountOut);

    spotPriceAfter = calcSpotPrice(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, _swapFee);
    if(!(spotPriceAfter >= spotPriceBefore)) revert ERR_MATH_APPROX();
    if(!(spotPriceAfter <= maxPrice)) revert ERR_LIMIT_PRICE();
    if(!(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut))) revert ERR_MATH_APPROX();

    emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return (tokenAmountIn, spotPriceAfter);
  }

  function joinswapExternAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    uint256 minPoolAmountOut
  ) external _logs_ _lock_ returns (uint256 poolAmountOut) {
    if(!_finalized) revert ERR_NOT_FINALIZED();
    if(!_records[tokenIn].bound) revert ERR_NOT_BOUND();

    Record storage inRecord = _records[tokenIn];
    uint256 tokenInBalance = IERC20(tokenIn).balanceOf(address(this));

    poolAmountOut =
      calcPoolOutGivenSingleIn(tokenInBalance, inRecord.denorm, _totalSupply, _totalWeight, tokenAmountIn, _swapFee);

    if(!(poolAmountOut >= minPoolAmountOut)) revert ERR_LIMIT_OUT();
    if(!(tokenAmountIn <= bmul(tokenInBalance, MAX_IN_RATIO))) revert ERR_MAX_IN_RATIO();

    emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

    return poolAmountOut;
  }

  function joinswapPoolAmountOut(
    address tokenIn,
    uint256 poolAmountOut,
    uint256 maxAmountIn
  ) external _logs_ _lock_ returns (uint256 tokenAmountIn) {
    if(!_finalized) revert ERR_NOT_FINALIZED();
    if(!_records[tokenIn].bound) revert ERR_NOT_BOUND();

    Record storage inRecord = _records[tokenIn];
    uint256 tokenInBalance = IERC20(tokenIn).balanceOf(address(this));

    tokenAmountIn =
      calcSingleInGivenPoolOut(tokenInBalance, inRecord.denorm, _totalSupply, _totalWeight, poolAmountOut, _swapFee);

    if(!(tokenAmountIn != 0)) revert ERR_MATH_APPROX();
    if(!(tokenAmountIn <= maxAmountIn)) revert ERR_LIMIT_IN();
    if(!(tokenAmountIn <= bmul(tokenInBalance, MAX_IN_RATIO))) revert ERR_MAX_IN_RATIO();

    emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
    _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

    return tokenAmountIn;
  }

  function exitswapPoolAmountIn(
    address tokenOut,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) external _logs_ _lock_ returns (uint256 tokenAmountOut) {
    if(!_finalized) revert ERR_NOT_FINALIZED();
    if(!_records[tokenOut].bound) revert ERR_NOT_BOUND();

    Record storage outRecord = _records[tokenOut];
    uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));

    tokenAmountOut =
      calcSingleOutGivenPoolIn(tokenOutBalance, outRecord.denorm, _totalSupply, _totalWeight, poolAmountIn, _swapFee);

    if(!(tokenAmountOut >= minAmountOut)) revert ERR_LIMIT_OUT();
    if(!(tokenAmountOut <= bmul(tokenOutBalance, MAX_OUT_RATIO))) revert ERR_MAX_OUT_RATIO();

    emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

    _pullPoolShare(msg.sender, poolAmountIn);
    _burnPoolShare(poolAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return tokenAmountOut;
  }

  function exitswapExternAmountOut(
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPoolAmountIn
  ) external _logs_ _lock_ returns (uint256 poolAmountIn) {
    if(!_finalized) revert ERR_NOT_FINALIZED();
    if(!_records[tokenOut].bound) revert ERR_NOT_BOUND();

    Record storage outRecord = _records[tokenOut];
    uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));

    poolAmountIn =
      calcPoolInGivenSingleOut(tokenOutBalance, outRecord.denorm, _totalSupply, _totalWeight, tokenAmountOut, _swapFee);

    if(!(poolAmountIn != 0)) revert ERR_MATH_APPROX();
    if(!(poolAmountIn <= maxPoolAmountIn)) revert ERR_LIMIT_IN();
    if(!(tokenAmountOut <= bmul(tokenOutBalance, MAX_OUT_RATIO))) revert ERR_MAX_OUT_RATIO();

    emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

    _pullPoolShare(msg.sender, poolAmountIn);
    _burnPoolShare(poolAmountIn);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return poolAmountIn;
  }

  // ==
  // 'Underlying' token-manipulation functions make external calls but are NOT locked
  // You must `_lock_` or otherwise ensure reentry-safety

  function _pullUnderlying(address erc20, address from, uint256 amount) internal virtual {
    bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
    if(!xfer) revert ERR_ERC20_FALSE();
  }

  function _pushUnderlying(address erc20, address to, uint256 amount) internal virtual {
    bool xfer = IERC20(erc20).transfer(to, amount);
    if(!xfer) revert ERR_ERC20_FALSE();
  }

  function _pullPoolShare(address from, uint256 amount) internal {
    _pull(from, amount);
  }

  function _pushPoolShare(address to, uint256 amount) internal {
    _push(to, amount);
  }

  function _mintPoolShare(uint256 amount) internal {
    _mint(amount);
  }

  function _burnPoolShare(uint256 amount) internal {
    _burn(amount);
  }

  modifier _logs_() {
    emit LOG_CALL(msg.sig, msg.sender, msg.data);
    _;
  }

  modifier _lock_() {
    if(_mutex) revert ERR_REENTRY();
    _mutex = true;
    _;
    _mutex = false;
  }

  modifier _viewlock_() {
    if(_mutex) revert ERR_REENTRY();
    _;
  }
}
