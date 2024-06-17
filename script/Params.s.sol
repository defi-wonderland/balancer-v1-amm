// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract Params {
  struct BFactoryDeploymentParams {
    address bLabs;
  }

  struct BCoWFactoryDeploymentParams {
    address bLabs;
    address settlement;
  }

  /// @notice BFactory deployment parameters for each chain
  mapping(uint256 _chainId => BFactoryDeploymentParams _params) internal _bFactoryDeploymentParams;

  /// @notice BCoWFactory deployment parameters for each chain
  mapping(uint256 _chainId => BCoWFactoryDeploymentParams _params) internal _bCoWFactoryDeploymentParams;

  constructor() {
    // Mainnet
    _bFactoryDeploymentParams[1] = BFactoryDeploymentParams(address(this));
    _bCoWFactoryDeploymentParams[1] = BCoWFactoryDeploymentParams(address(this), address(this));

    // Sepolia
    _bFactoryDeploymentParams[11_155_111] = BFactoryDeploymentParams(address(this));
    _bCoWFactoryDeploymentParams[11_155_111] = BCoWFactoryDeploymentParams(address(this), address(this));
  }
}
