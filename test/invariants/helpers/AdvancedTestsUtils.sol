// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from 'forge-std/Test.sol';
import {MockERC20} from 'forge-std/mocks/MockERC20.sol';
import {SymTest} from 'halmos-cheatcodes/src/SymTest.sol';

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
  uint256 internal agentsIndex;
  address[] internal agents;

  address internal currentCaller;

  modifier agentOrDeployer() {
    uint256 _currentAgentIndex = agentsIndex;
    currentCaller = _currentAgentIndex == 0 ? address(this) : agents[agentsIndex];
    _;
  }

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

contract EchidnaTest is AgentsHandler {
  event AssertionFailed();

  IHevm hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

  constructor() AgentsHandler(5) {}

  function clamp(uint256 _value, uint256 _min, uint256 _max) internal pure returns (uint256) {
    if (_min > _max) {
      assert(false);
    }

    if (_value < _min || _value > _max) {
      return _min + (_value % (_max - _min + 1));
    }
    return _value;
  }
}

contract HalmosTest is SymTest, Test {}
