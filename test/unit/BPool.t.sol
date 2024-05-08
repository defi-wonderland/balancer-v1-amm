// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BConst} from 'contracts/BConst.sol';
import {BPool} from 'contracts/BPool.sol';
import {IERC20} from 'contracts/BToken.sol';
import {Test, console} from 'forge-std/Test.sol';
import {LibString} from 'solmate/utils/LibString.sol';

abstract contract Base is Test, BConst {
  using LibString for *;

  BPool public bPool;
  address[8] public tokens;

  function setUp() public {
    bPool = new BPool();

    // Create fake tokens
    for (uint256 i = 0; i < tokens.length; i++) {
      tokens[i] = makeAddr(i.toString());
    }
  }
}

contract BPool_Unit_Constructor is Base {
  function test_Deploy() public view {}
}

contract BPool_Unit_IsPublicSwap is Base {
  function test_Returns_IsPublicSwap() public view {}
}

contract BPool_Unit_IsFinalized is Base {
  function test_Returns_IsFinalized() public view {}
}

contract BPool_Unit_IsBound is Base {
  function test_Returns_IsBound() public view {}

  function test_Returns_IsNotBound() public view {}
}

contract BPool_Unit_GetNumTokens is Base {
  function test_Returns_NumTokens() public view {}
}

contract BPool_Unit_GetCurrentTokens is Base {
  function test_Returns_CurrentTokens() public view {}

  function test_Revert_Reentrancy() public view {}
}

contract BPool_Unit_GetFinalTokens is Base {
  function test_Returns_FinalTokens() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Revert_NotFinalized() public view {}
}

contract BPool_Unit_GetDenormalizedWeight is Base {
  function test_Returns_DenormalizedWeight() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Revert_NotBound() public view {}
}

contract BPool_Unit_GetTotalDenormalizedWeight is Base {
  function test_Returns_TotalDenormalizedWeight() public view {}

  function test_Revert_Reentrancy() public view {}
}

contract BPool_Unit_GetNormalizedWeight is Base {
  function test_Returns_NormalizedWeight() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Revert_NotBound() public view {}
}

contract BPool_Unit_GetBalance is Base {
  function test_Returns_Balance() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Revert_NotBound() public view {}
}

contract BPool_Unit_GetSwapFee is Base {
  function test_Returns_SwapFee() public view {}

  function test_Revert_Reentrancy() public view {}
}

contract BPool_Unit_GetController is Base {
  function test_Returns_Controller() public view {}

  function test_Revert_Reentrancy() public view {}
}

contract BPool_Unit_SetSwapFee is Base {
  function test_Revert_Finalized() public view {}

  function test_Revert_NotController() public view {}

  function test_Revert_MinFee() public view {}

  function test_Revert_MaxFee() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_SwapFee() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_SetController is Base {
  function test_Revert_NotController() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_Controller() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_SetPublicSwap is Base {
  function test_Revert_Finalized() public view {}

  function test_Revert_NotController() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_PublicSwap() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_Finalize is Base {
  function test_Revert_NotController() public view {}

  function test_Revert_Finalized() public view {}

  function test_Revert_MinTokens() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_Finalize() public view {}

  function test_Set_PublicSwap() public view {}

  function test_Mint_InitPoolSupply() public view {}

  function test_Push_InitPoolSupply() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_Bind is Base {
  function test_Revert_NotController() public view {}

  function test_Revert_IsBound() public view {}

  function test_Revert_Finalized() public view {}

  function test_Revert_MaxPoolTokens() public view {}

  function test_Set_Record() public view {}

  function test_Set_TokenArray() public view {}

  function test_Emit_LogCall() public view {}

  function test_Call_Rebind() public view {}
}

contract BPool_Unit_Rebind is Base {
  function test_Revert_NotController() public view {}

  function test_Revert_NotBound() public view {}

  function test_Revert_Finalized() public view {}

  function test_Revert_MinWeight() public view {}

  function test_Revert_MaxWeight() public view {}

  function test_Revert_MinBalance() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_TotalWeightIfDenormMoreThanOldWeight() public view {}

  function test_Set_TotalWeightIfDenormLessThanOldWeight() public view {}

  function test_Revert_MaxTotalWeight() public view {}

  function test_Set_Denorm() public view {}

  function test_Set_Balance() public view {}

  function test_Pull_IfBalanceMoreThanOldBalance() public view {}

  function test_Push_UnderlyingIfBalanceLessThanOldBalance() public view {}

  function test_Push_FeeIfBalanceLessThanOldBalance() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_Unbind is Base {
  function test_Revert_NotController() public view {}

  function test_Revert_NotBound() public view {}

  function test_Revert_Finalized() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_TotalWeight() public view {}

  function test_Set_TokenArray() public view {}

  function test_Set_Index() public view {}

  function test_Unset_TokenArray() public view {}

  function test_Unset_Record() public view {}

  function test_Push_UnderlyingBalance() public view {}

  function test_Push_UnderlyingFee() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_Gulp is Base {
  function test_Revert_NotBound() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_Balance() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_GetSpotPrice is Base {
  function test_Revert_NotBoundTokenIn() public view {}

  function test_Revert_NotBoundTokenOut() public view {}

  function test_Returns_SpotPrice() public view {}

  function test_Revert_Reentrancy() public view {}
}

contract BPool_Unit_GetSpotPriceSansFee is Base {
  function test_Revert_NotBoundTokenIn() public view {}

  function test_Revert_NotBoundTokenOut() public view {}

  function test_Returns_SpotPrice() public view {}

  function test_Revert_Reentrancy() public view {}
}

contract BPool_Unit_JoinPool is Base {

  struct FuzzScenario {
    uint256 poolAmountOut;
    uint256[8] balance;
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
    vm.store(address(bPool), bytes32(uint256(2)), bytes32(INIT_POOL_SUPPLY));
  }

  function _assumeHappyPath(FuzzScenario memory _fuzz) internal view {
    vm.assume(_fuzz.poolAmountOut > INIT_POOL_SUPPLY);
    vm.assume(_fuzz.poolAmountOut < type(uint256).max / BONE);

    uint _poolAmountOutTimesBONE = _fuzz.poolAmountOut * BONE; // bdiv uses '* BONE'

    uint _ratio = _poolAmountOutTimesBONE / INIT_POOL_SUPPLY;

    for (uint256 i = 0; i < _fuzz.balance.length; i++) {
      vm.assume(_fuzz.balance[i] > MIN_BALANCE);

      uint _maxTokenAmountIn = type(uint256).max / _ratio;
      vm.assume(_fuzz.balance[i] < _maxTokenAmountIn); // L272
    }
  }

  modifier happyPath(FuzzScenario memory _fuzz) {
    _assumeHappyPath(_fuzz);
    _setValues(_fuzz);
    _;
  }

  function test_HappyPath(FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256[] memory maxAmountsIn = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) { maxAmountsIn[i] = type(uint256).max; } // Using max possible amounts

    bPool.joinPool(_fuzz.poolAmountOut, maxAmountsIn);
  }

  function test_Revert_NotFinalized() public view {}

  function test_Revert_MathApprox() public view {}

  function test_Revert_TokenArrayMathApprox() public view {}

  function test_Revert_TokenArrayLimitIn() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_TokenArrayBalance() public view {}

  function test_Emit_TokenArrayLogJoin() public view {}

  function test_Pull_TokenArrayTokenAmountIn() public view {}

  function test_Mint_PoolShare() public view {}

  function test_Push_PoolShare() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_ExitPool is Base {
  function test_Revert_NotFinalized() public view {}

  function test_Revert_MathApprox() public view {}

  function test_Pull_PoolShare() public view {}

  function test_Push_PoolShare() public view {}

  function test_Burn_PoolShare() public view {}

  function test_Revert_TokenArrayMathApprox() public view {}

  function test_Revert_TokenArrayLimitOut() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_TokenArrayBalance() public view {}

  function test_Emit_TokenArrayLogExit() public view {}

  function test_Push_TokenArrayTokenAmountOut() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_SwapExactAmountIn is Base {
  function test_Revert_NotBoundTokenIn() public view {}

  function test_Revert_NotBoundTokenOut() public view {}

  function test_Revert_NotPublic() public view {}

  function test_Revert_MaxInRatio() public view {}

  function test_Revert_BadLimitPrice() public view {}

  function test_Revert_LimitOut() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_InRecord() public view {}

  function test_Set_OutRecord() public view {}

  function test_Revert_MathApprox() public view {}

  function test_Revert_LimitPrice() public view {}

  function test_Revert_MathApprox2() public view {}

  function test_Emit_LogSwap() public view {}

  function test_Pull_TokenAmountIn() public view {}

  function test_Push_TokenAmountOut() public view {}

  function test_Returns_AmountAndPrice() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_SwapExactAmountOut is Base {
  function test_Revert_NotBoundTokenIn() public view {}

  function test_Revert_NotBoundTokenOut() public view {}

  function test_Revert_NotPublic() public view {}

  function test_Revert_MaxOutRatio() public view {}

  function test_Revert_BadLimitPrice() public view {}

  function test_Revert_LimitIn() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_InRecord() public view {}

  function test_Set_OutRecord() public view {}

  function test_Revert_MathApprox() public view {}

  function test_Revert_LimitPrice() public view {}

  function test_Revert_MathApprox2() public view {}

  function test_Emit_LogSwap() public view {}

  function test_Pull_TokenAmountIn() public view {}

  function test_Push_TokenAmountOut() public view {}

  function test_Returns_AmountAndPrice() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_JoinswapExternAmountIn is Base {
  function test_Revert_NotFinalized() public view {}

  function test_Revert_NotBound() public view {}

  function test_Revert_MaxInRatio() public view {}

  function test_Revert_LimitOut() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_Balance() public view {}

  function test_Emit_LogJoin() public view {}

  function test_Mint_PoolShare() public view {}

  function test_Push_PoolShare() public view {}

  function test_Pull_Underlying() public view {}

  function test_Returns_PoolAmountOut() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_JoinswapExternAmountOut is Base {
  function test_Revert_NotFinalized() public view {}

  function test_Revert_NotBound() public view {}

  function test_Revert_MaxApprox() public view {}

  function test_Revert_LimitIn() public view {}

  function test_Revert_MaxInRatio() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_Balance() public view {}

  function test_Emit_LogJoin() public view {}

  function test_Mint_PoolShare() public view {}

  function test_Push_PoolShare() public view {}

  function test_Pull_Underlying() public view {}

  function test_Returns_TokenAmountIn() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_ExitswapPoolAmountIn is Base {
  function test_Revert_NotFinalized() public view {}

  function test_Revert_NotBound() public view {}

  function test_Revert_LimitOut() public view {}

  function test_Revert_MaxOutRatio() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_Balance() public view {}

  function test_Emit_LogExit() public view {}

  function test_Pull_PoolShare() public view {}

  function test_Burn_PoolShare() public view {}

  function test_Push_PoolShare() public view {}

  function test_Push_Underlying() public view {}

  function test_Returns_TokenAmountOut() public view {}

  function test_Emit_LogCall() public view {}
}

contract BPool_Unit_ExitswapPoolAmountOut is Base {
  function test_Revert_NotFinalized() public view {}

  function test_Revert_NotBound() public view {}

  function test_Revert_MaxOutRatio() public view {}

  function test_Revert_MathApprox() public view {}

  function test_Revert_LimitIn() public view {}

  function test_Revert_Reentrancy() public view {}

  function test_Set_Balance() public view {}

  function test_Emit_LogExit() public view {}

  function test_Pull_PoolShare() public view {}

  function test_Burn_PoolShare() public view {}

  function test_Push_PoolShare() public view {}

  function test_Push_Underlying() public view {}

  function test_Returns_PoolAmountIn() public view {}

  function test_Emit_LogCall() public view {}
}
