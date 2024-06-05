// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

interface IBPool {
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

  function setSwapFee(uint256 _swapFee) external;

  function setController(address _manager) external;

  function finalize() external;

  function bind(address _token, uint256 _balance, uint256 _denorm) external;

  function unbind(address _token) external;

  function joinPool(uint256 _poolAmountOut, uint256[] calldata _maxAmountsIn) external;

  function exitPool(uint256 _poolAmountIn, uint256[] calldata _minAmountsOut) external;

  function swapExactAmountIn(
    address _tokenIn,
    uint256 _tokenAmountIn,
    address _tokenOut,
    uint256 _minAmountOut,
    uint256 _maxPrice
  ) external returns (uint256 _tokenAmountOut, uint256 _spotPriceAfter);

  function swapExactAmountOut(
    address _tokenIn,
    uint256 _maxAmountIn,
    address _tokenOut,
    uint256 _tokenAmountOut,
    uint256 _maxPrice
  ) external returns (uint256 _tokenAmountIn, uint256 _spotPriceAfter);

  function joinswapExternAmountIn(
    address _tokenIn,
    uint256 _tokenAmountIn,
    uint256 _minPoolAmountOut
  ) external returns (uint256 _poolAmountOut);

  function joinswapPoolAmountOut(
    address _tokenIn,
    uint256 _poolAmountOut,
    uint256 _maxAmountIn
  ) external returns (uint256 _tokenAmountIn);

  function exitswapPoolAmountIn(
    address _tokenOut,
    uint256 _poolAmountIn,
    uint256 _minAmountOut
  ) external returns (uint256 _tokenAmountOut);

  function exitswapExternAmountOut(
    address _tokenOut,
    uint256 _tokenAmountOut,
    uint256 _maxPoolAmountIn
  ) external returns (uint256 _poolAmountIn);

  function getSpotPrice(address _tokenIn, address _tokenOut) external view returns (uint256 _spotPrice);

  function getSpotPriceSansFee(address _tokenIn, address _tokenOut) external view returns (uint256 _spotPrice);

  function isFinalized() external view returns (bool _isFinalized);

  function isBound(address _t) external view returns (bool _isBound);

  function getNumTokens() external view returns (uint256 _numTokens);

  function getCurrentTokens() external view returns (address[] memory _tokens);

  function getFinalTokens() external view returns (address[] memory _tokens);

  function getDenormalizedWeight(address _token) external view returns (uint256 _denormWeight);

  function getTotalDenormalizedWeight() external view returns (uint256 _totalDenormWeight);

  function getNormalizedWeight(address _token) external view returns (uint256 _normWeight);

  function getBalance(address _token) external view returns (uint256 _balance);

  function getSwapFee() external view returns (uint256 _swapFee);

  function getController() external view returns (address _controller);
}
