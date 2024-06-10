// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {
  BPool_Unit_Bind,
  BPool_Unit_ExitPool,
  BPool_Unit_ExitswapExternAmountOut,
  BPool_Unit_ExitswapPoolAmountIn,
  BPool_Unit_Finalize,
  BPool_Unit_GetBalance,
  BPool_Unit_GetController,
  BPool_Unit_GetCurrentTokens,
  BPool_Unit_GetDenormalizedWeight,
  BPool_Unit_GetFinalTokens,
  BPool_Unit_GetNormalizedWeight,
  BPool_Unit_GetNumTokens,
  BPool_Unit_GetSpotPrice,
  BPool_Unit_GetSpotPriceSansFee,
  BPool_Unit_GetSwapFee,
  BPool_Unit_GetTotalDenormalizedWeight,
  BPool_Unit_IsBound,
  BPool_Unit_IsFinalized,
  BPool_Unit_JoinPool,
  BPool_Unit_JoinswapExternAmountIn,
  BPool_Unit_JoinswapPoolAmountOut,
  BPool_Unit_SetController,
  BPool_Unit_SetSwapFee,
  BPool_Unit_SwapExactAmountIn,
  BPool_Unit_SwapExactAmountOut,
  BPool_Unit_Unbind,
  BPool_Unit__PullUnderlying,
  BPool_Unit__PushUnderlying
} from './BPool.t.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';
import {MockBCoWPool} from 'test/manual-smock/MockBCoWPool.sol';
import {MockBPool} from 'test/smock/MockBPool.sol';

import {Test} from 'forge-std/Test.sol';
import {Utils} from 'test/utils/Utils.sol';

contract Regressor is Test, Utils {
  uint256 public constant MAX_TOKENS = 8;

  address public cowSolutionSettler = makeAddr('cowSolutionSettler');
  bytes32 public domainSeparator = bytes32(bytes2(0xf00b));
  address public vaultRelayer = makeAddr('vaultRelayer');

  function configureCoWBPool() internal returns (MockBPool bPool) {
    address[] memory tokens = _getDeterministicTokenArray(MAX_TOKENS);
    for (uint256 i = 0; i < MAX_TOKENS; i++) {
      vm.mockCall(tokens[i], abi.encodePacked(IERC20.approve.selector), abi.encode(true));
    }
    vm.mockCall(cowSolutionSettler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(domainSeparator));
    vm.mockCall(cowSolutionSettler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(vaultRelayer));
    bPool = MockBPool(address(new MockBCoWPool(cowSolutionSettler)));
  }
}

contract BCoWPool_Regression_BPool_Unit_IsFinalized is Regressor, BPool_Unit_IsFinalized {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_IsBound is Regressor, BPool_Unit_IsBound {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_GetNumTokens is Regressor, BPool_Unit_GetNumTokens {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_GetCurrentTokens is Regressor, BPool_Unit_GetCurrentTokens {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_GetFinalTokens is Regressor, BPool_Unit_GetFinalTokens {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_GetDenormalizedWeight is Regressor, BPool_Unit_GetDenormalizedWeight {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_GetTotalDenormalizedWeight is Regressor, BPool_Unit_GetTotalDenormalizedWeight {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_GetNormalizedWeight is Regressor, BPool_Unit_GetNormalizedWeight {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_GetBalance is Regressor, BPool_Unit_GetBalance {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_GetSwapFee is Regressor, BPool_Unit_GetSwapFee {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_GetController is Regressor, BPool_Unit_GetController {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_SetSwapFee is Regressor, BPool_Unit_SetSwapFee {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_SetController is Regressor, BPool_Unit_SetController {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_Finalize is Regressor, BPool_Unit_Finalize {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_Bind is Regressor, BPool_Unit_Bind {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_Unbind is Regressor, BPool_Unit_Unbind {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_GetSpotPrice is Regressor, BPool_Unit_GetSpotPrice {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_GetSpotPriceSansFee is Regressor, BPool_Unit_GetSpotPriceSansFee {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_JoinPool is Regressor, BPool_Unit_JoinPool {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_ExitPool is Regressor, BPool_Unit_ExitPool {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_SwapExactAmountIn is Regressor, BPool_Unit_SwapExactAmountIn {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_SwapExactAmountOut is Regressor, BPool_Unit_SwapExactAmountOut {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_JoinswapExternAmountIn is Regressor, BPool_Unit_JoinswapExternAmountIn {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_JoinswapPoolAmountOut is Regressor, BPool_Unit_JoinswapPoolAmountOut {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_ExitswapPoolAmountIn is Regressor, BPool_Unit_ExitswapPoolAmountIn {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit_ExitswapExternAmountOut is Regressor, BPool_Unit_ExitswapExternAmountOut {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit__PullUnderlying is Regressor, BPool_Unit__PullUnderlying {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}

contract BCoWPool_Regression_BPool_Unit__PushUnderlying is Regressor, BPool_Unit__PushUnderlying {
  function setUp() public virtual override {
    super.setUp();
    bPool = configureCoWBPool();
  }
}
