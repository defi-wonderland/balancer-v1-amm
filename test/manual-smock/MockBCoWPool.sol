// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {BCoWPool, BPool, GPv2Order, IBCoWPool, IERC1271, IERC20, ISettlement} from '../../src/contracts/BCoWPool.sol';
import {BMath, IBPool} from '../../src/contracts/BPool.sol';
import {GPv2Order} from 'cowprotocol/contracts/libraries/GPv2Order.sol';
import {Test} from 'forge-std/Test.sol';

contract MockBCoWPool is BCoWPool, Test {
  /// MockBCoWPool mock methods
  function set_appDataHash(bytes32 _appDataHash) public {
    appDataHash = _appDataHash;
  }

  function set_commitment(bytes32 _commitment) public {
    assembly ("memory-safe") {
      tstore(COMMITMENT_SLOT, _commitment)
    }
  }

  function mock_call_appDataHash(bytes32 _value) public {
    vm.mockCall(address(this), abi.encodeWithSignature('appDataHash()'), abi.encode(_value));
  }

  constructor(address _cowSolutionSettler) BCoWPool(_cowSolutionSettler) {}

  function mock_call_enableTrading(bytes32 appData) public {
    vm.mockCall(address(this), abi.encodeWithSignature('enableTrading(bytes32)', appData), abi.encode());
  }

  function mock_call_disableTrading() public {
    vm.mockCall(address(this), abi.encodeWithSignature('disableTrading()'), abi.encode());
  }

  function mock_call_commit(bytes32 orderHash) public {
    vm.mockCall(address(this), abi.encodeWithSignature('commit(bytes32)', orderHash), abi.encode());
  }

  function mock_call_isValidSignature(bytes32 _hash, bytes memory signature, bytes4 _returnParam0) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature('isValidSignature(bytes32,bytes)', _hash, signature),
      abi.encode(_returnParam0)
    );
  }

  function mock_call_commitment(bytes32 value) public {
    vm.mockCall(address(this), abi.encodeWithSignature('commitment()'), abi.encode(value));
  }

  function mock_call_verify(GPv2Order.Data memory order) public {
    vm.mockCall(address(this), abi.encodeWithSignature('verify(GPv2Order.Data)', order), abi.encode());
  }

  function mock_call_hash(bytes32 appData, bytes32 _returnParam0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('hash(bytes32)', appData), abi.encode(_returnParam0));
  }
  /// BPool Mocked methods

  function set__mutex(bool __mutex) public {
    _mutex = __mutex;
  }

  function call__mutex() public view returns (bool) {
    return _mutex;
  }

  function set__factory(address __factory) public {
    _factory = __factory;
  }

  function call__factory() public view returns (address) {
    return _factory;
  }

  function set__controller(address __controller) public {
    _controller = __controller;
  }

  function call__controller() public view returns (address) {
    return _controller;
  }

  function set__swapFee(uint256 __swapFee) public {
    _swapFee = __swapFee;
  }

  function call__swapFee() public view returns (uint256) {
    return _swapFee;
  }

  function set__finalized(bool __finalized) public {
    _finalized = __finalized;
  }

  function call__finalized() public view returns (bool) {
    return _finalized;
  }

  function set__tokens(address[] memory __tokens) public {
    _tokens = __tokens;
  }

  function call__tokens() public view returns (address[] memory) {
    return _tokens;
  }

  function set__records(address _key0, IBPool.Record memory _value) public {
    _records[_key0] = _value;
  }

  function call__records(address _key0) public view returns (IBPool.Record memory) {
    return _records[_key0];
  }

  function set__totalWeight(uint256 __totalWeight) public {
    _totalWeight = __totalWeight;
  }

  function call__totalWeight() public view returns (uint256) {
    return _totalWeight;
  }

  function mock_call_setSwapFee(uint256 swapFee) public {
    vm.mockCall(address(this), abi.encodeWithSignature('setSwapFee(uint256)', swapFee), abi.encode());
  }

  function mock_call_setController(address manager) public {
    vm.mockCall(address(this), abi.encodeWithSignature('setController(address)', manager), abi.encode());
  }

  function mock_call_finalize() public {
    vm.mockCall(address(this), abi.encodeWithSignature('finalize()'), abi.encode());
  }

  function mock_call_bind(address token, uint256 balance, uint256 denorm) public {
    vm.mockCall(
      address(this), abi.encodeWithSignature('bind(address,uint256,uint256)', token, balance, denorm), abi.encode()
    );
  }

  function mock_call_unbind(address token) public {
    vm.mockCall(address(this), abi.encodeWithSignature('unbind(address)', token), abi.encode());
  }

  function mock_call_joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) public {
    vm.mockCall(
      address(this), abi.encodeWithSignature('joinPool(uint256,uint256[])', poolAmountOut, maxAmountsIn), abi.encode()
    );
  }

  function mock_call_exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) public {
    vm.mockCall(
      address(this), abi.encodeWithSignature('exitPool(uint256,uint256[])', poolAmountIn, minAmountsOut), abi.encode()
    );
  }

  function mock_call_swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice,
    uint256 tokenAmountOut,
    uint256 spotPriceAfter
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        'swapExactAmountIn(address,uint256,address,uint256,uint256)',
        tokenIn,
        tokenAmountIn,
        tokenOut,
        minAmountOut,
        maxPrice
      ),
      abi.encode(tokenAmountOut, spotPriceAfter)
    );
  }

  function mock_call_swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice,
    uint256 tokenAmountIn,
    uint256 spotPriceAfter
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        'swapExactAmountOut(address,uint256,address,uint256,uint256)',
        tokenIn,
        maxAmountIn,
        tokenOut,
        tokenAmountOut,
        maxPrice
      ),
      abi.encode(tokenAmountIn, spotPriceAfter)
    );
  }

  function mock_call_joinswapExternAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    uint256 minPoolAmountOut,
    uint256 poolAmountOut
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        'joinswapExternAmountIn(address,uint256,uint256)', tokenIn, tokenAmountIn, minPoolAmountOut
      ),
      abi.encode(poolAmountOut)
    );
  }

  function mock_call_joinswapPoolAmountOut(
    address tokenIn,
    uint256 poolAmountOut,
    uint256 maxAmountIn,
    uint256 tokenAmountIn
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature('joinswapPoolAmountOut(address,uint256,uint256)', tokenIn, poolAmountOut, maxAmountIn),
      abi.encode(tokenAmountIn)
    );
  }

  function mock_call_exitswapPoolAmountIn(
    address tokenOut,
    uint256 poolAmountIn,
    uint256 minAmountOut,
    uint256 tokenAmountOut
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature('exitswapPoolAmountIn(address,uint256,uint256)', tokenOut, poolAmountIn, minAmountOut),
      abi.encode(tokenAmountOut)
    );
  }

  function mock_call_exitswapExternAmountOut(
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPoolAmountIn,
    uint256 poolAmountIn
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        'exitswapExternAmountOut(address,uint256,uint256)', tokenOut, tokenAmountOut, maxPoolAmountIn
      ),
      abi.encode(poolAmountIn)
    );
  }

  function mock_call_getSpotPrice(address tokenIn, address tokenOut, uint256 spotPrice) public {
    vm.mockCall(
      address(this), abi.encodeWithSignature('getSpotPrice(address,address)', tokenIn, tokenOut), abi.encode(spotPrice)
    );
  }

  function mock_call_getSpotPriceSansFee(address tokenIn, address tokenOut, uint256 spotPrice) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature('getSpotPriceSansFee(address,address)', tokenIn, tokenOut),
      abi.encode(spotPrice)
    );
  }

  function mock_call_isFinalized(bool _returnParam0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('isFinalized()'), abi.encode(_returnParam0));
  }

  function mock_call_isBound(address t, bool _returnParam0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('isBound(address)', t), abi.encode(_returnParam0));
  }

  function mock_call_getNumTokens(uint256 _returnParam0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('getNumTokens()'), abi.encode(_returnParam0));
  }

  function mock_call_getCurrentTokens(address[] memory tokens) public {
    vm.mockCall(address(this), abi.encodeWithSignature('getCurrentTokens()'), abi.encode(tokens));
  }

  function mock_call_getFinalTokens(address[] memory tokens) public {
    vm.mockCall(address(this), abi.encodeWithSignature('getFinalTokens()'), abi.encode(tokens));
  }

  function mock_call_getDenormalizedWeight(address token, uint256 _returnParam0) public {
    vm.mockCall(
      address(this), abi.encodeWithSignature('getDenormalizedWeight(address)', token), abi.encode(_returnParam0)
    );
  }

  function mock_call_getTotalDenormalizedWeight(uint256 _returnParam0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('getTotalDenormalizedWeight()'), abi.encode(_returnParam0));
  }

  function mock_call_getNormalizedWeight(address token, uint256 _returnParam0) public {
    vm.mockCall(
      address(this), abi.encodeWithSignature('getNormalizedWeight(address)', token), abi.encode(_returnParam0)
    );
  }

  function mock_call_getBalance(address token, uint256 _returnParam0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('getBalance(address)', token), abi.encode(_returnParam0));
  }

  function mock_call_getSwapFee(uint256 _returnParam0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('getSwapFee()'), abi.encode(_returnParam0));
  }

  function mock_call_getController(address _returnParam0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('getController()'), abi.encode(_returnParam0));
  }

  function mock_call__pullUnderlying(address erc20, address from, uint256 amount) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature('_pullUnderlying(address,address,uint256)', erc20, from, amount),
      abi.encode()
    );
  }

  function _pullUnderlying(address erc20, address from, uint256 amount) internal override {
    (bool _success, bytes memory _data) =
      address(this).call(abi.encodeWithSignature('_pullUnderlying(address,address,uint256)', erc20, from, amount));

    if (_success) return abi.decode(_data, ());
    else return super._pullUnderlying(erc20, from, amount);
  }

  function call__pullUnderlying(address erc20, address from, uint256 amount) public {
    return _pullUnderlying(erc20, from, amount);
  }

  function expectCall__pullUnderlying(address erc20, address from, uint256 amount) public {
    vm.expectCall(
      address(this), abi.encodeWithSignature('_pullUnderlying(address,address,uint256)', erc20, from, amount)
    );
  }

  function mock_call__pushUnderlying(address erc20, address to, uint256 amount) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature('_pushUnderlying(address,address,uint256)', erc20, to, amount),
      abi.encode()
    );
  }

  function _pushUnderlying(address erc20, address to, uint256 amount) internal override {
    (bool _success, bytes memory _data) =
      address(this).call(abi.encodeWithSignature('_pushUnderlying(address,address,uint256)', erc20, to, amount));

    if (_success) return abi.decode(_data, ());
    else return super._pushUnderlying(erc20, to, amount);
  }

  function call__pushUnderlying(address erc20, address to, uint256 amount) public {
    return _pushUnderlying(erc20, to, amount);
  }

  function expectCall__pushUnderlying(address erc20, address to, uint256 amount) public {
    vm.expectCall(address(this), abi.encodeWithSignature('_pushUnderlying(address,address,uint256)', erc20, to, amount));
  }
  // BCoWPool overrides

  function verify(GPv2Order.Data memory order) public view override {
    (bool _success, bytes memory _data) =
      address(this).staticcall(abi.encodeWithSignature('verify(GPv2Order.Data)', order));

    if (_success) return abi.decode(_data, ());
    else return super.verify(order);
  }

  function expectCall_verify(GPv2Order.Data memory order) public {
    vm.expectCall(address(this), abi.encodeWithSignature('verify(GPv2Order.Data)', order));
  }
}
