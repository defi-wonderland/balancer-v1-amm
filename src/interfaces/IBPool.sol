// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

interface IBPool {
  struct Record {
    bool bound; // is token bound to pool
    uint256 index; // internal
    uint256 denorm; // denormalized weight
  }
  /**
   * @notice Emitted when a swap is performed
   * @param caller The caller of the swap function
   * @param tokenIn The address of the token being swapped in
   * @param tokenOut The address of the token being swapped out
   * @param tokenAmountIn The amount of tokenIn being swapped in
   * @param tokenAmountOut The amount of tokenOut being swapped out
   */

  event LOG_SWAP(
    address indexed caller,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 tokenAmountIn,
    uint256 tokenAmountOut
  );

  /**
   * @notice Emitted when a token amount is introduced to the pool
   * @param _caller The caller of the function
   * @param _tokenIn The address of the token being sent to the pool
   * @param _tokenAmountIn The balance of the token being sent to the pool
   */
  event LOG_JOIN(address indexed _caller, address indexed _tokenIn, uint256 _tokenAmountIn);

  /**
   * @notice Emitted when a token amount is removed from the pool
   * @param _caller The caller of the function
   * @param _tokenOut The address of the token being removed from the pool
   * @param _tokenAmountOut The balance of the token being removed from the pool
   */
  event LOG_EXIT(address indexed _caller, address indexed _tokenOut, uint256 _tokenAmountOut);

  /**
   * @notice Emitted when a call is performed to the pool
   * @param _sig The signature of the function selector being called
   * @param _caller The caller of the function
   * @param _data The complete data of the call
   */
  event LOG_CALL(bytes4 indexed _sig, address indexed _caller, bytes _data) anonymous;

  /**
   * @notice Sets the new swap fee
   * @param _swapFee The new swap fee
   */
  function setSwapFee(uint256 _swapFee) external;

  /**
   * @notice Sets the new controller
   * @param _manager The new controller
   */
  function setController(address _manager) external;

  /**
   * @notice Finalize the pool, removing the restrictions on the pool
   */
  function finalize() external;

  /**
   * @notice Binds a token to the pool
   * @param _token The address of the token to bind
   * @param _balance The balance of the token to bind
   * @param _denorm The denormalized weight of the token to bind
   */
  function bind(address _token, uint256 _balance, uint256 _denorm) external;

  /**
   * @notice Unbinds a token from the pool
   * @param _token The address of the token to unbind
   */
  function unbind(address _token) external;

  /**
   * @notice Joins a pool, providing each token in the pool with a proportional amount
   * @param _poolAmountOut The amount of pool tokens to mint
   * @param _maxAmountsIn The maximum amount of tokens to send to the pool
   */
  function joinPool(uint256 _poolAmountOut, uint256[] calldata _maxAmountsIn) external;

  /**
   * @notice Exits a pool, receiving each token in the pool with a proportional amount
   * @param _poolAmountIn The amount of pool tokens to burn
   * @param _minAmountsOut The minimum amount of tokens to receive from the pool
   */
  function exitPool(uint256 _poolAmountIn, uint256[] calldata _minAmountsOut) external;

  /**
   * @notice Swaps an exact amount of tokens in for as many tokens out as possible
   * @param _tokenIn The address of the token to swap in
   * @param _tokenAmountIn The amount of token to swap in
   * @param _tokenOut The address of the token to swap out
   * @param _minAmountOut The minimum amount of token to receive from the swap
   * @param _maxPrice The maximum price to pay for the swap
   * @return _tokenAmountOut The amount of token swapped out
   * @return _spotPriceAfter The spot price after the swap
   */
  function swapExactAmountIn(
    address _tokenIn,
    uint256 _tokenAmountIn,
    address _tokenOut,
    uint256 _minAmountOut,
    uint256 _maxPrice
  ) external returns (uint256 _tokenAmountOut, uint256 _spotPriceAfter);

  /**
   * @notice Swaps as many tokens in as possible for an exact amount of tokens out
   * @param _tokenIn The address of the token to swap in
   * @param _maxAmountIn The maximum amount of token to swap in
   * @param _tokenOut The address of the token to swap out
   * @param _tokenAmountOut The amount of token to swap out
   * @param _maxPrice The maximum price to pay for the swap
   * @return _tokenAmountIn The amount of token swapped in
   * @return _spotPriceAfter The spot price after the swap
   */
  function swapExactAmountOut(
    address _tokenIn,
    uint256 _maxAmountIn,
    address _tokenOut,
    uint256 _tokenAmountOut,
    uint256 _maxPrice
  ) external returns (uint256 _tokenAmountIn, uint256 _spotPriceAfter);

  /**
   * @notice Joins a pool providing only a single token, and a specific amount of tokenIn
   * @param _tokenIn The address of the token to swap in and join
   * @param _tokenAmountIn The amount of token to join
   * @param _minPoolAmountOut The minimum amount of pool token to receive
   * @return _poolAmountOut The amount of pool token received
   */
  function joinswapExternAmountIn(
    address _tokenIn,
    uint256 _tokenAmountIn,
    uint256 _minPoolAmountOut
  ) external returns (uint256 _poolAmountOut);

  /**
   * @notice Joins a pool expecting a specific amount of pool token, and providing only a single token
   * @param _tokenIn The address of the token to swap in and join
   * @param _poolAmountOut The amount of pool token to receive
   * @param _maxAmountIn The maximum amount of token to introduce to the pool
   * @return _tokenAmountIn The amount of token in introduced
   */
  function joinswapPoolAmountOut(
    address _tokenIn,
    uint256 _poolAmountOut,
    uint256 _maxAmountIn
  ) external returns (uint256 _tokenAmountIn);

  /**
   * @notice Exits a pool providing a specific amount of pool in, and receiving only a single token
   * @param _tokenOut The address of the token to swap out and exit
   * @param _poolAmountIn The amount of pool token to burn
   * @param _minAmountOut The minimum amount of token to receive
   * @return _tokenAmountOut The amount of token received
   */
  function exitswapPoolAmountIn(
    address _tokenOut,
    uint256 _poolAmountIn,
    uint256 _minAmountOut
  ) external returns (uint256 _tokenAmountOut);

  /**
   * @notice Exits a pool expecting a specific amount of token out, and providing pool token
   * @param _tokenOut The address of the token to swap out and exit
   * @param _tokenAmountOut The amount of token to receive
   * @param _maxPoolAmountIn The maximum amount of pool token to burn
   * @return _poolAmountIn The amount of pool token burned
   */
  function exitswapExternAmountOut(
    address _tokenOut,
    uint256 _tokenAmountOut,
    uint256 _maxPoolAmountIn
  ) external returns (uint256 _poolAmountIn);

  /**
   * @notice Gets the spot price of a hypothetical swap
   * @param _tokenIn The address of the token to swap in
   * @param _tokenOut The address of the token to swap out
   * @return _spotPrice The spot price of the swap
   */
  function getSpotPrice(address _tokenIn, address _tokenOut) external view returns (uint256 _spotPrice);

  /**
   * @notice Gets the spot price of a hypothetical swap without the fee
   * @param _tokenIn The address of the token to swap in
   * @param _tokenOut The address of the token to swap out
   * @return _spotPrice The spot price of the swap without the fee
   */
  function getSpotPriceSansFee(address _tokenIn, address _tokenOut) external view returns (uint256 _spotPrice);

  /**
   * @notice Gets the finalized status of the pool
   * @return _isFinalized True if the pool is finalized, False otherwise
   */
  function isFinalized() external view returns (bool _isFinalized);

  /**
   * @notice Gets the bound status of a token
   * @param _t The address of the token to check
   * @return _isBound True if the token is bound, False otherwise
   */
  function isBound(address _t) external view returns (bool _isBound);

  /**
   * @notice Gets the number of tokens in the pool
   * @return _numTokens The number of tokens in the pool
   */
  function getNumTokens() external view returns (uint256 _numTokens);

  /**
   * @notice Gets the current array of tokens in the pool, while the pool is not finalized
   * @return _tokens The array of tokens in the pool
   */
  function getCurrentTokens() external view returns (address[] memory _tokens);

  /**
   * @notice Gets the final array of tokens in the pool, after finalization
   * @return _tokens The array of tokens in the pool
   */
  function getFinalTokens() external view returns (address[] memory _tokens);

  /**
   * @notice Gets the denormalized weight of a token in the pool
   * @param _token The address of the token to check
   * @return _denormWeight The denormalized weight of the token in the pool
   */
  function getDenormalizedWeight(address _token) external view returns (uint256 _denormWeight);

  /**
   * @notice Gets the total denormalized weight of the pool
   * @return _totalDenormWeight The total denormalized weight of the pool
   */
  function getTotalDenormalizedWeight() external view returns (uint256 _totalDenormWeight);

  /**
   * @notice Gets the normalized weight of a token in the pool
   * @param _token The address of the token to check
   * @return _normWeight The normalized weight of the token in the pool
   */
  function getNormalizedWeight(address _token) external view returns (uint256 _normWeight);

  /**
   * @notice Gets the balance of a token in the pool
   * @param _token The address of the token to check
   * @return _balance The balance of the token in the pool
   */
  function getBalance(address _token) external view returns (uint256 _balance);

  /**
   * @notice Gets the swap fee of the pool
   * @return _swapFee The swap fee of the pool
   */
  function getSwapFee() external view returns (uint256 _swapFee);

  /**
   * @notice Gets the controller of the pool
   * @return _controller The controller of the pool
   */
  function getController() external view returns (address _controller);
}
