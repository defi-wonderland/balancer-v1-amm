// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from 'forge-std/Test.sol';

abstract contract Base is Test {
  function setUp() public {}
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
