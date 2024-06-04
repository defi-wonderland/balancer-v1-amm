// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

address constant SEPOLIA_FAUCET = 0x26bfAecAe4D5fa93eE1737ce1Ce7D53F2a0E9b2d;
address constant SEPOLIA_BAL_TOKEN = 0xb19382073c7A0aDdbb56Ac6AF1808Fa49e377B75;
address constant SEPOLIA_DAI_TOKEN = 0xB77EB1A70A96fDAAeB31DB1b42F2b8b5846b2613;
address constant SEPOLIA_USDC_TOKEN = 0x80D6d3946ed8A1Da4E226aa21CCdDc32bd127d1A;

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
