// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract Params {
  struct DeploymentParams {
    address bLabs;
    address cowSwap;
  }

  address constant COW_SWAP_SOLUTION_SETTLER = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;

  /// @notice Deployment parameters for each chain
  mapping(uint256 _chainId => DeploymentParams _params) internal _deploymentParams;

  constructor() {
    // Mainnet
    _deploymentParams[1] = DeploymentParams({bLabs: address(this), cowSwap: COW_SWAP_SOLUTION_SETTLER});

    // Sepolia
    _deploymentParams[11_155_111] = DeploymentParams({bLabs: address(this), cowSwap: COW_SWAP_SOLUTION_SETTLER});
  }
}
