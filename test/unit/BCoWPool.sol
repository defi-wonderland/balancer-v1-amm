// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {
  BaseBPool_Unit_Constructor,
  BaseBPool_Unit_ExitPool,
  BaseBPool_Unit_ExitswapExternAmountOut,
  BaseBPool_Unit_ExitswapPoolAmountIn,
  BaseBPool_Unit_JoinPool,
  BaseBPool_Unit_JoinswapExternAmountIn,
  BaseBPool_Unit_JoinswapPoolAmountOut,
  BaseBPool_Unit_SetSwapFee,
  BaseBPool_Unit__PullUnderlying,
  BaseBPool_Unit__PushUnderlying,
  BasePoolTest
} from './BPool.t.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';
import {MockBCoWPool} from 'test/manual-smock/MockBCoWPool.sol';
import {MockBPool} from 'test/smock/MockBPool.sol';

import {Test} from 'forge-std/Test.sol';

abstract contract BaseCoWPoolTest is BasePoolTest {
  address public cowSolutionSettler = makeAddr('cowSolutionSettler');
  bytes32 public domainSeparator = bytes32(bytes2(0xf00b));
  address public vaultRelayer = makeAddr('vaultRelayer');

  function _deployPool() internal override returns (address) {
    vm.mockCall(cowSolutionSettler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(domainSeparator));
    vm.mockCall(cowSolutionSettler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(vaultRelayer));
    return address(new MockBCoWPool(cowSolutionSettler));
  }
}

contract BCoWPool_Unit_Constructor is BaseCoWPoolTest {
  function test_Set_SolutionSettler(address _settler) public {
    assumeNotForgeAddress(_settler);
    vm.mockCall(_settler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(domainSeparator));
    vm.mockCall(_settler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(vaultRelayer));
    MockBCoWPool pool = new MockBCoWPool(_settler);
    assertEq(address(pool.SOLUTION_SETTLER()), _settler);
  }

  function test_Set_DomainSeparator(address _settler, bytes32 _separator) public {
    assumeNotForgeAddress(_settler);
    vm.mockCall(_settler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(_separator));
    vm.mockCall(_settler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(vaultRelayer));
    MockBCoWPool pool = new MockBCoWPool(_settler);
    assertEq(pool.SOLUTION_SETTLER_DOMAIN_SEPARATOR(), _separator);
  }

  function test_Set_VaultRelayer(address _settler, address _relayer) public {
    assumeNotForgeAddress(_settler);
    vm.mockCall(_settler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(domainSeparator));
    vm.mockCall(_settler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(_relayer));
    MockBCoWPool pool = new MockBCoWPool(_settler);
    assertEq(pool.VAULT_RELAYER(), _relayer);
  }
}

contract BCoWPool_Unit_Finalize is BaseCoWPoolTest {
  function test_setsApprovals(uint256 _tokensLength) public {
    _tokensLength = bound(_tokensLength, MIN_BOUND_TOKENS, MAX_BOUND_TOKENS);
    _setRandomTokens(_tokensLength);
    address[] memory tokens = _getDeterministicTokenArray(_tokensLength);
    for (uint256 i = 0; i < bPool.getNumTokens(); i++) {
      vm.mockCall(tokens[i], abi.encodePacked(IERC20.approve.selector), abi.encode(true));
      vm.expectCall(tokens[i], abi.encodeCall(IERC20.approve, (vaultRelayer, type(uint256).max)));
    }
    bPool.finalize();
  }
}

// BaseBPool tests implementations

contract BPool_Unit_Constructor is BaseBPool_Unit_Constructor, BaseCoWPoolTest {}

contract BPool_Unit_SetSwapFee is BaseBPool_Unit_SetSwapFee, BaseCoWPoolTest {}

contract BPool_Unit_JoinPool is BaseBPool_Unit_JoinPool, BaseCoWPoolTest {}

contract BPool_Unit_ExitPool is BaseBPool_Unit_ExitPool, BaseCoWPoolTest {}

contract BPool_Unit_JoinswapExternAmountIn is BaseBPool_Unit_JoinswapExternAmountIn, BaseCoWPoolTest {}

contract BPool_Unit_JoinswapPoolAmountOut is BaseBPool_Unit_JoinswapPoolAmountOut, BaseCoWPoolTest {}

contract BPool_Unit_ExitswapPoolAmountIn is BaseBPool_Unit_ExitswapPoolAmountIn, BaseCoWPoolTest {}

contract BPool_Unit_ExitswapExternAmountOut is BaseBPool_Unit_ExitswapExternAmountOut, BaseCoWPoolTest {}

contract BPool_Unit__PullUnderlying is BaseBPool_Unit__PullUnderlying, BaseCoWPoolTest {}

contract BPool_Unit__PushUnderlying is BaseBPool_Unit__PushUnderlying, BaseCoWPoolTest {}
