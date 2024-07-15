// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {FuzzERC20, HalmosTest} from '../helpers/AdvancedTestsUtils.sol';

import {MockSettler} from '../helpers/MockSettler.sol';
import {BCoWFactory, BCoWPool, IBPool} from 'contracts/BCoWFactory.sol';
import {BConst} from 'contracts/BConst.sol';
import {BMath} from 'contracts/BMath.sol';
import {BNum} from 'contracts/BNum.sol';

contract HalmosBalancer is HalmosTest {
  // System under test
  BCoWFactory factory;
  BConst bconst;
  BMath bmath;
  BNum_exposed bnum;

  address solutionSettler;
  bytes32 appData;

  FuzzERC20[] tokens;
  BCoWPool pool;

  address currentCaller = svm.createAddress('currentCaller');

  constructor() {
    solutionSettler = address(new MockSettler());
    factory = new BCoWFactory(solutionSettler, appData);
    bconst = new BConst();
    bmath = new BMath();
    bnum = new BNum_exposed();
    pool = BCoWPool(address(factory.newBPool()));

    // max bound token is 8
    for (uint256 i; i < 5; i++) {
      FuzzERC20 _token = new FuzzERC20();
      _token.initialize('', '', 18);
      tokens.push(_token);

      _token.mint(address(this), 10 ether);
      _token.approve(address(pool), 10 ether);

      uint256 _poolWeight = bconst.MAX_WEIGHT() / 5;

      pool.bind(address(_token), 10 ether, _poolWeight);
    }

    pool.finalize();
  }

  /// @custom:property-id 0
  /// @custom:property BFactory should always be able to deploy new pools
  function check_deploy() public {
    assert(factory.SOLUTION_SETTLER() == solutionSettler);
    assert(pool.isFinalized());
  }

  /// @custom:property-id 1
  /// @custom:property BFactory should always be able to deploy new pools
  function check_BFactoryAlwaysDeploy(address _caller) public {
    // Precondition
    vm.assume(_caller != address(0));
    vm.prank(_caller);

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
  function check_blabAlwaysModByBLab() public {
    // Precondition
    address _currentBLab = factory.getBLabs();

    vm.prank(currentCaller);

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
  function check_alwaysCollect() public {
    // Precondition
    address _currentBLab = factory.getBLabs();

    vm.prank(currentCaller);

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
  /// @custom:property-id 13
  /// @custom:property an exact amount in should always earn the amount out calculated in bmath
  /// @custom:property-id 15
  /// @custom:property there can't be any amount out for a 0 amount in
  /// @custom:property-id 19
  /// @custom:property a swap can only happen when the pool is finalized
  function skipped_swapExactIn(uint256 _minAmountOut, uint256 _amountIn, uint256 _tokenIn, uint256 _tokenOut) public {
    // Preconditions
    vm.assume(_tokenIn < tokens.length);
    vm.assume(_tokenOut < tokens.length);
    vm.assume(_tokenIn != _tokenOut); // todo: dig this, it should pass without this precondition

    tokens[_tokenIn].mint(currentCaller, _amountIn);

    vm.prank(currentCaller);
    tokens[_tokenIn].approve(address(pool), type(uint256).max); // approval isn't limiting

    uint256 _balanceOutBefore = tokens[_tokenOut].balanceOf(currentCaller);

    uint256 _outComputed = bmath.calcOutGivenIn(
      tokens[_tokenIn].balanceOf(address(pool)),
      pool.getDenormalizedWeight(address(tokens[_tokenIn])),
      tokens[_tokenOut].balanceOf(address(pool)),
      pool.getDenormalizedWeight(address(tokens[_tokenOut])),
      _amountIn,
      bconst.MIN_FEE()
    );

    vm.prank(currentCaller);

    // Action
    try pool.swapExactAmountIn(
      address(tokens[_tokenIn]), _amountIn, address(tokens[_tokenOut]), _minAmountOut, type(uint256).max
    ) {
      // Postcondition
      uint256 _balanceOutAfter = tokens[_tokenOut].balanceOf(currentCaller);

      // 13
      assert(_balanceOutAfter - _balanceOutBefore == _outComputed);

      // 4
      if (_amountIn != 0) assert(_balanceOutBefore <= _balanceOutAfter + _minAmountOut);
      // 15
      else assert(_balanceOutBefore == _balanceOutAfter);

      // 19
      assert(pool.isFinalized());
    } catch {}
  }

  /// @custom:property-id 5
  /// @custom:property the amount spent can never be greater than max amount in
  /// @custom:property-id 14
  /// @custom:property an exact amount out is earned only if the amount in calculated in bmath is transfere
  /// @custom:property-id 15
  /// @custom:property there can't be any amount out for a 0 amount in
  /// @custom:property-id 19
  /// @custom:property a swap can only happen when the pool is finalized
  function skipped_swapExactOut(uint256 _maxAmountIn, uint256 _amountOut, uint256 _tokenIn, uint256 _tokenOut) public {
    // Precondition
    vm.assume(_tokenIn < tokens.length);
    vm.assume(_tokenOut < tokens.length);

    tokens[_tokenIn].mint(currentCaller, _maxAmountIn);

    vm.prank(currentCaller);
    tokens[_tokenIn].approve(address(pool), type(uint256).max); // approval isn't limiting

    uint256 _balanceInBefore = tokens[_tokenIn].balanceOf(currentCaller);
    uint256 _balanceOutBefore = tokens[_tokenOut].balanceOf(currentCaller);

    uint256 _inComputed = bmath.calcInGivenOut(
      tokens[_tokenIn].balanceOf(address(pool)),
      pool.getDenormalizedWeight(address(tokens[_tokenIn])),
      tokens[_tokenOut].balanceOf(address(pool)),
      pool.getDenormalizedWeight(address(tokens[_tokenOut])),
      _amountOut,
      bconst.MIN_FEE()
    );

    vm.prank(currentCaller);

    // Action
    try pool.swapExactAmountOut(
      address(tokens[_tokenIn]), _maxAmountIn, address(tokens[_tokenOut]), _amountOut, type(uint256).max
    ) {
      // Postcondition
      uint256 _balanceInAfter = tokens[_tokenIn].balanceOf(currentCaller);
      uint256 _balanceOutAfter = tokens[_tokenOut].balanceOf(currentCaller);

      // 5
      assert(_balanceInBefore - _balanceInAfter <= _maxAmountIn);

      // 14
      if (_tokenIn != _tokenOut) assert(_balanceOutAfter - _balanceOutBefore == _amountOut);
      else assert(_balanceOutAfter == _balanceOutBefore - _inComputed + _amountOut);

      // 15
      if (_balanceInBefore == _balanceInAfter) assert(_balanceOutBefore == _balanceOutAfter);

      // 19
      assert(pool.isFinalized());
    } catch {}
  }

  /// @custom:property-id 6
  /// @custom:property swap fee can only be 0 (cow pool)

  /// @custom:property-id 7
  /// @custom:property total weight can be up to 50e18
  /// @dev Only 2 tokens are used, to avoid hitting the limit in loop unrolling
  function check_totalWeightMax(uint256[2] calldata _weights) public {
    // Precondition
    BCoWPool _pool = BCoWPool(address(factory.newBPool()));

    uint256 _totalWeight = 0;

    for (uint256 i; i < 2; i++) {
      vm.assume(_weights[i] >= bconst.MIN_WEIGHT() && _weights[i] <= bconst.MAX_WEIGHT());
    }

    for (uint256 i; i < 2; i++) {
      FuzzERC20 _token = new FuzzERC20();
      _token.initialize('', '', 18);
      _token.mint(address(this), 10 ether);
      _token.approve(address(_pool), 10 ether);

      uint256 _poolWeight = _weights[i];

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

  /// properties 8 and 9 are tested with the BToken internal tests

  /// @custom:property-id 10
  /// @custom:property a pool can either be finalized or not finalized
  /// @dev included to be exhaustive/future-proof if more states are added, as rn, it
  /// basically tests the tautological (a || !a)

  /// @custom:property-id 11
  /// @custom:property a finalized pool cannot switch back to non-finalized

  /// @custom:property-id 12
  /// @custom:property a non-finalized pool can only be finalized when the controller calls finalize()
  function check_poolFinalizedByController() public {
    // Precondition
    IBPool _nonFinalizedPool = factory.newBPool();

    vm.prank(_nonFinalizedPool.getController());

    for (uint256 i; i < 3; i++) {
      FuzzERC20 _token = new FuzzERC20();

      _token.initialize('', '', 18);
      _token.mint(_nonFinalizedPool.getController(), 10 ether);
      _token.approve(address(_nonFinalizedPool), 10 ether);

      uint256 _poolWeight = bconst.MAX_WEIGHT() / 5;

      _nonFinalizedPool.bind(address(_token), 10 ether, _poolWeight);
    }
    vm.stopPrank();

    vm.prank(currentCaller);

    // Action
    try _nonFinalizedPool.finalize() {
      // Postcondition
      assert(currentCaller == _nonFinalizedPool.getController());
    } catch {}
  }

  /// @custom:property-id 16
  /// @custom:property the pool btoken can only be minted/burned in the join and exit operations

  /// @custom:property-id 17
  /// @custom:property a direct token transfer can never reduce the underlying amount of a given token per BPT
  function skipped_directTransfer(uint256 _amountPoolToken, uint256 _amountToTransfer, uint256 _tokenIdx) public {
    vm.assume(_tokenIdx < tokens.length);

    FuzzERC20 _token = tokens[2];

    uint256 _redeemedAmountBeforeTransfer = bmath.calcSingleOutGivenPoolIn(
      _token.balanceOf(address(pool)),
      pool.getDenormalizedWeight(address(_token)),
      pool.totalSupply(),
      pool.getTotalDenormalizedWeight(),
      _amountPoolToken,
      bconst.MIN_FEE()
    );

    _token.mint(address(this), _amountToTransfer);
    // Action
    _token.transfer(address(pool), _amountToTransfer);

    // Postcondition
    uint256 _redeemedAmountAfter = bmath.calcSingleOutGivenPoolIn(
      _token.balanceOf(address(pool)),
      pool.getDenormalizedWeight(address(_token)),
      pool.totalSupply(),
      pool.getTotalDenormalizedWeight(),
      _amountPoolToken,
      bconst.MIN_FEE()
    );

    assert(_redeemedAmountAfter >= _redeemedAmountBeforeTransfer);
  }

  /// @custom:property-id 18
  /// @custom:property the amount of underlying token when exiting should always be the amount calculated in bmath
  function correctBPTBurnAmount(uint256 _amountPoolToken) public {
    _amountPoolToken = bound(_amountPoolToken, 0, pool.balanceOf(currentCaller));

    uint256[] memory _amountsToReceive = new uint256[](4);
    uint256[] memory _previousBalances = new uint256[](4);

    for (uint256 i; i < tokens.length; i++) {
      FuzzERC20 _token = tokens[i];

      _amountsToReceive[i] = bmath.calcSingleOutGivenPoolIn(
        _token.balanceOf(address(pool)),
        pool.getDenormalizedWeight(address(_token)),
        pool.totalSupply(),
        pool.getTotalDenormalizedWeight(),
        _amountPoolToken,
        bconst.MIN_FEE()
      );

      _previousBalances[i] = _token.balanceOf(currentCaller);
    }

    vm.prank(currentCaller);
    pool.approve(address(pool), _amountPoolToken);

    vm.prank(currentCaller);

    // Action
    pool.exitPool(_amountPoolToken, new uint256[](4));

    // PostCondition
    for (uint256 i; i < tokens.length; i++) {
      assert(tokens[i].balanceOf(currentCaller) == _previousBalances[i] + _amountsToReceive[i]);
    }
  }

  /// @custom:property-id 20
  /// @custom:property bounding and unbounding token can only be done on a non-finalized pool, by the controller
  function check_boundOnlyNotFinalized() public {
    // Precondition
    IBPool _nonFinalizedPool = factory.newBPool();

    address _callerBind = svm.createAddress('callerBind');
    address _callerUnbind = svm.createAddress('callerUnbind');
    address _callerFinalize = svm.createAddress('callerFinalize');

    for (uint256 i; i < 2; i++) {
      tokens[i].mint(_callerBind, 10 ether);

      vm.startPrank(_callerBind);
      tokens[i].approve(address(pool), 10 ether);

      uint256 _poolWeight = bconst.MAX_WEIGHT() / 5;

      try _nonFinalizedPool.bind(address(tokens[i]), 10 ether, _poolWeight) {
        assert(_callerBind == _nonFinalizedPool.getController());
      } catch {
        assert(_callerBind != _nonFinalizedPool.getController());
      }

      vm.stopPrank();
    }

    vm.prank(_callerUnbind);
    try _nonFinalizedPool.unbind(address(tokens[1])) {
      assert(_callerUnbind == _nonFinalizedPool.getController());
    } catch {
      assert(_callerUnbind != _nonFinalizedPool.getController());
    }

    vm.prank(_callerFinalize);
    try _nonFinalizedPool.finalize() {
      assert(_callerFinalize == _nonFinalizedPool.getController());
    } catch {
      // assert(_callerFinalize != _nonFinalizedPool.getController());
    }

    vm.stopPrank();
  }

  /// @custom:property-id 21
  /// @custom:property there always should be between MIN_BOUND_TOKENS and MAX_BOUND_TOKENS bound in a pool
  function fuzz_minMaxBoundToken() public {
    assert(pool.getNumTokens() >= bconst.MIN_BOUND_TOKENS());
    assert(pool.getNumTokens() <= bconst.MAX_BOUND_TOKENS());
  }

  /// @custom:property-id 22
  /// @custom:property only the settler can commit a hash
  function fuzz_settlerCommit() public {
    // Precondition
    vm.prank(currentCaller);

    // Action
    try pool.commit(hex'1234') {
      // Postcondition
      assert(currentCaller == solutionSettler);
    } catch {}
  }

  /// @custom:property-id 23
  /// @custom:property when a hash has been commited, only this order can be settled
  /// @custom:property-not-implemented
  function fuzz_settlerSettle() public {}
}

contract BNum_exposed is BNum {
  function bdiv_exposed(uint256 a, uint256 b) public pure returns (uint256) {
    return bdiv(a, b);
  }

  function bmul_exposed(uint256 a, uint256 b) public pure returns (uint256) {
    return bmul(a, b);
  }
}
