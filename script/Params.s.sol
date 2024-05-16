// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract Params {
  struct DeploymentParams {
    address bLabs;
    address cowSwap;
  }

  /// @notice Deployment parameters for each chain
  mapping(uint256 _chainId => DeploymentParams _params) internal _deploymentParams;

  constructor() {
    // Mainnet
    _deploymentParams[1] =
      DeploymentParams({bLabs: address(this), cowSwap: address(0xC92E8bdf79f0507f65a392b0ab4667716BFE0110)});

    // Sepolia
    _deploymentParams[11_155_111] =
      DeploymentParams({bLabs: address(this), cowSwap: address(0xC92E8bdf79f0507f65a392b0ab4667716BFE0110)});
  }
}
