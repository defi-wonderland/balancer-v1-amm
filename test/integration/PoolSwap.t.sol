// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Test} from 'forge-std/Test.sol';

import {BCoWPool, IBCoWPool} from 'contracts/BCoWPool.sol';
import {BFactory} from 'contracts/BFactory.sol';

import {GPv2Order} from 'cow-swap/GPv2Order.sol';
import {IBPool} from 'interfaces/IBPool.sol';

import {GasSnapshot} from 'forge-gas-snapshot/GasSnapshot.sol';

abstract contract PoolSwapIntegrationTest is Test, GasSnapshot {
  BFactory public factory;
  IBPool public pool;

  IERC20 public tokenA;
  IERC20 public tokenB;

  address public lp = address(420);
  address public swapper = address(69);
  address public bLabs = address(0x614B5);
  address public cowSwap = address(0xbeef);

  function setUp() public {
    tokenA = IERC20(address(deployMockERC20('TokenA', 'TKA', 18)));
    tokenB = IERC20(address(deployMockERC20('TokenB', 'TKB', 18)));

    deal(address(tokenA), address(lp), 100e18);
    deal(address(tokenB), address(lp), 100e18);

    deal(address(tokenA), address(swapper), 1e18);

    /**
     * BCoWPool requirements
     * TODO: move to a separate factory contract (reuse tests by inheritance)
     */
    vm.mockCall(cowSwap, abi.encodeWithSignature('domainSeparator()'), abi.encode(bytes32(0)));
    vm.mockCall(cowSwap, abi.encodeWithSignature('vaultRelayer()'), abi.encode(swapper));

    factory = new BFactory(cowSwap);

    vm.startPrank(lp);
    pool = factory.newBPool();

    tokenA.approve(address(pool), type(uint256).max);
    tokenB.approve(address(pool), type(uint256).max);

    pool.bind(address(tokenA), 1e18, 2e18); // 20% weight?
    pool.bind(address(tokenB), 1e18, 8e18); // 80%

    pool.finalize();

    bytes32 appData = '';
    BCoWPool(address(pool)).enableTrading(appData);

    vm.stopPrank();
  }

  function testDeployPool() public {
    snapStart('deployPool');
    factory.newBPool();
    snapEnd();
  }

  function testSimpleSwap() public {
    _makeSwap();
    assertEq(tokenA.balanceOf(address(swapper)), 0.5e18);
    // NOTE: hardcoded from test result
    assertEq(tokenB.balanceOf(address(swapper)), 0.096397921069149814e18);

    vm.startPrank(lp);

    uint256 lpBalance = pool.balanceOf(address(lp));
    pool.exitPool(lpBalance, new uint256[](2));

    // NOTE: no swap fees involved
    assertEq(tokenA.balanceOf(address(lp)), 100.5e18); // initial 100 + 0.5 tokenA
    // NOTE: hardcoded from test result
    assertEq(tokenB.balanceOf(address(lp)), 99.903602078930850186e18); // initial 100 - ~0.09 tokenB
  }

  function _makeSwap() internal virtual;
}

contract DirectPoolSwapIntegrationTest is PoolSwapIntegrationTest {
  function _makeSwap() internal override {
    vm.startPrank(swapper);
    tokenA.approve(address(pool), type(uint256).max);

    // swap 0.5 tokenA for tokenB
    snapStart('swapExactAmountIn');
    pool.swapExactAmountIn(address(tokenA), 0.5e18, address(tokenB), 0, type(uint256).max);
    snapEnd();

    vm.stopPrank();
  }
}

contract IndirectPoolSwapIntegrationTest is PoolSwapIntegrationTest {
  function _makeSwap() internal override {
    vm.startPrank(swapper);
    // swap 0.5 tokenA for tokenB

    snapStart('indirectSwap');
    tokenA.transfer(address(pool), 0.5e18);
    tokenB.transferFrom(address(pool), address(swapper), 0.096397921069149814e18);
    snapEnd();
    vm.stopPrank();
  }
}

contract SignatureSwapIntegrationTest is PoolSwapIntegrationTest {
  function _makeSwap() internal override {
    GPv2Order.Data memory order = GPv2Order.Data({
      sellToken: tokenA,
      buyToken: tokenB,
      receiver: swapper,
      sellAmount: 0.5e18,
      buyAmount: 0.096397921069149814e18,
      validTo: 0,
      appData: '',
      feeAmount: 0,
      kind: GPv2Order.KIND_SELL,
      partiallyFillable: false,
      sellTokenBalance: GPv2Order.BALANCE_ERC20,
      buyTokenBalance: GPv2Order.BALANCE_ERC20
    });

    bytes memory orderData = abi.encode(order);
    bytes32 orderHash = GPv2Order.hash(order, bytes32(0));

    BCoWPool bCowPool = BCoWPool(address(pool));
    snapStart('signatureSwap');
    vm.prank(cowSwap);
    bCowPool.commit(orderHash);

    bCowPool.isValidSignature(orderHash, orderData);

    vm.startPrank(swapper);
    tokenA.transfer(address(pool), 0.5e18);
    tokenB.transferFrom(address(pool), address(swapper), 0.096397921069149814e18);
    snapEnd();
    vm.stopPrank();
  }
}
