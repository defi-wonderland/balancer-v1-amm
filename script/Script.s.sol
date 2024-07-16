// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IBPool} from 'contracts/BPool.sol';
import {IFaucet} from 'interfaces/IFaucet.sol';

import {Script} from 'forge-std/Script.sol';
import {Registry} from 'script/Registry.s.sol';

abstract contract BaseScript is Registry, Script {
  constructor() Registry(block.chainid) {}
}

contract MainnetScript is BaseScript {
  /// @notice This script will be executed by `yarn script:mainnet`
  function run() public {
    assert(block.chainid == 1);
    vm.startBroadcast();

    // script logic here

    vm.stopBroadcast();
  }
}

contract TestnetScript is BaseScript {
  /// @notice ERC20 and Faucet addresses
  address internal constant _SEPOLIA_FAUCET = 0x26bfAecAe4D5fa93eE1737ce1Ce7D53F2a0E9b2d;
  address internal constant _SEPOLIA_BAL_TOKEN = 0xb19382073c7A0aDdbb56Ac6AF1808Fa49e377B75;
  address internal constant _SEPOLIA_DAI_TOKEN = 0xB77EB1A70A96fDAAeB31DB1b42F2b8b5846b2613;
  address internal constant _SEPOLIA_USDC_TOKEN = 0x80D6d3946ed8A1Da4E226aa21CCdDc32bd127d1A;

  /// @notice This script will be executed by `yarn script:testnet`
  /// @dev The following is an example of a script that deploys a Balancer CoW pool
  function run() public {
    assert(block.chainid == 11_155_111);
    vm.startBroadcast();

    // NOTE: dripping can be called by anyone but only once a day (per address)
    IFaucet(_SEPOLIA_FAUCET).drip(_SEPOLIA_BAL_TOKEN);
    IFaucet(_SEPOLIA_FAUCET).drip(_SEPOLIA_DAI_TOKEN);
    IFaucet(_SEPOLIA_FAUCET).drip(_SEPOLIA_USDC_TOKEN);

    IBPool bPool = bCoWFactory.newBPool();

    IERC20(_SEPOLIA_BAL_TOKEN).approve(address(bPool), type(uint256).max);
    IERC20(_SEPOLIA_DAI_TOKEN).approve(address(bPool), type(uint256).max);
    IERC20(_SEPOLIA_USDC_TOKEN).approve(address(bPool), type(uint256).max);

    bPool.bind(_SEPOLIA_BAL_TOKEN, 40e18, 1e18);
    bPool.bind(_SEPOLIA_DAI_TOKEN, 10e18, 1e18);
    bPool.bind(_SEPOLIA_USDC_TOKEN, 10e6, 1e18);

    bPool.finalize();
    vm.stopBroadcast();
  }
}
