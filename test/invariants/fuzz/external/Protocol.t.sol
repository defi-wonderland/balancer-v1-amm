// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EchidnaTest, FuzzERC20} from '../../AdvancedTestsUtils.sol';

import {BCoWFactory, BCoWPool, IBPool} from 'contracts/BCoWFactory.sol';
import {BConst} from 'contracts/BConst.sol';
import {BMath} from 'contracts/BMath.sol';

import {MockSettler} from './MockSettler.sol';

contract EchidnaBalancer is EchidnaTest {
  // System under test
  BCoWFactory factory;
  BConst bconst;
  BMath bmath;

  address solutionSettler;
  bytes32 appData;

  FuzzERC20[] tokens;
  BCoWPool pool;
  bool poolIsFinalized;

  constructor() {
    solutionSettler = address(new MockSettler());

    factory = new BCoWFactory(solutionSettler, appData);
    bconst = new BConst();
    bmath = new BMath();

    // max bound token is 8
    for (uint256 i; i < 4; i++) {
      FuzzERC20 _token = new FuzzERC20();
      _token.initialize('', '', 18);
      tokens.push(_token);
    }
  }

  function provideEnoughTokenCaller(FuzzERC20 _token, uint256 _amount) internal {
    _token.mint(currentCaller, _amount);
  }

  function setup_poolLiquidity() public {
    if (poolIsFinalized) return;

    pool = BCoWPool(address(factory.newBPool()));

    for (uint256 i; i < 4; i++) {
      FuzzERC20 _token = new FuzzERC20();
      _token.initialize('', '', 18);
      tokens.push(_token);

      _token.mint(address(this), 10 ether);
      _token.approve(address(pool), 10 ether);

      uint256 _poolWeight = bconst.MAX_WEIGHT() / 5;

      try pool.bind(address(_token), 10 ether, _poolWeight) {}
      catch {
        emit AssertionFailed();
      }
    }

    pool.finalize();

    poolIsFinalized = true;
  }

  // function test_test() public {
  //   fuzz_BFactoryAlwaysDeploy();
  //   setup_poolLiquidity(2, 0, 1000);
  // }

  // Probably wants to have a pool setup with more than 2 tokens too + swap
  /// @custom:property-id 1
  /// @custom:property BFactory should always be able to deploy new pools
  function fuzz_BFactoryAlwaysDeploy() public AgentOrDeployer {
    // Precondition
    hevm.prank(currentCaller);

    // Action
    try factory.newBPool() returns (IBPool _newPool) {
      // Postcondition
      assert(address(_newPool).code.length > 0);
      assert(factory.isBPool(address(_newPool)));
      assert(!_newPool.isFinalized());
    } catch {
      assert(false);
    }
  }

  /// @custom:property-id 2
  /// @custom:property BFactory's blab should always be modifiable by the current blabs
  function fuzz_blabAlwaysModByBLab() public AgentOrDeployer {
    // Precondition
    address _currentBLab = factory.getBLabs();

    hevm.prank(currentCaller);

    // Action
    try factory.setBLabs(address(123)) {
      // Postcondition
      assert(_currentBLab == currentCaller);
    } catch {
      assert(_currentBLab != currentCaller);
    }
  }

  /// @custom:property-id 3
  /// @custom:property BFactory should always be able to transfer the BToken to the blab, if called by it
  function fuzz_alwaysCollect() public AgentOrDeployer {
    // Precondition
    address _currentBLab = factory.getBLabs();

    if (address(pool) == address(0)) {
      return;
    }

    hevm.prank(currentCaller);

    // Action
    try factory.collect(pool) {
      // Postcondition
      assert(_currentBLab == currentCaller);
    } catch {
      assert(_currentBLab != currentCaller);
    }
  }

  /// @custom:property-id 4
  /// @custom:property the amount received can never be less than min amount out
  /// @custom:property-id 15
  /// @custom:property there can't be any amount out for a 0 amount in
  function amountReceivedFloored(
    uint256 _minAmountOut,
    uint256 _amountIn,
    uint256 _tokenIn,
    uint256 _tokenOut
  ) public AgentOrDeployer {
    // Precondition
    require(pool.isFinalized());

    _tokenIn = clamp(_tokenIn, 0, tokens.length - 1);
    _tokenOut = clamp(_tokenOut, 0, tokens.length - 1);
    _amountIn = clamp(_amountIn, 0, 10 ether);

    require(_tokenIn != _tokenOut); // todo: dig this, it should pass without this precondition

    tokens[_tokenIn].mint(currentCaller, _amountIn);

    hevm.prank(currentCaller);
    tokens[_tokenIn].approve(address(pool), type(uint256).max); // approval isn't limiting

    uint256 _balanceOutBefore = tokens[_tokenOut].balanceOf(currentCaller);

    hevm.prank(currentCaller);

    // Action
    try pool.swapExactAmountIn(
      address(tokens[_tokenIn]), _amountIn, address(tokens[_tokenOut]), _minAmountOut, type(uint256).max
    ) {
      // Postcondition
      uint256 _balanceOutAfter = tokens[_tokenOut].balanceOf(currentCaller);

      // 4
      if (_amountIn != 0) assert(_balanceOutBefore <= _balanceOutAfter + _minAmountOut);
      // 15
      else assert(_balanceOutBefore == _balanceOutAfter);
    } catch {}
  }

  /// @custom:property-id 5
  /// @custom:property the amount spent can never be greater than max amount in
  /// @custom:property-id 15
  /// @custom:property there can't be any amount out for a 0 amount in
  function amountSpentCapped(
    uint256 _maxAmountIn,
    uint256 _amountOut,
    uint256 _tokenIn,
    uint256 _tokenOut
  ) public AgentOrDeployer {
    // Precondition
    require(pool.isFinalized());

    _tokenIn = clamp(_tokenIn, 0, tokens.length - 1);
    _tokenOut = clamp(_tokenOut, 0, tokens.length - 1);

    _maxAmountIn = clamp(_maxAmountIn, 0, 10 ether);

    tokens[_tokenIn].mint(currentCaller, _maxAmountIn);

    hevm.prank(currentCaller);
    tokens[_tokenIn].approve(address(pool), type(uint256).max); // approval isn't limiting

    uint256 _balanceInBefore = tokens[_tokenIn].balanceOf(currentCaller);
    uint256 _balanceOutBefore = tokens[_tokenOut].balanceOf(currentCaller);

    hevm.prank(currentCaller);

    // Action
    try pool.swapExactAmountOut(
      address(tokens[_tokenIn]), _maxAmountIn, address(tokens[_tokenOut]), _amountOut, type(uint256).max
    ) {
      // Postcondition
      uint256 _balanceInAfter = tokens[_tokenIn].balanceOf(currentCaller);
      uint256 _balanceOutAfter = tokens[_tokenOut].balanceOf(currentCaller);

      // 5
      assert(_balanceInBefore - _balanceInAfter <= _maxAmountIn);

      // 15
      if (_maxAmountIn == 0) assert(_balanceOutBefore == _balanceOutAfter);
    } catch {}
  }

  /// @custom:property-id 6
  /// @custom:property swap fee can only be 0 (cow pool)
  function fuzz_swapFeeAlwaysZero() public {
    assert(pool.getSwapFee() == bconst.MIN_FEE()); // todo: check if this is the intended property (min fee == 0?)
  }

  /// @custom:property-id 7
  /// @custom:property total weight can be up to 50e18
  function totalWeightMax(uint256 _numberTokens, uint256[8] calldata _weights) public {
    // Precondition
    BCoWPool _pool = BCoWPool(address(factory.newBPool()));

    _numberTokens = clamp(_numberTokens, bconst.MIN_BOUND_TOKENS(), bconst.MAX_BOUND_TOKENS());

    uint256 _totalWeight = 0;

    for (uint256 i; i < _numberTokens; i++) {
      FuzzERC20 _token = new FuzzERC20();
      _token.initialize('', '', 18);
      _token.mint(address(this), 10 ether);
      _token.approve(address(_pool), 10 ether);

      uint256 _poolWeight = _weights[i];
      _poolWeight = clamp(_poolWeight, bconst.MIN_WEIGHT(), bconst.MAX_WEIGHT());

      // Action
      try _pool.bind(address(_token), 10 ether, _poolWeight) {
        // Postcondition
        _totalWeight += _poolWeight;

        // 7
        assert(_totalWeight <= bconst.MAX_TOTAL_WEIGHT());
      } catch {
        // 7
        assert(_totalWeight + _poolWeight > bconst.MAX_TOTAL_WEIGHT());
        break;
      }
    }
  }

  /// @custom:property-id 10
  /// @custom:property a pool can either be finalized or not finalized

  /// @custom:property-id 11
  /// @custom:property a finalized pool cannot switch back to non-finalized

  /// @custom:property-id 12
  /// @custom:property a non-finalized pool can only be finalized when the controller calls finalize()

  /// @custom:property-id 13
  /// @custom:property an exact amount in should always earn the amount out calculated in bmath

  /// @custom:property-id 14
  /// @custom:property an exact amount out is earned only if the amount in calculated in bmath is transfered

  /// @custom:property there can't be any amount out for a 0 amount in
  /// @custom:property the pool btoken can only be minted/burned in the join and exit operations
  /// @custom:property a direct token transfer can never reduce the underlying amount of a given token per BPT
  /// @custom:property the amount of underlying token when exiting should always be the amount calculated in bmath
  /// @custom:property a swap can only happen when the pool is finalized
  /// @custom:property bounding and unbounding token can only be done on a non-finalized pool, by the controller
  /// @custom:property there always should be between MIN_BOUND_TOKENS and MAX_BOUND_TOKENS bound in a pool
  /// @custom:property only the settler can commit a hash
  /// @custom:property when a hash has been commited, only this order can be settled
  /// @custom:property BToken should not break the ToB ERC20 properties*
}
