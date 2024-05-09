// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BPool} from 'contracts/BPool.sol';
import {MockBPool} from 'test/smock/MockBPool.sol';

import {BConst} from 'contracts/BConst.sol';
import {IERC20} from 'contracts/BToken.sol';
import {Test} from 'forge-std/Test.sol';
import {LibString} from 'solmate/utils/LibString.sol';
import {Utils} from 'test/unit/Utils.sol';

// TODO: remove once `private` keyword is removed in all test cases
/* solhint-disable */

abstract contract BasePoolTest is Test, BConst, Utils {
  using LibString for *;

  uint256 public constant TOKENS_AMOUNT = 3;

  MockBPool public bPool;
  address[TOKENS_AMOUNT] public tokens;

  function setUp() public {
    bPool = new MockBPool();

    // Create fake tokens
    for (uint256 i = 0; i < tokens.length; i++) {
      tokens[i] = makeAddr(i.toString());
    }
  }

  // TODO: move tokens and this method to Utils.sol
  function _tokensToMemory() internal view returns (address[] memory _tokens) {
    _tokens = new address[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      _tokens[i] = tokens[i];
    }
  }

  function _mockTransfer(address _token) internal {
    // TODO: add amount to transfer to check that it's called with the right amount
    vm.mockCall(_token, abi.encodeWithSelector(IERC20(_token).transfer.selector), abi.encode(true));
  }

  function _mockTransferFrom(address _token) internal {
    // TODO: add from and amount to transfer to check that it's called with the right params
    vm.mockCall(_token, abi.encodeWithSelector(IERC20(_token).transferFrom.selector), abi.encode(true));
  }

  function _setTokens(address[] memory _tokens) internal {
    bPool.set__tokens(_tokens);
  }

  function _setRecord(address _token, BPool.Record memory _record) internal {
    bPool.set__records(_token, _record);
  }

  function _setPublicSwap(bool _isPublicSwap) internal {
    bPool.set__publicSwap(_isPublicSwap);
  }

  function _setFinalize(bool _isFinalized) internal {
    bPool.set__finalized(_isFinalized);
  }

  function _setTotalSupply(uint256 _totalSupply) internal {
    // NOTE: not in smock as it uses ERC20.totalSupply()
    _writeUintToStorage(address(bPool), 2, _totalSupply);
  }
}

contract BPool_Unit_Constructor is BasePoolTest {
  function test_Deploy() private view {}
}

contract BPool_Unit_IsPublicSwap is BasePoolTest {
  function test_Returns_IsPublicSwap() private view {}
}

contract BPool_Unit_IsFinalized is BasePoolTest {
  function test_Returns_IsFinalized() private view {}
}

contract BPool_Unit_IsBound is BasePoolTest {
  function test_Returns_IsBound() private view {}

  function test_Returns_IsNotBound() private view {}
}

contract BPool_Unit_GetNumTokens is BasePoolTest {
  function test_Returns_NumTokens() private view {}
}

contract BPool_Unit_GetCurrentTokens is BasePoolTest {
  function test_Returns_CurrentTokens() private view {}

  function test_Revert_Reentrancy() private view {}
}

contract BPool_Unit_GetFinalTokens is BasePoolTest {
  function test_Returns_FinalTokens() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Revert_NotFinalized() private view {}
}

contract BPool_Unit_GetDenormalizedWeight is BasePoolTest {
  function test_Returns_DenormalizedWeight() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Revert_NotBound() private view {}
}

contract BPool_Unit_GetTotalDenormalizedWeight is BasePoolTest {
  function test_Returns_TotalDenormalizedWeight() private view {}

  function test_Revert_Reentrancy() private view {}
}

contract BPool_Unit_GetNormalizedWeight is BasePoolTest {
  function test_Returns_NormalizedWeight() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Revert_NotBound() private view {}
}

contract BPool_Unit_GetBalance is BasePoolTest {
  function test_Returns_Balance() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Revert_NotBound() private view {}
}

contract BPool_Unit_GetSwapFee is BasePoolTest {
  function test_Returns_SwapFee() private view {}

  function test_Revert_Reentrancy() private view {}
}

contract BPool_Unit_GetController is BasePoolTest {
  function test_Returns_Controller() private view {}

  function test_Revert_Reentrancy() private view {}
}

contract BPool_Unit_SetSwapFee is BasePoolTest {
  function test_Revert_Finalized() private view {}

  function test_Revert_NotController() private view {}

  function test_Revert_MinFee() private view {}

  function test_Revert_MaxFee() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_SwapFee() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_SetController is BasePoolTest {
  function test_Revert_NotController() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_Controller() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_SetPublicSwap is BasePoolTest {
  function test_Revert_Finalized() private view {}

  function test_Revert_NotController() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_PublicSwap() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_Finalize is BasePoolTest {
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

contract BPool_Unit_Bind is BasePoolTest {
  function test_Revert_NotController() private view {}

  function test_Revert_IsBound() private view {}

  function test_Revert_Finalized() private view {}

  function test_Revert_MaxPoolTokens() private view {}

  function test_Set_Record() private view {}

  function test_Set_TokenArray() private view {}

  function test_Emit_LogCall() private view {}

  function test_Call_Rebind() private view {}
}

contract BPool_Unit_Rebind is BasePoolTest {
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

contract BPool_Unit_Unbind is BasePoolTest {
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

contract BPool_Unit_Gulp is BasePoolTest {
  function test_Revert_NotBound() private view {}

  function test_Revert_Reentrancy() private view {}

  function test_Set_Balance() private view {}

  function test_Emit_LogCall() private view {}
}

contract BPool_Unit_GetSpotPrice is BasePoolTest {
  function test_Revert_NotBoundTokenIn() private view {}

  function test_Revert_NotBoundTokenOut() private view {}

  function test_Returns_SpotPrice() private view {}

  function test_Revert_Reentrancy() private view {}
}

contract BPool_Unit_GetSpotPriceSansFee is BasePoolTest {
  function test_Revert_NotBoundTokenIn() private view {}

  function test_Revert_NotBoundTokenOut() private view {}

  function test_Returns_SpotPrice() private view {}

  function test_Revert_Reentrancy() private view {}
}

contract BPool_Unit_JoinPool is BasePoolTest {
  struct JoinPool_FuzzScenario {
    uint256 poolAmountOut;
    uint256 initPoolSupply;
    uint256[TOKENS_AMOUNT] balance;
  }

  function _setValues(JoinPool_FuzzScenario memory _fuzz) internal {
    // Create mocks
    for (uint256 i = 0; i < tokens.length; i++) {
      _mockTransfer(tokens[i]);
      _mockTransferFrom(tokens[i]);
    }

    // Set tokens
    _setTokens(_tokensToMemory());

    // Set balances
    for (uint256 i = 0; i < tokens.length; i++) {
      _setRecord(
        tokens[i],
        BPool.Record({
          bound: true,
          index: 0, // NOTE: irrelevant for this method
          denorm: 0, // NOTE: irrelevant for this method
          balance: _fuzz.balance[i]
        })
      );
    }

    // Set public swap
    _setPublicSwap(true);
    // Set finalize
    _setFinalize(true);
    // Set totalSupply
    _setTotalSupply(_fuzz.initPoolSupply);
  }

  function _assumeHappyPath(JoinPool_FuzzScenario memory _fuzz) internal pure {
    vm.assume(_fuzz.initPoolSupply >= INIT_POOL_SUPPLY);
    vm.assume(_fuzz.poolAmountOut >= _fuzz.initPoolSupply);
    vm.assume(_fuzz.poolAmountOut < type(uint256).max / BONE);

    uint256 _ratio = (_fuzz.poolAmountOut * BONE) / _fuzz.initPoolSupply; // bdiv uses '* BONE'
    uint256 _maxTokenAmountIn = type(uint256).max / _ratio;

    for (uint256 i = 0; i < _fuzz.balance.length; i++) {
      vm.assume(_fuzz.balance[i] >= MIN_BALANCE);
      vm.assume(_fuzz.balance[i] <= _maxTokenAmountIn); // L272
    }
  }

  modifier happyPath(JoinPool_FuzzScenario memory _fuzz) {
    _assumeHappyPath(_fuzz);
    _setValues(_fuzz);
    _;
  }

  function test_HappyPath(JoinPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256[] memory maxAmountsIn = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      maxAmountsIn[i] = type(uint256).max;
    } // Using max possible amounts

    bPool.joinPool(_fuzz.poolAmountOut, maxAmountsIn);
  }

  function test_Revert_NotFinalized(JoinPool_FuzzScenario memory _fuzz) public {
    _setFinalize(false);

    vm.expectRevert('ERR_NOT_FINALIZED');
    bPool.joinPool(_fuzz.poolAmountOut, new uint256[](tokens.length));
  }

  function test_Revert_MathApprox(JoinPool_FuzzScenario memory _fuzz, uint256 _poolAmountOut) public happyPath(_fuzz) {
    _poolAmountOut = bound(_poolAmountOut, 0, INIT_POOL_SUPPLY / 2 / BONE); // bdiv rounds up

    vm.expectRevert('ERR_MATH_APPROX');
    bPool.joinPool(_poolAmountOut, new uint256[](tokens.length));
  }

  function test_Revert_TokenArrayMathApprox(JoinPool_FuzzScenario memory _fuzz, uint256 _tokenIndex) public {
    // TODO: internalize this to _maxAmountsIn() -> uint256[] memory
    uint256[] memory maxAmountsIn = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      maxAmountsIn[i] = type(uint256).max;
    } // Using max possible amounts

    _assumeHappyPath(_fuzz);
    _tokenIndex = bound(_tokenIndex, 0, TOKENS_AMOUNT - 1);
    _fuzz.balance[_tokenIndex] = 0;
    // TODO: check range of failure
    // _fuzz.balance[_tokenIndex] = bound(_fuzz.balance[_tokenIndex], 0, BONE);
    _setValues(_fuzz);

    vm.expectRevert('ERR_MATH_APPROX');
    bPool.joinPool(_fuzz.poolAmountOut, maxAmountsIn);
  }

  function test_Revert_TokenArrayLimitIn() public {
    vm.skip(true);
  }

  function test_Revert_Reentrancy() public {
    vm.skip(true);
  }

  function test_Set_TokenArrayBalance() public {
    vm.skip(true);
  }

  function test_Emit_TokenArrayLogJoin() public {
    vm.skip(true);
  }

  function test_Pull_TokenArrayTokenAmountIn() public {
    vm.skip(true);
  }

  function test_Mint_PoolShare(JoinPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    // TODO: internalize this to _maxAmountsIn() -> uint256[] memory
    uint256[] memory maxAmountsIn = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      maxAmountsIn[i] = type(uint256).max;
    } // Using max possible amounts

    bPool.joinPool(_fuzz.poolAmountOut, maxAmountsIn);

    assertEq(bPool.totalSupply(), _fuzz.initPoolSupply + _fuzz.poolAmountOut);
  }

  function test_Push_PoolShare(JoinPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    // TODO: internalize this to _maxAmountsIn() -> uint256[] memory
    uint256[] memory maxAmountsIn = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      maxAmountsIn[i] = type(uint256).max;
    } // Using max possible amounts

    // TODO: prank a caller
    bPool.joinPool(_fuzz.poolAmountOut, maxAmountsIn);

    // TODO: specify minted amount to caller
    assertGt(bPool.balanceOf(address(this)), 0);
  }

  function test_Emit_LogCall() public {
    vm.skip(true);
  }
}

contract BPool_Unit_ExitPool is BasePoolTest {
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

contract BPool_Unit_SwapExactAmountIn is BasePoolTest {
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

contract BPool_Unit_SwapExactAmountOut is BasePoolTest {
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

contract BPool_Unit_JoinswapExternAmountIn is BasePoolTest {
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

contract BPool_Unit_JoinswapExternAmountOut is BasePoolTest {
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

contract BPool_Unit_ExitswapPoolAmountIn is BasePoolTest {
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

contract BPool_Unit_ExitswapPoolAmountOut is BasePoolTest {
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
