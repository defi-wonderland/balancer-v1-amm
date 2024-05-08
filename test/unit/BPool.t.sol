// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BConst} from 'contracts/BConst.sol';
import {BPool} from 'contracts/BPool.sol';
import {IERC20} from 'contracts/BToken.sol';
import {Test} from 'forge-std/Test.sol';
import {LibString} from 'solmate/utils/LibString.sol';

abstract contract Base is Test, BConst {
  using LibString for *;

  uint256 public constant TOKENS_AMOUNT = 5;

  BPool public bPool;
  address[TOKENS_AMOUNT] public tokens;

  function setUp() public {
    bPool = new BPool();

    // Create fake tokens
    for (uint256 i = 0; i < tokens.length; i++) {
      tokens[i] = makeAddr(i.toString());
    }
  }
}

contract BPool_Unit_Constructor is Base {
  function test_Deploy() private view {}
}

contract BPool_Unit_IsPublicSwap is Base {
  function test_Returns_IsPublicSwap() private view {}
}

contract BPool_Unit_IsFinalized is Base {
  function test_Returns_IsFinalized() private view {}
}

contract BPool_Unit_IsBound is Base {
  function test_Returns_IsBound() private view {}

  function test_Returns_IsNotBound() private view {}
}

contract BPool_Unit_GetNumTokens is Base {
  function test_Returns_NumTokens() private view {}
}

contract BPool_Unit_GetCurrentTokens is Base {
  function test_Returns_CurrentTokens() private view {}

  function test_Revert_Reentrancy() private view {}
}

contract BPool_Unit_GetFinalTokens is Base {
  function test_Returns_FinalTokens() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Revert_NotFinalized() private view {}
}

contract BPool_Unit_GetDenormalizedWeight is Base {
  function test_Returns_DenormalizedWeight() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Revert_NotBound() private view {}
}

contract BPool_Unit_GetTotalDenormalizedWeight is Base {
  function test_Returns_TotalDenormalizedWeight() private view {}

  function test_Revert_Reentrancy() private view {}
}

contract BPool_Unit_GetNormalizedWeight is Base {
  function test_Returns_NormalizedWeight() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Revert_NotBound() private view {}
}

contract BPool_Unit_GetBalance is Base {
  function test_Returns_Balance() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Revert_NotBound() private view {}
}

contract BPool_Unit_GetSwapFee is Base {
  function test_Returns_SwapFee() private view {}

  function test_Revert_Reentrancy() private view {}
}

contract BPool_Unit_GetController is Base {
  function test_Returns_Controller() private view {}

  function test_Revert_Reentrancy() private view {}
}

contract BPool_Unit_SetSwapFee is Base {
  function test_Revert_Finalized() private view {}

  function test_Revert_NotController() private view {}

  function test_Revert_MinFee() private view {}

  function test_Revert_MaxFee() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_SwapFee() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_SetController is Base {
  function test_Revert_NotController() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_Controller() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_SetPublicSwap is Base {
  function test_Revert_Finalized() private view {}

  function test_Revert_NotController() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_PublicSwap() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_Finalize is Base {
  function test_Revert_NotController() private view {}

  function test_Revert_Finalized() private view {}

  function test_Revert_MinTokens() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_Finalize() private view {}

  function test_Set_PublicSwap() private view {}

  function test_Mint_InitPoolSupply() private view {}

  function test_Push_InitPoolSupply() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_Bind is Base {
  function test_Revert_NotController() private view {}

  function test_Revert_IsBound() private view {}

  function test_Revert_Finalized() private view {}

  function test_Revert_MaxPoolTokens() private view {}

  function test_Set_Record() private view {}

  function test_Set_TokenArray() private view {}

  function test_Emit_LogCall() private view {}

  function test_Call_Rebind() private view {}
}

contract BPool_Unit_Rebind is Base {
  function test_Revert_NotController() private view {}

  function test_Revert_NotBound() private view {}

  function test_Revert_Finalized() private view {}

  function test_Revert_MinWeight() private view {}

  function test_Revert_MaxWeight() private view {}

  function test_Revert_MinBalance() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_TotalWeightIfDenormMoreThanOldWeight() private view {}

  function test_Set_TotalWeightIfDenormLessThanOldWeight() private view {}

  function test_Revert_MaxTotalWeight() private view {}

  function test_Set_Denorm() private view {}

  function test_Set_Balance() private view {}

  function test_Pull_IfBalanceMoreThanOldBalance() private view {}

  function test_Push_UnderlyingIfBalanceLessThanOldBalance() private view {}

  function test_Push_FeeIfBalanceLessThanOldBalance() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_Unbind is Base {
  function test_Revert_NotController() private view {}

  function test_Revert_NotBound() private view {}

  function test_Revert_Finalized() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_TotalWeight() private view {}

  function test_Set_TokenArray() private view {}

  function test_Set_Index() private view {}

  function test_Unset_TokenArray() private view {}

  function test_Unset_Record() private view {}

  function test_Push_UnderlyingBalance() private view {}

  function test_Push_UnderlyingFee() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_Gulp is Base {
  function test_Revert_NotBound() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_Balance() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_GetSpotPrice is Base {
  function test_Revert_NotBoundTokenIn() private view {}

  function test_Revert_NotBoundTokenOut() private view {}

  function test_Returns_SpotPrice() private view {}

  function test_Revert_Reentrancy() private view {}
}

contract BPool_Unit_GetSpotPriceSansFee is Base {
  function test_Revert_NotBoundTokenIn() private view {}

  function test_Revert_NotBoundTokenOut() private view {}

  function test_Returns_SpotPrice() private view {}

  function test_Revert_Reentrancy() private view {}
}

contract BPool_Unit_JoinPool is Base {
  struct FuzzScenario {
    uint256 poolAmountOut;
    uint256 initPoolSupply;
    uint256[TOKENS_AMOUNT] balance;
  }

  function test_HappyPath(FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256[] memory maxAmountsIn = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      maxAmountsIn[i] = type(uint256).max;
    } // Using max possible amounts

    bPool.joinPool(_fuzz.poolAmountOut, maxAmountsIn);
  }

  function test_Revert_NotFinalized() private view {}

  function test_Revert_MathApprox() private view {}

  function test_Revert_TokenArrayMathApprox() private view {}

  function test_Revert_TokenArrayLimitIn() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_TokenArrayBalance() private view {}

  function test_Emit_TokenArrayLogJoin() private view {}

  function test_Pull_TokenArrayTokenAmountIn() private view {}

  function test_Mint_PoolShare() private view {}

  function test_Push_PoolShare() private view {}

  function test_Emit_LogCall() private view {}

  modifier happyPath(FuzzScenario memory _fuzz) {
    _assumeHappyPath(_fuzz);
    _setValues(_fuzz);
    _;
  }

  function _setValues(FuzzScenario memory _fuzz) internal {
    // Create mocks
    for (uint256 i = 0; i < tokens.length; i++) {
      vm.mockCall(tokens[i], abi.encodeWithSelector(IERC20(tokens[i]).transfer.selector), abi.encode(true));
      vm.mockCall(tokens[i], abi.encodeWithSelector(IERC20(tokens[i]).transferFrom.selector), abi.encode(true));
    }

    // Set tokens
    bytes memory _arraySlot = abi.encode(9);
    bytes32 _hashArraySlot = keccak256(_arraySlot);
    vm.store(address(bPool), bytes32(_arraySlot), bytes32(tokens.length)); // write length
    for (uint256 i = 0; i < tokens.length; i++) {
      vm.store(address(bPool), bytes32(uint256(_hashArraySlot) + i), bytes32(abi.encode(tokens[i]))); // write token
    }

    // Set balances
    for (uint256 i = 0; i < tokens.length; i++) {
      bytes32 _slot = keccak256(abi.encode(tokens[i], 10)); // mapping is found at slot 10
      vm.store(address(bPool), bytes32(uint256(_slot) + 0), bytes32(abi.encode(1))); // bound
      vm.store(address(bPool), bytes32(uint256(_slot) + 3), bytes32(abi.encode(_fuzz.balance[i]))); // balance
    }

    // Set public swap
    vm.store(
      address(bPool),
      bytes32(uint256(6)),
      bytes32(uint256(0x0000000000000000000000010000000000000000000000000000000000000000))
    );
    // Set finalize
    vm.store(address(bPool), bytes32(uint256(8)), bytes32(uint256(1)));
    // Set totalSupply
    vm.store(address(bPool), bytes32(uint256(2)), bytes32(_fuzz.initPoolSupply));
  }

  function _assumeHappyPath(FuzzScenario memory _fuzz) internal view {
    vm.assume(_fuzz.initPoolSupply >= INIT_POOL_SUPPLY);
    vm.assume(_fuzz.poolAmountOut >= _fuzz.initPoolSupply);
    vm.assume(_fuzz.poolAmountOut < type(uint256).max / BONE);

    uint256 _poolAmountOutTimesBONE = _fuzz.poolAmountOut * BONE; // bdiv uses '* BONE'
    uint256 _ratio = _poolAmountOutTimesBONE / _fuzz.initPoolSupply;
    uint256 _maxTokenAmountIn = type(uint256).max / _ratio;

    for (uint256 i = 0; i < _fuzz.balance.length; i++) {
      vm.assume(_fuzz.balance[i] >= MIN_BALANCE);
      vm.assume(_fuzz.balance[i] <= _maxTokenAmountIn); // L272
    }
  }
}

contract BPool_Unit_ExitPool is Base {
  function test_Revert_NotFinalized() private view {}

  function test_Revert_MathApprox() private view {}

  function test_Pull_PoolShare() private view {}

  function test_Push_PoolShare() private view {}

  function test_Burn_PoolShare() private view {}

  function test_Revert_TokenArrayMathApprox() private view {}

  function test_Revert_TokenArrayLimitOut() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_TokenArrayBalance() private view {}

  function test_Emit_TokenArrayLogExit() private view {}

  function test_Push_TokenArrayTokenAmountOut() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_SwapExactAmountIn is Base {
  function test_Revert_NotBoundTokenIn() private view {}

  function test_Revert_NotBoundTokenOut() private view {}

  function test_Revert_NotPublic() private view {}

  function test_Revert_MaxInRatio() private view {}

  function test_Revert_BadLimitPrice() private view {}

  function test_Revert_LimitOut() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_InRecord() private view {}

  function test_Set_OutRecord() private view {}

  function test_Revert_MathApprox() private view {}

  function test_Revert_LimitPrice() private view {}

  function test_Revert_MathApprox2() private view {}

  function test_Emit_LogSwap() private view {}

  function test_Pull_TokenAmountIn() private view {}

  function test_Push_TokenAmountOut() private view {}

  function test_Returns_AmountAndPrice() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_SwapExactAmountOut is Base {
  function test_Revert_NotBoundTokenIn() private view {}

  function test_Revert_NotBoundTokenOut() private view {}

  function test_Revert_NotPublic() private view {}

  function test_Revert_MaxOutRatio() private view {}

  function test_Revert_BadLimitPrice() private view {}

  function test_Revert_LimitIn() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_InRecord() private view {}

  function test_Set_OutRecord() private view {}

  function test_Revert_MathApprox() private view {}

  function test_Revert_LimitPrice() private view {}

  function test_Revert_MathApprox2() private view {}

  function test_Emit_LogSwap() private view {}

  function test_Pull_TokenAmountIn() private view {}

  function test_Push_TokenAmountOut() private view {}

  function test_Returns_AmountAndPrice() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_JoinswapExternAmountIn is Base {
  function test_Revert_NotFinalized() private view {}

  function test_Revert_NotBound() private view {}

  function test_Revert_MaxInRatio() private view {}

  function test_Revert_LimitOut() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_Balance() private view {}

  function test_Emit_LogJoin() private view {}

  function test_Mint_PoolShare() private view {}

  function test_Push_PoolShare() private view {}

  function test_Pull_Underlying() private view {}

  function test_Returns_PoolAmountOut() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_JoinswapExternAmountOut is Base {
  function test_Revert_NotFinalized() private view {}

  function test_Revert_NotBound() private view {}

  function test_Revert_MaxApprox() private view {}

  function test_Revert_LimitIn() private view {}

  function test_Revert_MaxInRatio() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_Balance() private view {}

  function test_Emit_LogJoin() private view {}

  function test_Mint_PoolShare() private view {}

  function test_Push_PoolShare() private view {}

  function test_Pull_Underlying() private view {}

  function test_Returns_TokenAmountIn() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_ExitswapPoolAmountIn is Base {
  function test_Revert_NotFinalized() private view {}

  function test_Revert_NotBound() private view {}

  function test_Revert_LimitOut() private view {}

  function test_Revert_MaxOutRatio() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_Balance() private view {}

  function test_Emit_LogExit() private view {}

  function test_Pull_PoolShare() private view {}

  function test_Burn_PoolShare() private view {}

  function test_Push_PoolShare() private view {}

  function test_Push_Underlying() private view {}

  function test_Returns_TokenAmountOut() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_ExitswapPoolAmountOut is Base {
  function test_Revert_NotFinalized() private view {}

  function test_Revert_NotBound() private view {}

  function test_Revert_MaxOutRatio() private view {}

  function test_Revert_MathApprox() private view {}

  function test_Revert_LimitIn() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_Balance() private view {}

  function test_Emit_LogExit() private view {}

  function test_Pull_PoolShare() private view {}

  function test_Burn_PoolShare() private view {}

  function test_Push_PoolShare() private view {}

  function test_Push_Underlying() private view {}

  function test_Returns_PoolAmountIn() private view {}

  function test_Emit_LogCall() private view {}
}
