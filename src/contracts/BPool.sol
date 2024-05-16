// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.23;

import './BMath.sol';
import './BToken.sol';

import {ConditionalOrdersUtilsLib as Utils} from '../cow-swap/ConditionalOrdersUtilsLib.sol';
import {GPv2Order} from '../cow-swap/GPv2Order.sol';
import {IConditionalOrder} from '../cow-swap/IConditionalOrder.sol';
import 'interfaces/IBFactory.sol';
import {IERC1271} from 'interfaces/IERC1271.sol';

contract BPool is IERC1271, BBronze, BToken, BMath {
  struct Record {
    bool bound; // is token bound to pool
    uint256 index; // internal
    uint256 denorm; // denormalized weight
  }

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

  modifier _logs_() {
    emit LOG_CALL(msg.sig, msg.sender, msg.data);
    _;
  }

  modifier _lock_() {
    require(!_mutex, 'ERR_REENTRY');
    _mutex = true;
    _;
    _mutex = false;
  }

  modifier _viewlock_() {
    require(!_mutex, 'ERR_REENTRY');
    _;
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

  constructor() {
    _controller = msg.sender;
    _factory = msg.sender;
    _swapFee = MIN_FEE;
    _publicSwap = false;
    _finalized = false;
  }

  function isPublicSwap() external view returns (bool) {
    return _publicSwap;
  }

  function isFinalized() external view returns (bool) {
    return _finalized;
  }

  function isBound(address t) external view returns (bool) {
    return _records[t].bound;
  }

  function getNumTokens() external view returns (uint256) {
    return _tokens.length;
  }

  function getCurrentTokens() external view _viewlock_ returns (address[] memory tokens) {
    return _tokens;
  }

  function getFinalTokens() external view _viewlock_ returns (address[] memory tokens) {
    require(_finalized, 'ERR_NOT_FINALIZED');
    return _tokens;
  }

  function getDenormalizedWeight(address token) external view _viewlock_ returns (uint256) {
    require(_records[token].bound, 'ERR_NOT_BOUND');
    return _records[token].denorm;
  }

  function getTotalDenormalizedWeight() external view _viewlock_ returns (uint256) {
    return _totalWeight;
  }

  function getNormalizedWeight(address token) external view _viewlock_ returns (uint256) {
    require(_records[token].bound, 'ERR_NOT_BOUND');
    uint256 denorm = _records[token].denorm;
    return bdiv(denorm, _totalWeight);
  }

  function getBalance(address token) external view _viewlock_ returns (uint256) {
    require(_records[token].bound, 'ERR_NOT_BOUND');
    return IERC20(token).balanceOf(address(this));
  }

  function getSwapFee() external view _viewlock_ returns (uint256) {
    return _swapFee;
  }

  function getController() external view _viewlock_ returns (address) {
    return _controller;
  }

  function setSwapFee(uint256 swapFee) external _logs_ _lock_ {
    require(!_finalized, 'ERR_IS_FINALIZED');
    require(msg.sender == _controller, 'ERR_NOT_CONTROLLER');
    require(swapFee >= MIN_FEE, 'ERR_MIN_FEE');
    require(swapFee <= MAX_FEE, 'ERR_MAX_FEE');
    _swapFee = swapFee;
  }

  function setController(address manager) external _logs_ _lock_ {
    require(msg.sender == _controller, 'ERR_NOT_CONTROLLER');
    _controller = manager;
  }

  function setPublicSwap(bool public_) external _logs_ _lock_ {
    require(!_finalized, 'ERR_IS_FINALIZED');
    require(msg.sender == _controller, 'ERR_NOT_CONTROLLER');
    _publicSwap = public_;
  }

  function finalize() external _logs_ _lock_ {
    require(msg.sender == _controller, 'ERR_NOT_CONTROLLER');
    require(!_finalized, 'ERR_IS_FINALIZED');
    require(_tokens.length >= MIN_BOUND_TOKENS, 'ERR_MIN_TOKENS');

    _finalized = true;
    _publicSwap = true;

    _mintPoolShare(INIT_POOL_SUPPLY);
    _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);

    _grantApprovalsTo(IBFactory(_factory).getCowSwap());
  }

  function bind(address token, uint256 balance, uint256 denorm) external _logs_ 
  // _lock_  Bind does not lock because it jumps to `rebind`, which does
  {
    require(msg.sender == _controller, 'ERR_NOT_CONTROLLER');
    require(!_records[token].bound, 'ERR_IS_BOUND');
    require(!_finalized, 'ERR_IS_FINALIZED');

    require(_tokens.length < MAX_BOUND_TOKENS, 'ERR_MAX_TOKENS');

    _records[token] = Record({
      bound: true,
      index: _tokens.length,
      denorm: 0 // denorm will be validated
    });
    _tokens.push(token);
    rebind(token, balance, denorm);
  }

  function rebind(address token, uint256 balance, uint256 denorm) public _logs_ _lock_ {
    require(msg.sender == _controller, 'ERR_NOT_CONTROLLER');
    require(_records[token].bound, 'ERR_NOT_BOUND');
    require(!_finalized, 'ERR_IS_FINALIZED');

    require(denorm >= MIN_WEIGHT, 'ERR_MIN_WEIGHT');
    require(denorm <= MAX_WEIGHT, 'ERR_MAX_WEIGHT');
    require(balance >= MIN_BALANCE, 'ERR_MIN_BALANCE');

    // Adjust the denorm and totalWeight
    uint256 oldWeight = _records[token].denorm;
    if (denorm > oldWeight) {
      _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
      require(_totalWeight <= MAX_TOTAL_WEIGHT, 'ERR_MAX_TOTAL_WEIGHT');
    } else if (denorm < oldWeight) {
      _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
    }
    _records[token].denorm = denorm;

    // Adjust the balance record and actual token balance
    uint256 oldBalance = IERC20(token).balanceOf(address(this));
    if (balance > oldBalance) {
      _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
    } else if (balance < oldBalance) {
      // In this case liquidity is being withdrawn, so charge EXIT_FEE
      uint256 tokenBalanceWithdrawn = bsub(oldBalance, balance);
      uint256 tokenExitFee = bmul(tokenBalanceWithdrawn, EXIT_FEE);
      _pushUnderlying(token, msg.sender, bsub(tokenBalanceWithdrawn, tokenExitFee));
      _pushUnderlying(token, _factory, tokenExitFee);
    }
  }

  function unbind(address token) external _logs_ _lock_ {
    require(msg.sender == _controller, 'ERR_NOT_CONTROLLER');
    require(_records[token].bound, 'ERR_NOT_BOUND');
    require(!_finalized, 'ERR_IS_FINALIZED');

    uint256 tokenBalance = IERC20(token).balanceOf(address(this));
    uint256 tokenExitFee = bmul(tokenBalance, EXIT_FEE);

    _totalWeight = bsub(_totalWeight, _records[token].denorm);

    // Swap the token-to-unbind with the last token,
    // then delete the last token
    uint256 index = _records[token].index;
    uint256 last = _tokens.length - 1;
    _tokens[index] = _tokens[last];
    _records[_tokens[index]].index = index;
    _tokens.pop();
    _records[token] = Record({bound: false, index: 0, denorm: 0});

    _pushUnderlying(token, msg.sender, bsub(tokenBalance, tokenExitFee));
    _pushUnderlying(token, _factory, tokenExitFee);
  }

  // NOTE: deprecated method, as balances are calculated on-the-fly
  // Absorb any tokens that have been sent to this contract into the pool
  function gulp(address token) external _logs_ _lock_ {
    require(_records[token].bound, 'ERR_NOT_BOUND');
    return;
  }

  function getSpotPrice(address tokenIn, address tokenOut) external view _viewlock_ returns (uint256 spotPrice) {
    require(_records[tokenIn].bound, 'ERR_NOT_BOUND');
    require(_records[tokenOut].bound, 'ERR_NOT_BOUND');
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
    require(_records[tokenIn].bound, 'ERR_NOT_BOUND');
    require(_records[tokenOut].bound, 'ERR_NOT_BOUND');
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
    require(_finalized, 'ERR_NOT_FINALIZED');

    uint256 poolTotal = totalSupply();
    uint256 ratio = bdiv(poolAmountOut, poolTotal);
    require(ratio != 0, 'ERR_MATH_APPROX');

    for (uint256 i = 0; i < _tokens.length; i++) {
      address t = _tokens[i];
      uint256 bal = IERC20(t).balanceOf(address(this));
      uint256 tokenAmountIn = bmul(ratio, bal);
      require(tokenAmountIn != 0, 'ERR_MATH_APPROX');
      require(tokenAmountIn <= maxAmountsIn[i], 'ERR_LIMIT_IN');
      emit LOG_JOIN(msg.sender, t, tokenAmountIn);
      _pullUnderlying(t, msg.sender, tokenAmountIn);
    }
    _mintPoolShare(poolAmountOut);
    _pushPoolShare(msg.sender, poolAmountOut);
  }

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external _logs_ _lock_ {
    require(_finalized, 'ERR_NOT_FINALIZED');

    uint256 poolTotal = totalSupply();
    uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);
    uint256 pAiAfterExitFee = bsub(poolAmountIn, exitFee);
    uint256 ratio = bdiv(pAiAfterExitFee, poolTotal);
    require(ratio != 0, 'ERR_MATH_APPROX');

    _pullPoolShare(msg.sender, poolAmountIn);
    _pushPoolShare(_factory, exitFee);
    _burnPoolShare(pAiAfterExitFee);

    for (uint256 i = 0; i < _tokens.length; i++) {
      address t = _tokens[i];
      uint256 bal = IERC20(t).balanceOf(address(this));
      uint256 tokenAmountOut = bmul(ratio, bal);
      require(tokenAmountOut != 0, 'ERR_MATH_APPROX');
      require(tokenAmountOut >= minAmountsOut[i], 'ERR_LIMIT_OUT');
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
    require(_records[tokenIn].bound, 'ERR_NOT_BOUND');
    require(_records[tokenOut].bound, 'ERR_NOT_BOUND');
    require(_publicSwap, 'ERR_SWAP_NOT_PUBLIC');

    Record storage inRecord = _records[address(tokenIn)];
    Record storage outRecord = _records[address(tokenOut)];

    uint256 tokenInBalance = IERC20(tokenIn).balanceOf(address(this));
    uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));

    require(tokenAmountIn <= bmul(tokenInBalance, MAX_IN_RATIO), 'ERR_MAX_IN_RATIO');

    uint256 spotPriceBefore =
      calcSpotPrice(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, _swapFee);
    require(spotPriceBefore <= maxPrice, 'ERR_BAD_LIMIT_PRICE');

    tokenAmountOut =
      calcOutGivenIn(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, tokenAmountIn, _swapFee);
    require(tokenAmountOut >= minAmountOut, 'ERR_LIMIT_OUT');

    tokenInBalance = badd(tokenInBalance, tokenAmountIn);
    tokenOutBalance = bsub(tokenOutBalance, tokenAmountOut);

    spotPriceAfter = calcSpotPrice(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, _swapFee);
    require(spotPriceAfter >= spotPriceBefore, 'ERR_MATH_APPROX');
    require(spotPriceAfter <= maxPrice, 'ERR_LIMIT_PRICE');
    require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), 'ERR_MATH_APPROX');

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
    require(_records[tokenIn].bound, 'ERR_NOT_BOUND');
    require(_records[tokenOut].bound, 'ERR_NOT_BOUND');
    require(_publicSwap, 'ERR_SWAP_NOT_PUBLIC');

    Record storage inRecord = _records[address(tokenIn)];
    Record storage outRecord = _records[address(tokenOut)];

    uint256 tokenInBalance = IERC20(tokenIn).balanceOf(address(this));
    uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));

    require(tokenAmountOut <= bmul(tokenOutBalance, MAX_OUT_RATIO), 'ERR_MAX_OUT_RATIO');

    uint256 spotPriceBefore =
      calcSpotPrice(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, _swapFee);
    require(spotPriceBefore <= maxPrice, 'ERR_BAD_LIMIT_PRICE');

    tokenAmountIn =
      calcInGivenOut(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, tokenAmountOut, _swapFee);
    require(tokenAmountIn <= maxAmountIn, 'ERR_LIMIT_IN');

    tokenInBalance = badd(tokenInBalance, tokenAmountIn);
    tokenOutBalance = bsub(tokenOutBalance, tokenAmountOut);

    spotPriceAfter = calcSpotPrice(tokenInBalance, inRecord.denorm, tokenOutBalance, outRecord.denorm, _swapFee);
    require(spotPriceAfter >= spotPriceBefore, 'ERR_MATH_APPROX');
    require(spotPriceAfter <= maxPrice, 'ERR_LIMIT_PRICE');
    require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), 'ERR_MATH_APPROX');

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
    require(_finalized, 'ERR_NOT_FINALIZED');
    require(_records[tokenIn].bound, 'ERR_NOT_BOUND');

    Record storage inRecord = _records[tokenIn];
    uint256 tokenInBalance = IERC20(tokenIn).balanceOf(address(this));

    poolAmountOut =
      calcPoolOutGivenSingleIn(tokenInBalance, inRecord.denorm, _totalSupply, _totalWeight, tokenAmountIn, _swapFee);

    require(poolAmountOut >= minPoolAmountOut, 'ERR_LIMIT_OUT');
    require(tokenAmountIn <= bmul(tokenInBalance, MAX_IN_RATIO), 'ERR_MAX_IN_RATIO');

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
    require(_finalized, 'ERR_NOT_FINALIZED');
    require(_records[tokenIn].bound, 'ERR_NOT_BOUND');

    Record storage inRecord = _records[tokenIn];
    uint256 tokenInBalance = IERC20(tokenIn).balanceOf(address(this));

    tokenAmountIn =
      calcSingleInGivenPoolOut(tokenInBalance, inRecord.denorm, _totalSupply, _totalWeight, poolAmountOut, _swapFee);

    require(tokenAmountIn != 0, 'ERR_MATH_APPROX');
    require(tokenAmountIn <= maxAmountIn, 'ERR_LIMIT_IN');
    require(tokenAmountIn <= bmul(tokenInBalance, MAX_IN_RATIO), 'ERR_MAX_IN_RATIO');

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
    require(_finalized, 'ERR_NOT_FINALIZED');
    require(_records[tokenOut].bound, 'ERR_NOT_BOUND');

    Record storage outRecord = _records[tokenOut];
    uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));

    tokenAmountOut =
      calcSingleOutGivenPoolIn(tokenOutBalance, outRecord.denorm, _totalSupply, _totalWeight, poolAmountIn, _swapFee);

    require(tokenAmountOut >= minAmountOut, 'ERR_LIMIT_OUT');
    require(tokenAmountOut <= bmul(tokenOutBalance, MAX_OUT_RATIO), 'ERR_MAX_OUT_RATIO');

    uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);

    emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

    _pullPoolShare(msg.sender, poolAmountIn);
    _burnPoolShare(bsub(poolAmountIn, exitFee));
    _pushPoolShare(_factory, exitFee);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return tokenAmountOut;
  }

  function exitswapExternAmountOut(
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPoolAmountIn
  ) external _logs_ _lock_ returns (uint256 poolAmountIn) {
    require(_finalized, 'ERR_NOT_FINALIZED');
    require(_records[tokenOut].bound, 'ERR_NOT_BOUND');

    Record storage outRecord = _records[tokenOut];
    uint256 tokenOutBalance = IERC20(tokenOut).balanceOf(address(this));

    poolAmountIn =
      calcPoolInGivenSingleOut(tokenOutBalance, outRecord.denorm, _totalSupply, _totalWeight, tokenAmountOut, _swapFee);

    require(poolAmountIn != 0, 'ERR_MATH_APPROX');
    require(poolAmountIn <= maxPoolAmountIn, 'ERR_LIMIT_IN');
    require(tokenAmountOut <= bmul(tokenOutBalance, MAX_OUT_RATIO), 'ERR_MAX_OUT_RATIO');

    uint256 exitFee = bmul(poolAmountIn, EXIT_FEE);

    emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

    _pullPoolShare(msg.sender, poolAmountIn);
    _burnPoolShare(bsub(poolAmountIn, exitFee));
    _pushPoolShare(_factory, exitFee);
    _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    return poolAmountIn;
  }

  // ==
  // 'Underlying' token-manipulation functions make external calls but are NOT locked
  // You must `_lock_` or otherwise ensure reentry-safety

  function _pullUnderlying(address erc20, address from, uint256 amount) internal {
    bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
    require(xfer, 'ERR_ERC20_FALSE');
  }

  function _pushUnderlying(address erc20, address to, uint256 amount) internal {
    bool xfer = IERC20(erc20).transfer(to, amount);
    require(xfer, 'ERR_ERC20_FALSE');
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

  function _grantApprovalsTo(address _target) internal {
    for (uint256 i = 0; i < _tokens.length; i++) {
      IERC20(_tokens[i]).approve(_target, type(uint256).max);
    }
  }

  function isValidSignature(bytes32, bytes memory) external pure override returns (bytes4 magicValue) {
    return this.isValidSignature.selector;
  }
}
