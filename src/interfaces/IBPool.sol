// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.26;

import {IERC20} from 'forge-std/interfaces/IERC20.sol';

interface IBPool is IERC20 {
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

  function setSwapFee(uint256 swapFee) external;

  function setController(address manager) external;

  function finalize() external;

  function bind(address token, uint256 balance, uint256 denorm) external;

  function unbind(address token) external;

  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

  function swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice
  ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

  function joinswapExternAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    uint256 minPoolAmountOut
  ) external returns (uint256 poolAmountOut);

  function joinswapPoolAmountOut(
    address tokenIn,
    uint256 poolAmountOut,
    uint256 maxAmountIn
  ) external returns (uint256 tokenAmountIn);

  function exitswapPoolAmountIn(
    address tokenOut,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) external returns (uint256 tokenAmountOut);

  function exitswapExternAmountOut(
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPoolAmountIn
  ) external returns (uint256 poolAmountIn);
}
