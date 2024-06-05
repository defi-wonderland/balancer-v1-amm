// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BFactory} from 'contracts/BFactory.sol';
import {IERC20} from 'contracts/BToken.sol';
import {GasSnapshot} from 'forge-gas-snapshot/GasSnapshot.sol';
import {Test} from 'forge-std/Test.sol';

abstract contract Base is Test, GasSnapshot {
  BFactory public factory;

  IERC20 public tokenA;
  IERC20 public tokenB;

  address public lp = address(420);
  address public swapper = address(69);

  uint256 lpInitialBalanceTokenA = 100e18;
  uint256 lpInitialBalanceTokenB = 100e18;
  uint256 swapperInitialBalanceTokenA = 1e18;

  function setUp() public virtual {
    tokenA = IERC20(address(deployMockERC20('TokenA', 'TKA', 18)));
    tokenB = IERC20(address(deployMockERC20('TokenB', 'TKB', 18)));

    deal(address(tokenA), address(lp), lpInitialBalanceTokenA);
    deal(address(tokenB), address(lp), lpInitialBalanceTokenB);

    deal(address(tokenA), address(swapper), swapperInitialBalanceTokenA);

    factory = new BFactory();
  }
}
