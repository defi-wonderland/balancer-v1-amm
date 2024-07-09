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
  FuzzERC20 tokenA;
  FuzzERC20 tokenB;

  address solutionSettler;
  bytes32 appData;

  mapping(address => bool) alreadyMinted;

  BCoWPool[] deployedPools;

  constructor() {
    tokenA = new FuzzERC20();
    tokenB = new FuzzERC20();
    tokenA.initialize('', '', 18);
    tokenB.initialize('', '', 18);

    solutionSettler = address(new MockSettler());

    factory = new BCoWFactory(solutionSettler, appData);
    bconst = new BConst();
  }

  function setup_mint(uint256 _amountA, uint256 _amountB) public AgentOrDeployer {
    if (!alreadyMinted[currentCaller]) {
      alreadyMinted[currentCaller] = true;
      tokenA.mint(currentCaller, _amountA);
      tokenB.mint(currentCaller, _amountB);
    }
  }

  function setup_poolLiquidity(
    uint256 _amountA,
    uint256 _amountB,
    uint256 _denormA,
    uint256 _denormB,
    uint256 _poolIndex
  ) public {
    require(_amountA >= bconst.MIN_BALANCE() && _amountB >= bconst.MIN_BALANCE());
    require(_denormA + _denormB <= bconst.MAX_TOTAL_WEIGHT());

    _poolIndex = _poolIndex % deployedPools.length;
    BCoWPool pool = deployedPools[_poolIndex];

    tokenA.approve(address(pool), _amountA);
    tokenB.approve(address(pool), _amountB);
    pool.bind(address(tokenA), _amountA, _denormA);
    pool.bind(address(tokenB), _amountB, _denormB);
    pool.finalize();
  }

  // Probably wants to have a pool setup with more than 2 tokens too + swap

  function fuzz_BFactoryAlwaysDeploy() public AgentOrDeployer {
    hevm.prank(currentCaller);
    BCoWPool _newPool = BCoWPool(address(factory.newBPool()));

    deployedPools.push(_newPool);

    assert(address(_newPool).code.length > 0);
    assert(factory.isBPool(address(_newPool)));
    assert(!_newPool.isFinalized());
  }

  function fuzz_blabAlwaysModByBLab() public AgentOrDeployer {
    address _currentBLab = factory.getBLabs();

    hevm.prank(currentCaller);

    try factory.setBLabs(address(123)) {
      assert(_currentBLab == currentCaller);
    } catch {
      assert(_currentBLab != currentCaller);
    }
  }

  function fuzz_alwayCollect() public AgentOrDeployer {}

  function fuzz_increaseApproval() public AgentOrDeployer {}

  function fuzz_decreaseApproval() public AgentOrDeployer {}

  function fuzz_correctOutForExactIn() public AgentOrDeployer {}
}
