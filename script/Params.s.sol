// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from 'forge-std/Test.sol';

contract Params is Test {
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

  /// @notice Deployer address for each chain
  mapping(uint256 _chainId => address _deployer) internal _deployer;

  constructor() {
    _deployer[1] = vm.addr(uint256(vm.envBytes32('MAINNET_DEPLOYER_PK')));
    _deployer[11_155_111] = vm.addr(uint256(vm.envBytes32('SEPOLIA_DEPLOYER_PK')));

    // Mainnet
    _bFactoryDeploymentParams[1] = BFactoryDeploymentParams(address(this));
    _bCoWFactoryDeploymentParams[1] = BCoWFactoryDeploymentParams(address(this), address(this));

    // Sepolia
    _bFactoryDeploymentParams[11_155_111] = BFactoryDeploymentParams(address(this));
    _bCoWFactoryDeploymentParams[11_155_111] = BCoWFactoryDeploymentParams(address(this), address(this));
  }
}
