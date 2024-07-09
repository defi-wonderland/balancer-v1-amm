// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract Params {
  struct BFactoryDeploymentParams {
    address bDao;
  }

  struct BCoWFactoryDeploymentParams {
    address settlement;
    bytes32 appData;
  }

  /// @notice ERC20 and Faucet addresses
  address internal constant _SEPOLIA_FAUCET = 0x26bfAecAe4D5fa93eE1737ce1Ce7D53F2a0E9b2d;
  address internal constant _SEPOLIA_BAL_TOKEN = 0xb19382073c7A0aDdbb56Ac6AF1808Fa49e377B75;
  address internal constant _SEPOLIA_DAI_TOKEN = 0xB77EB1A70A96fDAAeB31DB1b42F2b8b5846b2613;
  address internal constant _SEPOLIA_USDC_TOKEN = 0x80D6d3946ed8A1Da4E226aa21CCdDc32bd127d1A;

  /// @notice Settlement address
  address internal constant _GPV2_SETTLEMENT = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;
  /// @notice Balancer DAO address (has controller permission to collect fees from BFactory pools)
  address internal constant _B_DAO = 0xce88686553686DA562CE7Cea497CE749DA109f9F;

  /**
   * @notice AppData identifier
   * @dev Value obtained from https://explorer.cow.fi/appdata?tab=encode
   *      - appCode: "CoW AMM Balancer"
   *      - metadata:hooks:version: 0.1.0
   *      - version: 1.1.0
   */
  bytes32 internal constant _APP_DATA = 0x362e5182440b52aa8fffe70a251550fbbcbca424740fe5a14f59bf0c1b06fe1d;

  /// @notice BFactory deployment parameters for each chain
  mapping(uint256 _chainId => BFactoryDeploymentParams _params) internal _bFactoryDeploymentParams;

  /// @notice BCoWFactory deployment parameters for each chain
  mapping(uint256 _chainId => BCoWFactoryDeploymentParams _params) internal _bCoWFactoryDeploymentParams;

  constructor() {
    // Mainnet
    _bFactoryDeploymentParams[1] = BFactoryDeploymentParams({bDao: _B_DAO});
    _bCoWFactoryDeploymentParams[1] = BCoWFactoryDeploymentParams({settlement: _GPV2_SETTLEMENT, appData: _APP_DATA});

    // Sepolia
    _bFactoryDeploymentParams[11_155_111] = BFactoryDeploymentParams({bDao: _B_DAO});
    _bCoWFactoryDeploymentParams[11_155_111] =
      BCoWFactoryDeploymentParams({settlement: _GPV2_SETTLEMENT, appData: _APP_DATA});
  }
}
