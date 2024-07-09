// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {EchidnaTest, FuzzERC20} from '../../AdvancedTestsUtils.sol';

import {BCoWFactory, BCoWPool} from 'contracts/BCoWFactory.sol';
import {BConst} from 'contracts/BConst.sol';

import {MockSettler} from './MockSettler.sol';

contract EchidnaBalancer is EchidnaTest {
  // System under test
  BCoWFactory factory;
  BConst bconst;

  address solutionSettler;
  bytes32 appData;

  bool alreadySetup;

  FuzzERC20[] tokens;
  BCoWPool[] deployedPools;
  mapping(BCoWPool => bool) finalizedPools;

  constructor() {
    solutionSettler = address(new MockSettler());

    factory = new BCoWFactory(solutionSettler, appData);
    bconst = new BConst();
  }

  modifier providedEnoughTokenCaller(FuzzERC20 _token, uint256 _amount) {
    _token.mint(currentCaller, _amount);
    _;
  }

  function setup_tokens() public AgentOrDeployer {
    if (!alreadySetup) {
      // max bound token is 8
      for (uint256 i; i < 8; i++) {
        FuzzERC20 _token = new FuzzERC20();
        _token.initialize('', '', 18);
        tokens.push(_token);
      }

      alreadySetup = true;
    }
  }

  function setup_poolLiquidity(uint256 _numberOfTokens, uint256 _poolIndex) public {
    _poolIndex = _poolIndex % deployedPools.length;

    _numberOfTokens = clamp(_numberOfTokens, bconst.MIN_BOUND_TOKENS(), bconst.MAX_BOUND_TOKENS());

    BCoWPool pool = deployedPools[_poolIndex];
    require(!deployedPools[_poolIndex].isFinalized());

    for (uint256 i; i < _numberOfTokens; i++) {
      FuzzERC20 _token = tokens[i];
      uint256 _amount = bconst.INIT_POOL_SUPPLY() / _numberOfTokens;
      pool.bind(address(_token), _amount, bconst.MIN_WEIGHT());
    }

    // require(_amountA >= bconst.MIN_BALANCE() && _amountB >= bconst.MIN_BALANCE());
    // require(_denormA + _denormB <= bconst.MAX_TOTAL_WEIGHT());

    // tokenA.approve(address(pool), _amountA);
    // tokenB.approve(address(pool), _amountB);
    // pool.bind(address(tokenA), _amountA, _denormA);
    // pool.bind(address(tokenB), _amountB, _denormB);
    // pool.finalize();
  }

  // Probably wants to have a pool setup with more than 2 tokens too + swap
  /// @custom:property-id 1
  /// @custom:property BFactory should always be able to deploy new pools
  function fuzz_BFactoryAlwaysDeploy() public AgentOrDeployer {
    // Precondition
    require(deployedPools.length < 4); // Avoid too many pools to interact with
    hevm.prank(currentCaller);

    // Action
    BCoWPool _newPool = BCoWPool(address(factory.newBPool()));

    // Postcondition
    deployedPools.push(_newPool);

    assert(address(_newPool).code.length > 0);
    assert(factory.isBPool(address(_newPool)));
    assert(!_newPool.isFinalized());
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
  function fuzz_alwayCollect() public AgentOrDeployer {}

  /// @custom:property-id 8
  /// @custom:property  BToken increaseApproval should increase the approval of the address by the amount
  function fuzz_increaseApproval() public AgentOrDeployer {}

  /// @custom:property-id 9
  /// @custom:property BToken decreaseApproval should decrease the approval to max(old-amount, 0)
  function fuzz_decreaseApproval() public AgentOrDeployer {}
}
