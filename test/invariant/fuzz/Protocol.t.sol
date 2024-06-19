// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BConst} from 'contracts/BConst.sol';
import {BFactory, BPool, IBPool} from 'contracts/BFactory.sol';
import {IERC20, MockERC20} from 'forge-std/mocks/MockERC20.sol';

interface IHevm {
  function prank(address) external;
}

contract FuzzERC20 is MockERC20 {
  function mint(address _to, uint256 _amount) public {
    _mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) public {
    _burn(_from, _amount);
  }
}

contract AgentsHandler {
  uint256 public agentsIndex;
  address[] agents;

  constructor(uint256 _numAgents) {
    for (uint256 i = 0; i < _numAgents; i++) {
      agents.push(address(bytes20(keccak256(abi.encodePacked(i)))));
    }
  }

  function nextAgent() public {
    agentsIndex = (agentsIndex + 1) % agents.length;
  }

  function getCurrentAgent() public view returns (address) {
    return agents[agentsIndex];
  }
}

contract Setup {
  IERC20 public tokenA;
  IERC20 public tokenB;

  BFactory public factory;
  BPool public pool;

  AgentsHandler agentHandler;
}

contract Test {
  // System under test
  BFactory factory;
  BConst bconst;
  FuzzERC20 tokenA;
  FuzzERC20 tokenB;

  // Handler
  AgentsHandler agentHandler;
  address currentCaller;

  mapping(address => bool) alreadyMinted;

  IBPool[] deployedPools;

  // Echidna
  IHevm hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

  event AssertionFailed();

  modifier AgentOrDeployer() {
    uint256 _currentAgentIndex = agentHandler.agentsIndex();
    currentCaller = _currentAgentIndex == 0 ? address(this) : agentHandler.getCurrentAgent();
    _;
  }

  constructor() {
    agentHandler = new AgentsHandler(5);

    tokenA = new FuzzERC20();
    tokenB = new FuzzERC20();
    tokenA.initialize('', '', 18);
    tokenB.initialize('', '', 18);

    factory = new BFactory();
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
    IBPool pool = deployedPools[_poolIndex];

    tokenA.approve(address(pool), _amountA);
    tokenB.approve(address(pool), _amountB);
    pool.bind(address(tokenA), _amountA, _denormA);
    pool.bind(address(tokenB), _amountB, _denormB);
    pool.finalize();
  }

  // Probably wants to have a pool setup with more than 2 tokens too + swap

  function fuzz_BFactoryAlwaysDeploy() public AgentOrDeployer {
    hevm.prank(currentCaller);
    IBPool _newPool = factory.newBPool();

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
