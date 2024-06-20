// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

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

contract EchidnaUtils {
  event AssertionFailed();

  IHevm hevm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
}
