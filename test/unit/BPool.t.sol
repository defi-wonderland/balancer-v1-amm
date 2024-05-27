// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BPool} from 'contracts/BPool.sol';
import {MockBPool} from 'test/smock/MockBPool.sol';

import {BConst} from 'contracts/BConst.sol';
import {BMath} from 'contracts/BMath.sol';
import {IERC20} from 'contracts/BToken.sol';
import {Test} from 'forge-std/Test.sol';
import {LibString} from 'solmate/utils/LibString.sol';
import {Pow} from 'test/utils/Pow.sol';
import {Utils} from 'test/utils/Utils.sol';

// TODO: remove once `private` keyword is removed in all test cases
/* solhint-disable */

abstract contract BasePoolTest is Test, BConst, Utils, BMath {
  using LibString for *;

  uint256 public constant TOKENS_AMOUNT = 3;

  MockBPool public bPool;
  address[TOKENS_AMOUNT] public tokens;

  // Deploy this external contract to perform a try-catch when calling bpow.
  // If the call fails, it means that the function overflowed, then we reject the fuzzed inputs
  Pow public pow = new Pow();

  function setUp() public {
    bPool = new MockBPool();

    // Create fake tokens
    for (uint256 i = 0; i < tokens.length; i++) {
      tokens[i] = makeAddr(i.toString());
    }
  }

  function _setRandomTokens(uint256 _length) internal returns (address[] memory _tokensToAdd) {
    _tokensToAdd = new address[](_length);
    for (uint256 i = 0; i < _length; i++) {
      _tokensToAdd[i] = makeAddr(i.toString());
    }
    _setTokens(_tokensToAdd);
  }

  // TODO: move tokens and this method to Utils.sol
  function _tokensToMemory() internal view returns (address[] memory _tokens) {
    _tokens = new address[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      _tokens[i] = tokens[i];
    }
  }

  function _maxAmountsArray() internal pure returns (uint256[] memory _maxAmounts) {
    _maxAmounts = new uint256[](TOKENS_AMOUNT);
    for (uint256 i = 0; i < TOKENS_AMOUNT; i++) {
      _maxAmounts[i] = type(uint256).max;
    }
  }

  function _zeroAmountsArray() internal view returns (uint256[] memory _zeroAmounts) {
    _zeroAmounts = new uint256[](tokens.length);
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

  function _setSwapFee(uint256 _swapFee) internal {
    bPool.set__swapFee(_swapFee);
  }

  function _setFinalize(bool _isFinalized) internal {
    bPool.set__finalized(_isFinalized);
  }

  function _setPoolBalance(address _user, uint256 _balance) internal {
    deal(address(bPool), _user, _balance, true);
  }

  function _setTotalSupply(uint256 _totalSupply) internal {
    _setPoolBalance(address(0), _totalSupply);
  }

  function _setTotalWeight(uint256 _totalWeight) internal {
    bPool.set__totalWeight(_totalWeight);
  }

  function _assumeCalcSpotPrice(
    uint256 _tokenInBalance,
    uint256 _tokenInDenorm,
    uint256 _tokenOutBalance,
    uint256 _tokenOutDenorm,
    uint256 _swapFee
  ) internal pure {
    vm.assume(_tokenInDenorm > 0);
    vm.assume(_tokenInBalance < type(uint256).max / BONE);
    vm.assume(_tokenInBalance * BONE < type(uint256).max - (_tokenInDenorm / 2));

    uint256 _numer = bdiv(_tokenInBalance, _tokenInDenorm);
    vm.assume(_tokenOutDenorm > 0);
    vm.assume(_tokenOutBalance < type(uint256).max / BONE);
    vm.assume(_tokenOutBalance * BONE < type(uint256).max - (_tokenOutDenorm / 2));

    uint256 _denom = bdiv(_tokenOutBalance, _tokenOutDenorm);
    vm.assume(_denom > 0);
    vm.assume(_numer < type(uint256).max / BONE);
    vm.assume(_numer * BONE < type(uint256).max - (_denom / 2));
    vm.assume(_swapFee <= BONE);

    uint256 _ratio = bdiv(_numer, _denom);
    vm.assume(bsub(BONE, _swapFee) > 0);

    uint256 _scale = bdiv(BONE, bsub(BONE, _swapFee));
    vm.assume(_ratio < type(uint256).max / _scale);
  }

  function _assumeCalcInGivenOut(
    uint256 _tokenOutDenorm,
    uint256 _tokenInDenorm,
    uint256 _tokenOutBalance,
    uint256 _tokenAmountOut,
    uint256 _tokenInBalance
  ) internal pure {
    uint256 _weightRatio = bdiv(_tokenOutDenorm, _tokenInDenorm);
    uint256 _diff = bsub(_tokenOutBalance, _tokenAmountOut);
    uint256 _y = bdiv(_tokenOutBalance, _diff);
    uint256 _foo = bpow(_y, _weightRatio);
    vm.assume(bsub(_foo, BONE) < type(uint256).max / _tokenInBalance);
  }

  function _assumeCalcOutGivenIn(
    uint256 _tokenInBalance,
    uint256 _tokenInDenorm,
    uint256 _tokenOutBalance,
    uint256 _tokenOutDenorm,
    uint256 _tokenAmountIn,
    uint256 _swapFee
  ) internal pure {
    uint256 _adjustedIn = bsub(BONE, _swapFee);
    _adjustedIn = bmul(_tokenAmountIn, _adjustedIn);
    vm.assume(_tokenInBalance < type(uint256).max / BONE);
    vm.assume(_tokenInBalance * BONE < type(uint256).max - (badd(_tokenInBalance, _adjustedIn) / 2));
  }

  function _assumeCalcPoolOutGivenSingleIn(
    uint256 _tokenInDenorm,
    uint256 _tokenInBalance,
    uint256 _tokenAmountIn,
    uint256 _swapFee,
    uint256 _totalWeight,
    uint256 _totalSupply
  ) internal pure {
    uint256 _normalizedWeight = bdiv(_tokenInDenorm, _totalWeight);
    vm.assume(_normalizedWeight < BONE); // TODO: why this? if the weights are between allowed it should be fine

    uint256 _zaz = bmul(bsub(BONE, _normalizedWeight), _swapFee);
    uint256 _tokenAmountInAfterFee = bmul(_tokenAmountIn, bsub(BONE, _zaz));
    uint256 _newTokenBalanceIn = badd(_tokenInBalance, _tokenAmountInAfterFee);
    vm.assume(_newTokenBalanceIn < type(uint256).max / BONE);
    vm.assume(_newTokenBalanceIn > _tokenInBalance);

    uint256 _tokenInRatio = bdiv(_newTokenBalanceIn, _tokenInBalance);
    uint256 _poolRatio = bpow(_tokenInRatio, _normalizedWeight);
    vm.assume(_poolRatio < type(uint256).max / _totalSupply);
  }

  function _assumeCalcSingleInGivenPoolOut(
    uint256 _tokenInBalance,
    uint256 _tokenInDenorm,
    uint256 _poolSupply,
    uint256 _totalWeight,
    uint256 _poolAmountOut,
    uint256
  ) internal view {
    uint256 _normalizedWeight = bdiv(_tokenInDenorm, _totalWeight);
    uint256 _newPoolSupply = badd(_poolSupply, _poolAmountOut);
    vm.assume(_newPoolSupply < type(uint256).max / BONE);
    vm.assume(_newPoolSupply * BONE < type(uint256).max - (_poolSupply / 2)); // bdiv require

    uint256 _poolRatio = bdiv(_newPoolSupply, _poolSupply);
    vm.assume(_poolRatio < MAX_BPOW_BASE);
    vm.assume(BONE > _normalizedWeight);

    uint256 _boo = bdiv(BONE, _normalizedWeight);
    uint256 _tokenRatio;
    try pow.pow(_poolRatio, _boo) returns (uint256 _result) {
      // pow didn't overflow
      _tokenRatio = _result;
    } catch {
      // pow did an overflow. Reject this inputs
      vm.assume(false);
    }

    vm.assume(_tokenRatio < type(uint256).max / _tokenInBalance);
  }

  function _assumeCalcSingleOutGivenPoolIn(
    uint256 _tokenOutBalance,
    uint256 _tokenOutDenorm,
    uint256 _poolSupply,
    uint256 _totalWeight,
    uint256 _poolAmountIn,
    uint256 _swapFee
  ) internal pure {
    uint256 _normalizedWeight = bdiv(_tokenOutDenorm, _totalWeight);
    uint256 _exitFee = bsub(BONE, EXIT_FEE);
    vm.assume(_poolAmountIn < type(uint256).max / _exitFee);

    uint256 _poolAmountInAfterExitFee = bmul(_poolAmountIn, _exitFee);
    uint256 _newPoolSupply = bsub(_poolSupply, _poolAmountInAfterExitFee);
    vm.assume(_newPoolSupply < type(uint256).max / BONE);
    vm.assume(_newPoolSupply * BONE < type(uint256).max - (_poolSupply / 2)); // bdiv require

    uint256 _poolRatio = bdiv(_newPoolSupply, _poolSupply);
    vm.assume(_poolRatio < MAX_BPOW_BASE);
    vm.assume(BONE > _normalizedWeight);

    uint256 _tokenOutRatio = bpow(_poolRatio, bdiv(BONE, _normalizedWeight));
    vm.assume(_tokenOutRatio < type(uint256).max / _tokenOutBalance);

    uint256 _newTokenOutBalance = bmul(_tokenOutRatio, _tokenOutBalance);
    uint256 _tokenAmountOutBeforeSwapFee = bsub(_tokenOutBalance, _newTokenOutBalance);
    uint256 _zaz = bmul(bsub(BONE, _normalizedWeight), _swapFee);
    vm.assume(_tokenAmountOutBeforeSwapFee < type(uint256).max / bsub(BONE, _zaz));
  }

  function _assumeCalcPoolInGivenSingleOut(
    uint256 _tokenOutBalance,
    uint256 _tokenOutDenorm,
    uint256 _poolSupply,
    uint256 _totalWeight,
    uint256 _tokenAmountOut,
    uint256 _swapFee
  ) internal pure {
    uint256 _normalizedWeight = bdiv(_tokenOutDenorm, _totalWeight);
    vm.assume(BONE > _normalizedWeight);

    uint256 _zoo = bsub(BONE, _normalizedWeight);
    uint256 _zar = bmul(_zoo, _swapFee);
    uint256 _tokenAmountOutBeforeSwapFee = bdiv(_tokenAmountOut, bsub(BONE, _zar));
    uint256 _newTokenOutBalance = bsub(_tokenOutBalance, _tokenAmountOutBeforeSwapFee);
    vm.assume(_newTokenOutBalance < type(uint256).max / _tokenOutBalance);

    uint256 _tokenOutRatio = bdiv(_newTokenOutBalance, _tokenOutBalance);
    uint256 _poolRatio = bpow(_tokenOutRatio, _normalizedWeight);
    vm.assume(_poolRatio < type(uint256).max / _poolSupply);
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
  using LibString for *;

  function test_Returns_NumTokens(uint256 _tokensToAdd) public {
    vm.assume(_tokensToAdd > 0);
    vm.assume(_tokensToAdd <= MAX_BOUND_TOKENS);
    _setRandomTokens(_tokensToAdd);

    assertEq(bPool.getNumTokens(), _tokensToAdd);
  }
}

contract BPool_Unit_GetCurrentTokens is BasePoolTest {
  function test_Returns_CurrentTokens(uint256 _length) public {
    vm.assume(_length > 0);
    vm.assume(_length <= MAX_BOUND_TOKENS);
    address[] memory _tokensToAdd = _setRandomTokens(_length);

    assertEq(bPool.getCurrentTokens(), _tokensToAdd);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.getCurrentTokens();
  }
}

contract BPool_Unit_GetFinalTokens is BasePoolTest {
  function test_Returns_FinalTokens(uint256 _length) public {
    vm.assume(_length > 0);
    vm.assume(_length <= MAX_BOUND_TOKENS);
    address[] memory _tokensToAdd = _setRandomTokens(_length);
    _setFinalize(true);

    assertEq(bPool.getFinalTokens(), _tokensToAdd);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.getFinalTokens();
  }

  function test_Revert_NotFinalized(uint256 _length) public {
    vm.assume(_length > 0);
    vm.assume(_length <= MAX_BOUND_TOKENS);
    _setRandomTokens(_length);
    _setFinalize(false);

    vm.expectRevert('ERR_NOT_FINALIZED');
    bPool.getFinalTokens();
  }
}

contract BPool_Unit_GetDenormalizedWeight is BasePoolTest {
  function test_Returns_DenormalizedWeight(address _token, uint256 _weight) public {
    bPool.set__records(_token, BPool.Record({bound: true, index: 0, denorm: _weight, balance: 0}));

    assertEq(bPool.getDenormalizedWeight(_token), _weight);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.getDenormalizedWeight(address(0));
  }

  function test_Revert_NotBound(address _token) public {
    vm.expectRevert('ERR_NOT_BOUND');
    bPool.getDenormalizedWeight(_token);
  }
}

contract BPool_Unit_GetTotalDenormalizedWeight is BasePoolTest {
  function test_Returns_TotalDenormalizedWeight(uint256 _totalWeight) public {
    _setTotalWeight(_totalWeight);

    assertEq(bPool.getTotalDenormalizedWeight(), _totalWeight);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.getTotalDenormalizedWeight();
  }
}

contract BPool_Unit_GetNormalizedWeight is BasePoolTest {
  function test_Returns_NormalizedWeight(address _token, uint256 _weight, uint256 _totalWeight) public {
    _weight = bound(_weight, MIN_WEIGHT, MAX_WEIGHT);
    _totalWeight = bound(_totalWeight, MIN_WEIGHT, MAX_WEIGHT * MAX_BOUND_TOKENS);
    vm.assume(_weight < _totalWeight);
    _setRecord(_token, BPool.Record({bound: true, index: 0, denorm: _weight, balance: 0}));
    _setTotalWeight(_totalWeight);

    assertEq(bPool.getNormalizedWeight(_token), bdiv(_weight, _totalWeight));
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.getNormalizedWeight(address(0));
  }

  function test_Revert_NotBound(address _token) public {
    vm.expectRevert('ERR_NOT_BOUND');
    bPool.getNormalizedWeight(_token);
  }
}

contract BPool_Unit_GetBalance is BasePoolTest {
  function test_Returns_Balance(address _token, uint256 _balance) public {
    bPool.set__records(_token, BPool.Record({bound: true, index: 0, denorm: 0, balance: _balance}));

    assertEq(bPool.getBalance(_token), _balance);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.getBalance(address(0));
  }

  function test_Revert_NotBound(address _token) public {
    vm.expectRevert('ERR_NOT_BOUND');
    bPool.getBalance(_token);
  }
}

contract BPool_Unit_GetSwapFee is BasePoolTest {
  function test_Returns_SwapFee(uint256 _swapFee) public {
    _setSwapFee(_swapFee);

    assertEq(bPool.getSwapFee(), _swapFee);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.getSwapFee();
  }
}

contract BPool_Unit_GetController is BasePoolTest {
  function test_Returns_Controller(address _controller) public {
    bPool.set__controller(_controller);

    assertEq(bPool.getController(), _controller);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.getController();
  }
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
  function test_Revert_NotController(address _controller, address _caller) public {
    vm.assume(_controller != _caller);
    vm.assume(_caller != address(this));

    vm.prank(_caller);
    vm.expectRevert('ERR_NOT_CONTROLLER');
    bPool.finalize();
  }

  function test_Revert_Finalized() public {
    _setFinalize(true);

    vm.expectRevert('ERR_IS_FINALIZED');
    bPool.finalize();
  }

  function test_Revert_MinTokens(uint256 _tokensLength) public {
    _tokensLength = bound(_tokensLength, 0, MIN_BOUND_TOKENS - 1);
    _setRandomTokens(_tokensLength);

    vm.expectRevert('ERR_MIN_TOKENS');
    bPool.finalize();
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.finalize();
  }

  function test_Set_Finalize(uint256 _tokensLength) public {
    _tokensLength = bound(_tokensLength, MIN_BOUND_TOKENS, MAX_BOUND_TOKENS);
    _setRandomTokens(_tokensLength);

    bPool.finalize();

    assertEq(bPool.call__finalized(), true);
  }

  function test_Set_PublicSwap(uint256 _tokensLength) public {
    _tokensLength = bound(_tokensLength, MIN_BOUND_TOKENS, MAX_BOUND_TOKENS);
    _setRandomTokens(_tokensLength);

    bPool.finalize();

    assertEq(bPool.call__publicSwap(), true);
  }

  function test_Mint_InitPoolSupply(uint256 _tokensLength) public {
    _tokensLength = bound(_tokensLength, MIN_BOUND_TOKENS, MAX_BOUND_TOKENS);
    _setRandomTokens(_tokensLength);

    bPool.finalize();

    assertEq(bPool.totalSupply(), INIT_POOL_SUPPLY);
  }

  function test_Push_InitPoolSupply(uint256 _tokensLength) public {
    _tokensLength = bound(_tokensLength, MIN_BOUND_TOKENS, MAX_BOUND_TOKENS);
    _setRandomTokens(_tokensLength);

    bPool.finalize();

    assertEq(bPool.balanceOf(address(this)), INIT_POOL_SUPPLY);
  }

  function test_Emit_LogCall(uint256 _tokensLength) public {
    _tokensLength = bound(_tokensLength, MIN_BOUND_TOKENS, MAX_BOUND_TOKENS);
    _setRandomTokens(_tokensLength);

    vm.expectEmit(true, true, true, true);
    bytes memory _data = abi.encodeWithSelector(BPool.finalize.selector);
    emit BPool.LOG_CALL(BPool.finalize.selector, address(this), _data);

    bPool.finalize();
  }
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
  function test_Revert_NotBoundTokenIn(address _tokenIn, address _tokenOut) public {
    vm.expectRevert('ERR_NOT_BOUND');
    bPool.getSpotPrice(_tokenIn, _tokenOut);
  }

  function test_Revert_NotBoundTokenOut(address _tokenIn, address _tokenOut) public {
    _setRecord(_tokenIn, BPool.Record({bound: true, index: 0, denorm: 0, balance: 0}));

    vm.expectRevert('ERR_NOT_BOUND');
    bPool.getSpotPrice(_tokenIn, _tokenOut);
  }

  function test_Returns_SpotPrice(
    address _tokenIn,
    address _tokenOut,
    uint256 _tokenInBalance,
    uint256 _tokenInDenorm,
    uint256 _tokenOutBalance,
    uint256 _tokenOutDenorm,
    uint256 _swapFee
  ) public {
    vm.assume(_tokenIn != _tokenOut);
    _assumeCalcSpotPrice(_tokenInBalance, _tokenInDenorm, _tokenOutBalance, _tokenOutDenorm, _swapFee);

    _setRecord(_tokenIn, BPool.Record({bound: true, index: 0, denorm: _tokenInDenorm, balance: _tokenInBalance}));
    _setRecord(_tokenOut, BPool.Record({bound: true, index: 0, denorm: _tokenOutDenorm, balance: _tokenOutBalance}));
    _setSwapFee(_swapFee);

    uint256 _expectedSpotPrice =
      calcSpotPrice(_tokenInBalance, _tokenInDenorm, _tokenOutBalance, _tokenOutDenorm, _swapFee);
    uint256 _spotPrice = bPool.getSpotPrice(_tokenIn, _tokenOut);
    assertEq(_spotPrice, _expectedSpotPrice);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.getSpotPrice(address(0), address(0));
  }
}

contract BPool_Unit_GetSpotPriceSansFee is BasePoolTest {
  function test_Revert_NotBoundTokenIn(address _tokenIn, address _tokenOut) public {
    vm.expectRevert('ERR_NOT_BOUND');
    bPool.getSpotPriceSansFee(_tokenIn, _tokenOut);
  }

  function test_Revert_NotBoundTokenOut(address _tokenIn, address _tokenOut) public {
    _setRecord(_tokenIn, BPool.Record({bound: true, index: 0, denorm: 0, balance: 0}));

    vm.expectRevert('ERR_NOT_BOUND');
    bPool.getSpotPriceSansFee(_tokenIn, _tokenOut);
  }

  function test_Returns_SpotPrice(
    address _tokenIn,
    address _tokenOut,
    uint256 _tokenInBalance,
    uint256 _tokenInDenorm,
    uint256 _tokenOutBalance,
    uint256 _tokenOutDenorm
  ) public {
    vm.assume(_tokenIn != _tokenOut);
    _assumeCalcSpotPrice(_tokenInBalance, _tokenInDenorm, _tokenOutBalance, _tokenOutDenorm, 0);

    _setRecord(_tokenIn, BPool.Record({bound: true, index: 0, denorm: _tokenInDenorm, balance: _tokenInBalance}));
    _setRecord(_tokenOut, BPool.Record({bound: true, index: 0, denorm: _tokenOutDenorm, balance: _tokenOutBalance}));

    uint256 _expectedSpotPrice = calcSpotPrice(_tokenInBalance, _tokenInDenorm, _tokenOutBalance, _tokenOutDenorm, 0);
    uint256 _spotPrice = bPool.getSpotPriceSansFee(_tokenIn, _tokenOut);
    assertEq(_spotPrice, _expectedSpotPrice);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.getSpotPriceSansFee(address(0), address(0));
  }
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
    bPool.joinPool(_fuzz.poolAmountOut, _maxAmountsArray());
  }

  function test_Revert_NotFinalized(JoinPool_FuzzScenario memory _fuzz) public {
    _setFinalize(false);

    vm.expectRevert('ERR_NOT_FINALIZED');
    bPool.joinPool(_fuzz.poolAmountOut, new uint256[](tokens.length));
  }

  function test_Revert_MathApprox(JoinPool_FuzzScenario memory _fuzz, uint256 _poolAmountOut) public happyPath(_fuzz) {
    _poolAmountOut = bound(_poolAmountOut, 0, (INIT_POOL_SUPPLY / 2 / BONE) - 1); // bdiv rounds up

    vm.expectRevert('ERR_MATH_APPROX');
    bPool.joinPool(_poolAmountOut, new uint256[](tokens.length));
  }

  function test_Revert_TokenArrayMathApprox(JoinPool_FuzzScenario memory _fuzz, uint256 _tokenIndex) public {
    _assumeHappyPath(_fuzz);
    _tokenIndex = bound(_tokenIndex, 0, TOKENS_AMOUNT - 1);
    _fuzz.balance[_tokenIndex] = 0;
    _setValues(_fuzz);

    vm.expectRevert('ERR_MATH_APPROX');
    bPool.joinPool(_fuzz.poolAmountOut, _maxAmountsArray());
  }

  function test_Revert_TokenArrayLimitIn(JoinPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    vm.expectRevert('ERR_LIMIT_IN');
    bPool.joinPool(_fuzz.poolAmountOut, _zeroAmountsArray());
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.joinPool(0, _zeroAmountsArray());
  }

  function test_Set_TokenArrayBalance(JoinPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    bPool.joinPool(_fuzz.poolAmountOut, _maxAmountsArray());

    uint256 _poolTotal = _fuzz.initPoolSupply;
    uint256 _ratio = bdiv(_fuzz.poolAmountOut, _poolTotal);

    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 _bal = _fuzz.balance[i];
      uint256 _tokenAmountIn = bmul(_ratio, _bal);
      assertEq(bPool.getBalance(tokens[i]), _bal + _tokenAmountIn);
    }
  }

  function test_Emit_TokenArrayLogJoin(JoinPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _poolTotal = _fuzz.initPoolSupply;
    uint256 _ratio = bdiv(_fuzz.poolAmountOut, _poolTotal);

    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 _bal = _fuzz.balance[i];
      uint256 _tokenAmountIn = bmul(_ratio, _bal);
      vm.expectEmit(true, true, true, true);
      emit BPool.LOG_JOIN(address(this), tokens[i], _tokenAmountIn);
    }
    bPool.joinPool(_fuzz.poolAmountOut, _maxAmountsArray());
  }

  function test_Pull_TokenArrayTokenAmountIn(JoinPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _poolTotal = _fuzz.initPoolSupply;
    uint256 _ratio = bdiv(_fuzz.poolAmountOut, _poolTotal);

    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 _bal = _fuzz.balance[i];
      uint256 _tokenAmountIn = bmul(_ratio, _bal);
      vm.expectCall(
        address(tokens[i]),
        abi.encodeWithSelector(IERC20.transferFrom.selector, address(this), address(bPool), _tokenAmountIn)
      );
    }
    bPool.joinPool(_fuzz.poolAmountOut, _maxAmountsArray());
  }

  function test_Mint_PoolShare(JoinPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    bPool.joinPool(_fuzz.poolAmountOut, _maxAmountsArray());

    assertEq(bPool.totalSupply(), _fuzz.initPoolSupply + _fuzz.poolAmountOut);
  }

  function test_Push_PoolShare(JoinPool_FuzzScenario memory _fuzz, address _caller) public happyPath(_fuzz) {
    vm.assume(_caller != address(VM_ADDRESS));
    vm.assume(_caller != address(0));

    vm.prank(_caller);
    bPool.joinPool(_fuzz.poolAmountOut, _maxAmountsArray());

    assertEq(bPool.balanceOf(_caller), _fuzz.poolAmountOut);
  }

  function test_Emit_LogCall(JoinPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    vm.expectEmit(true, true, true, true);
    bytes memory _data = abi.encodeWithSelector(BPool.joinPool.selector, _fuzz.poolAmountOut, _maxAmountsArray());
    emit BPool.LOG_CALL(BPool.joinPool.selector, address(this), _data);

    bPool.joinPool(_fuzz.poolAmountOut, _maxAmountsArray());
  }
}

contract BPool_Unit_ExitPool is BasePoolTest {
  struct ExitPool_FuzzScenario {
    uint256 poolAmountIn;
    uint256 initPoolSupply;
    uint256[TOKENS_AMOUNT] balance;
  }

  function _setValues(ExitPool_FuzzScenario memory _fuzz) internal {
    // Create mocks
    for (uint256 i = 0; i < tokens.length; i++) {
      _mockTransfer(tokens[i]);
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

    // Set LP token balance
    _setPoolBalance(address(this), _fuzz.initPoolSupply); // give LP tokens to fn caller, update totalSupply
    // Set public swap
    _setPublicSwap(true);
    // Set finalize
    _setFinalize(true);
  }

  function _assumeHappyPath(ExitPool_FuzzScenario memory _fuzz) internal pure {
    uint256 _maxInitSupply = type(uint256).max / BONE;
    _fuzz.initPoolSupply = bound(_fuzz.initPoolSupply, INIT_POOL_SUPPLY, _maxInitSupply);

    uint256 _poolAmountInAfterFee = _fuzz.poolAmountIn - (_fuzz.poolAmountIn * EXIT_FEE);
    vm.assume(_poolAmountInAfterFee <= _fuzz.initPoolSupply);
    vm.assume(_poolAmountInAfterFee * BONE > _fuzz.initPoolSupply);

    uint256 _ratio = (_poolAmountInAfterFee * BONE) / _fuzz.initPoolSupply; // bdiv uses '* BONE'

    for (uint256 i = 0; i < _fuzz.balance.length; i++) {
      vm.assume(_fuzz.balance[i] >= BONE); // TODO: why not using MIN_BALANCE?
      vm.assume(_fuzz.balance[i] <= type(uint256).max / (_ratio * BONE));
    }
  }

  modifier happyPath(ExitPool_FuzzScenario memory _fuzz) {
    _assumeHappyPath(_fuzz);
    _setValues(_fuzz);
    _;
  }

  function test_HappyPath(ExitPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    bPool.exitPool(_fuzz.poolAmountIn, _zeroAmountsArray());
  }

  function test_Revert_NotFinalized() public {
    _setFinalize(false);

    vm.expectRevert('ERR_NOT_FINALIZED');
    bPool.exitPool(0, _zeroAmountsArray());
  }

  function test_Revert_MathApprox(ExitPool_FuzzScenario memory _fuzz, uint256 _poolAmountIn) public happyPath(_fuzz) {
    _poolAmountIn = bound(_poolAmountIn, 0, (INIT_POOL_SUPPLY / 2 / BONE) - 1); // bdiv rounds up

    vm.expectRevert('ERR_MATH_APPROX');
    bPool.exitPool(_poolAmountIn, _zeroAmountsArray());
  }

  function test_Pull_PoolShare(ExitPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    assertEq(bPool.balanceOf(address(this)), _fuzz.initPoolSupply);

    bPool.exitPool(_fuzz.poolAmountIn, _zeroAmountsArray());

    assertEq(bPool.balanceOf(address(this)), _fuzz.initPoolSupply - _fuzz.poolAmountIn);
  }

  function test_Push_PoolShare(ExitPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    address _factoryAddress = bPool.call__factory();
    uint256 _exitFee = bmul(_fuzz.poolAmountIn, EXIT_FEE);
    uint256 _balanceBefore = bPool.balanceOf(_factoryAddress);

    bPool.exitPool(_fuzz.poolAmountIn, _zeroAmountsArray());

    assertEq(bPool.balanceOf(_factoryAddress), _balanceBefore - _fuzz.poolAmountIn + _exitFee);
  }

  function test_Burn_PoolShare(ExitPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _exitFee = bmul(_fuzz.poolAmountIn, EXIT_FEE);
    uint256 _pAiAfterExitFee = bsub(_fuzz.poolAmountIn, _exitFee);
    uint256 _totalSupplyBefore = bPool.totalSupply();

    bPool.exitPool(_fuzz.poolAmountIn, _zeroAmountsArray());

    assertEq(bPool.totalSupply(), _totalSupplyBefore - _pAiAfterExitFee);
  }

  function test_Revert_TokenArrayMathApprox(
    ExitPool_FuzzScenario memory _fuzz,
    uint256 _tokenIndex
  ) public happyPath(_fuzz) {
    _assumeHappyPath(_fuzz);
    _tokenIndex = bound(_tokenIndex, 0, TOKENS_AMOUNT - 1);
    _fuzz.balance[_tokenIndex] = 0;
    _setValues(_fuzz);

    vm.expectRevert('ERR_MATH_APPROX');
    bPool.exitPool(_fuzz.poolAmountIn, _zeroAmountsArray());
  }

  function test_Revert_TokenArrayLimitOut(
    ExitPool_FuzzScenario memory _fuzz,
    uint256 _tokenIndex
  ) public happyPath(_fuzz) {
    _tokenIndex = bound(_tokenIndex, 0, TOKENS_AMOUNT - 1);

    uint256 _poolTotal = _fuzz.initPoolSupply;
    uint256 _exitFee = bmul(_fuzz.poolAmountIn, EXIT_FEE);
    uint256 _pAiAfterExitFee = bsub(_fuzz.poolAmountIn, _exitFee);
    uint256 _ratio = bdiv(_pAiAfterExitFee, _poolTotal);

    uint256[] memory _minAmounts = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 _bal = _fuzz.balance[i];
      uint256 _tokenAmountOut = bmul(_ratio, _bal);

      _minAmounts[i] = _tokenIndex == i ? _tokenAmountOut + 1 : _tokenAmountOut;
    }

    vm.expectRevert('ERR_LIMIT_OUT');
    bPool.exitPool(_fuzz.poolAmountIn, _minAmounts);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.exitPool(0, _zeroAmountsArray());
  }

  function test_Set_TokenArrayBalance(ExitPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256[] memory _balanceBefore = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      _balanceBefore[i] = bPool.getBalance(tokens[i]);
    }

    bPool.exitPool(_fuzz.poolAmountIn, _zeroAmountsArray());

    uint256 _exitFee = bmul(_fuzz.poolAmountIn, EXIT_FEE);
    uint256 _pAiAfterExitFee = bsub(_fuzz.poolAmountIn, _exitFee);
    uint256 _ratio = bdiv(_pAiAfterExitFee, _fuzz.initPoolSupply);

    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 _bal = _fuzz.balance[i];
      uint256 _tokenAmountOut = bmul(_ratio, _bal);
      assertEq(bPool.getBalance(tokens[i]), _balanceBefore[i] - _tokenAmountOut);
    }
  }

  function test_Emit_TokenArrayLogExit(ExitPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _exitFee = bmul(_fuzz.poolAmountIn, EXIT_FEE);
    uint256 _pAiAfterExitFee = bsub(_fuzz.poolAmountIn, _exitFee);
    uint256 _ratio = bdiv(_pAiAfterExitFee, _fuzz.initPoolSupply);

    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 _bal = _fuzz.balance[i];
      uint256 _tokenAmountOut = bmul(_ratio, _bal);
      vm.expectEmit(true, true, true, true);
      emit BPool.LOG_EXIT(address(this), tokens[i], _tokenAmountOut);
    }
    bPool.exitPool(_fuzz.poolAmountIn, _zeroAmountsArray());
  }

  function test_Push_TokenArrayTokenAmountOut(ExitPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _exitFee = bmul(_fuzz.poolAmountIn, EXIT_FEE);
    uint256 _pAiAfterExitFee = bsub(_fuzz.poolAmountIn, _exitFee);
    uint256 _ratio = bdiv(_pAiAfterExitFee, _fuzz.initPoolSupply);

    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 _bal = _fuzz.balance[i];
      uint256 _tokenAmountOut = bmul(_ratio, _bal);
      vm.expectCall(
        address(tokens[i]), abi.encodeWithSelector(IERC20.transfer.selector, address(this), _tokenAmountOut)
      );
    }
    bPool.exitPool(_fuzz.poolAmountIn, _zeroAmountsArray());
  }

  function test_Emit_LogCall(ExitPool_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    vm.expectEmit(true, true, true, true);
    bytes memory _data = abi.encodeWithSelector(BPool.exitPool.selector, _fuzz.poolAmountIn, _zeroAmountsArray());
    emit BPool.LOG_CALL(BPool.exitPool.selector, address(this), _data);

    bPool.exitPool(_fuzz.poolAmountIn, _zeroAmountsArray());
  }
}

contract BPool_Unit_SwapExactAmountIn is BasePoolTest {
  address tokenIn;
  address tokenOut;

  struct SwapExactAmountIn_FuzzScenario {
    uint256 tokenAmountIn;
    uint256 tokenInBalance;
    uint256 tokenInDenorm;
    uint256 tokenOutBalance;
    uint256 tokenOutDenorm;
    uint256 swapFee;
  }

  function _setValues(SwapExactAmountIn_FuzzScenario memory _fuzz) internal {
    tokenIn = tokens[0];
    tokenOut = tokens[1];

    // Create mocks for tokenIn and tokenOut (only use the first 2 tokens)
    _mockTransferFrom(tokenIn);
    _mockTransfer(tokenOut);

    // Set balances
    _setRecord(
      tokenIn,
      BPool.Record({
        bound: true,
        index: 0, // NOTE: irrelevant for this method
        denorm: _fuzz.tokenInDenorm,
        balance: _fuzz.tokenInBalance
      })
    );
    _setRecord(
      tokenOut,
      BPool.Record({
        bound: true,
        index: 0, // NOTE: irrelevant for this method
        denorm: _fuzz.tokenOutDenorm,
        balance: _fuzz.tokenOutBalance
      })
    );

    // Set swapFee
    _setSwapFee(_fuzz.swapFee);
    // Set public swap
    _setPublicSwap(true);
    // Set finalize
    _setFinalize(true);
  }

  function _assumeHappyPath(SwapExactAmountIn_FuzzScenario memory _fuzz) internal pure {
    // safe bound assumptions
    _fuzz.tokenInDenorm = bound(_fuzz.tokenInDenorm, MIN_WEIGHT, MAX_WEIGHT);
    _fuzz.tokenOutDenorm = bound(_fuzz.tokenOutDenorm, MIN_WEIGHT, MAX_WEIGHT);
    _fuzz.swapFee = bound(_fuzz.swapFee, MIN_FEE, MAX_FEE);

    // min
    vm.assume(_fuzz.tokenInBalance >= MIN_BALANCE);
    vm.assume(_fuzz.tokenOutBalance >= MIN_BALANCE);

    // max - calcSpotPrice (spotPriceBefore)
    vm.assume(_fuzz.tokenInBalance < type(uint256).max / _fuzz.tokenInDenorm);
    vm.assume(_fuzz.tokenOutBalance < type(uint256).max / _fuzz.tokenOutDenorm);

    // max - calcSpotPrice (spotPriceAfter)
    vm.assume(_fuzz.tokenAmountIn < type(uint256).max - _fuzz.tokenInBalance);
    vm.assume(_fuzz.tokenInBalance + _fuzz.tokenAmountIn < type(uint256).max / _fuzz.tokenInDenorm);

    // internal calculation for calcSpotPrice (spotPriceBefore)
    _assumeCalcSpotPrice(
      _fuzz.tokenInBalance, _fuzz.tokenInDenorm, _fuzz.tokenOutBalance, _fuzz.tokenOutDenorm, _fuzz.swapFee
    );

    // MAX_IN_RATIO
    vm.assume(_fuzz.tokenAmountIn <= bmul(_fuzz.tokenInBalance, MAX_IN_RATIO));

    // L338 BPool.sol
    uint256 _spotPriceBefore = calcSpotPrice(
      _fuzz.tokenInBalance, _fuzz.tokenInDenorm, _fuzz.tokenOutBalance, _fuzz.tokenOutDenorm, _fuzz.swapFee
    );

    _assumeCalcOutGivenIn(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.tokenAmountIn,
      _fuzz.swapFee
    );
    uint256 _tokenAmountOut = calcOutGivenIn(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.tokenAmountIn,
      _fuzz.swapFee
    );
    vm.assume(_tokenAmountOut > BONE);

    // internal calculation for calcSpotPrice (spotPriceAfter)
    _assumeCalcSpotPrice(
      _fuzz.tokenInBalance + _fuzz.tokenAmountIn,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance - _tokenAmountOut,
      _fuzz.tokenOutDenorm,
      _fuzz.swapFee
    );

    vm.assume(bmul(_spotPriceBefore, _tokenAmountOut) <= _fuzz.tokenAmountIn);
  }

  modifier happyPath(SwapExactAmountIn_FuzzScenario memory _fuzz) {
    _assumeHappyPath(_fuzz);
    _setValues(_fuzz);
    _;
  }

  function test_HappyPath(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _maxPrice = type(uint256).max;
    uint256 _minAmountOut = 0;
    bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, _minAmountOut, _maxPrice);
  }

  function test_Revert_NotBoundTokenIn(address _tokenIn) public {
    vm.assume(_tokenIn != VM_ADDRESS);

    vm.expectRevert('ERR_NOT_BOUND');
    bPool.swapExactAmountIn(_tokenIn, 0, tokenOut, 0, 0);
  }

  function test_Revert_NotBoundTokenOut(address _tokenOut) public {
    vm.assume(_tokenOut != VM_ADDRESS);

    vm.expectRevert('ERR_NOT_BOUND');
    bPool.swapExactAmountIn(tokenIn, 0, _tokenOut, 0, 0);
  }

  function test_Revert_NotPublic(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    _setPublicSwap(false);

    vm.expectRevert('ERR_SWAP_NOT_PUBLIC');
    bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, 0, type(uint256).max);
  }

  function test_Revert_MaxInRatio(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _tokenAmountIn = bmul(_fuzz.tokenInBalance, MAX_IN_RATIO) + 1;

    vm.expectRevert('ERR_MAX_IN_RATIO');
    bPool.swapExactAmountIn(tokenIn, _tokenAmountIn, tokenOut, 0, type(uint256).max);
  }

  function test_Revert_BadLimitPrice(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _spotPriceBefore = calcSpotPrice(
      _fuzz.tokenInBalance, _fuzz.tokenInDenorm, _fuzz.tokenOutBalance, _fuzz.tokenOutDenorm, _fuzz.swapFee
    );
    vm.assume(_spotPriceBefore > 0);

    vm.expectRevert('ERR_BAD_LIMIT_PRICE');
    bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, 0, _spotPriceBefore - 1);
  }

  function test_Revert_LimitOut(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _tokenAmountOut = calcOutGivenIn(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.tokenAmountIn,
      _fuzz.swapFee
    );

    vm.expectRevert('ERR_LIMIT_OUT');
    bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, _tokenAmountOut + 1, type(uint256).max);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.swapExactAmountIn(tokenIn, 0, tokenOut, 0, 0);
  }

  function test_Set_InRecord(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, 0, type(uint256).max);

    assertEq(bPool.getBalance(tokenIn), _fuzz.tokenInBalance + _fuzz.tokenAmountIn);
  }

  function test_Set_OutRecord(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    (uint256 _tokenAmountOut,) = bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, 0, type(uint256).max);

    assertEq(bPool.getBalance(tokenOut), _fuzz.tokenOutBalance - _tokenAmountOut);
  }

  function test_Revert_MathApprox() public {
    vm.skip(true);
    // TODO
  }

  function test_Revert_LimitPrice(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _tokenAmountOut = calcOutGivenIn(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.tokenAmountIn,
      _fuzz.swapFee
    );
    uint256 _spotPriceBefore = calcSpotPrice(
      _fuzz.tokenInBalance, _fuzz.tokenInDenorm, _fuzz.tokenOutBalance, _fuzz.tokenOutDenorm, _fuzz.swapFee
    );
    uint256 _spotPriceAfter = calcSpotPrice(
      _fuzz.tokenInBalance + _fuzz.tokenAmountIn,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance - _tokenAmountOut,
      _fuzz.tokenOutDenorm,
      _fuzz.swapFee
    );
    vm.assume(_spotPriceAfter > _spotPriceBefore);

    vm.expectRevert('ERR_LIMIT_PRICE');
    bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, 0, _spotPriceBefore);
  }

  function test_Revert_MathApprox2(SwapExactAmountIn_FuzzScenario memory _fuzz) public {
    // Replicating _assumeHappyPath, but removing irrelevant assumptions and conditioning the revert
    _fuzz.tokenInDenorm = bound(_fuzz.tokenInDenorm, MIN_WEIGHT, MAX_WEIGHT);
    _fuzz.tokenOutDenorm = bound(_fuzz.tokenOutDenorm, MIN_WEIGHT, MAX_WEIGHT);
    _fuzz.swapFee = bound(_fuzz.swapFee, MIN_FEE, MAX_FEE);
    vm.assume(_fuzz.tokenInBalance >= MIN_BALANCE);
    vm.assume(_fuzz.tokenOutBalance >= MIN_BALANCE);
    vm.assume(_fuzz.tokenInBalance < type(uint256).max / _fuzz.tokenInDenorm);
    vm.assume(_fuzz.tokenOutBalance < type(uint256).max / _fuzz.tokenOutDenorm);
    vm.assume(_fuzz.tokenAmountIn < type(uint256).max - _fuzz.tokenInBalance);
    vm.assume(_fuzz.tokenInBalance + _fuzz.tokenAmountIn < type(uint256).max / _fuzz.tokenInDenorm);
    _assumeCalcSpotPrice(
      _fuzz.tokenInBalance, _fuzz.tokenInDenorm, _fuzz.tokenOutBalance, _fuzz.tokenOutDenorm, _fuzz.swapFee
    );
    vm.assume(_fuzz.tokenAmountIn <= bmul(_fuzz.tokenInBalance, MAX_IN_RATIO));
    uint256 _spotPriceBefore = calcSpotPrice(
      _fuzz.tokenInBalance, _fuzz.tokenInDenorm, _fuzz.tokenOutBalance, _fuzz.tokenOutDenorm, _fuzz.swapFee
    );
    uint256 _tokenAmountOut = calcOutGivenIn(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.tokenAmountIn,
      _fuzz.swapFee
    );
    vm.assume(_tokenAmountOut > BONE);
    _assumeCalcSpotPrice(
      _fuzz.tokenInBalance + _fuzz.tokenAmountIn,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance - _tokenAmountOut,
      _fuzz.tokenOutDenorm,
      _fuzz.swapFee
    );
    vm.assume(_spotPriceBefore > bdiv(_fuzz.tokenAmountIn, _tokenAmountOut));

    _setValues(_fuzz);

    vm.expectRevert('ERR_MATH_APPROX');
    bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, 0, type(uint256).max);
  }

  function test_Emit_LogSwap(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _tokenAmountOut = calcOutGivenIn(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.tokenAmountIn,
      _fuzz.swapFee
    );

    vm.expectEmit(true, true, true, true);
    emit BPool.LOG_SWAP(address(this), tokenIn, tokenOut, _fuzz.tokenAmountIn, _tokenAmountOut);
    bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, 0, type(uint256).max);
  }

  function test_Pull_TokenAmountIn(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    vm.expectCall(
      address(tokenIn),
      abi.encodeWithSelector(IERC20.transferFrom.selector, address(this), address(bPool), _fuzz.tokenAmountIn)
    );
    bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, 0, type(uint256).max);
  }

  function test_Push_TokenAmountOut(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _tokenAmountOut = calcOutGivenIn(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.tokenAmountIn,
      _fuzz.swapFee
    );

    vm.expectCall(address(tokenOut), abi.encodeWithSelector(IERC20.transfer.selector, address(this), _tokenAmountOut));
    bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, 0, type(uint256).max);
  }

  function test_Returns_AmountAndPrice(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _expectedTokenAmountOut = calcOutGivenIn(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.tokenAmountIn,
      _fuzz.swapFee
    );
    uint256 _expectedSpotPriceAfter = calcSpotPrice(
      _fuzz.tokenInBalance + _fuzz.tokenAmountIn,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance - _expectedTokenAmountOut,
      _fuzz.tokenOutDenorm,
      _fuzz.swapFee
    );

    (uint256 _tokenAmountOut, uint256 _spotPriceAfter) =
      bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, 0, type(uint256).max);

    assertEq(_tokenAmountOut, _expectedTokenAmountOut);
    assertEq(_spotPriceAfter, _expectedSpotPriceAfter);
  }

  function test_Emit_LogCall(SwapExactAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    vm.expectEmit(true, true, true, true);
    bytes memory _data = abi.encodeWithSelector(
      BPool.swapExactAmountIn.selector, tokenIn, _fuzz.tokenAmountIn, tokenOut, 0, type(uint256).max
    );
    emit BPool.LOG_CALL(BPool.swapExactAmountIn.selector, address(this), _data);

    bPool.swapExactAmountIn(tokenIn, _fuzz.tokenAmountIn, tokenOut, 0, type(uint256).max);
  }
}

contract BPool_Unit_SwapExactAmountOut is BasePoolTest {
  address tokenIn;
  address tokenOut;

  struct SwapExactAmountOut_FuzzScenario {
    uint256 tokenAmountOut;
    uint256 tokenInBalance;
    uint256 tokenInDenorm;
    uint256 tokenOutBalance;
    uint256 tokenOutDenorm;
    uint256 swapFee;
  }

  function _setValues(SwapExactAmountOut_FuzzScenario memory _fuzz) internal {
    tokenIn = tokens[0];
    tokenOut = tokens[1];

    // Create mocks for tokenIn and tokenOut (only use the first 2 tokens)
    _mockTransferFrom(tokenIn);
    _mockTransfer(tokenOut);

    // Set balances
    _setRecord(
      tokenIn,
      BPool.Record({
        bound: true,
        index: 0, // NOTE: irrelevant for this method
        denorm: _fuzz.tokenInDenorm,
        balance: _fuzz.tokenInBalance
      })
    );
    _setRecord(
      tokenOut,
      BPool.Record({
        bound: true,
        index: 0, // NOTE: irrelevant for this method
        denorm: _fuzz.tokenOutDenorm,
        balance: _fuzz.tokenOutBalance
      })
    );

    // Set swapFee
    _setSwapFee(_fuzz.swapFee);
    // Set public swap
    _setPublicSwap(true);
    // Set finalize
    _setFinalize(true);
  }

  function _assumeHappyPath(SwapExactAmountOut_FuzzScenario memory _fuzz) internal pure {
    // safe bound assumptions
    _fuzz.tokenInDenorm = bound(_fuzz.tokenInDenorm, MIN_WEIGHT, MAX_WEIGHT);
    _fuzz.tokenOutDenorm = bound(_fuzz.tokenOutDenorm, MIN_WEIGHT, MAX_WEIGHT);
    _fuzz.swapFee = bound(_fuzz.swapFee, MIN_FEE, MAX_FEE);

    // min
    vm.assume(_fuzz.tokenInBalance >= MIN_BALANCE);
    vm.assume(_fuzz.tokenOutBalance >= MIN_BALANCE);

    // max - calcSpotPrice (spotPriceBefore)
    vm.assume(_fuzz.tokenInBalance < type(uint256).max / _fuzz.tokenInDenorm);
    vm.assume(_fuzz.tokenOutBalance < type(uint256).max / _fuzz.tokenOutDenorm);

    // max - calcSpotPrice (spotPriceAfter)
    vm.assume(_fuzz.tokenAmountOut < type(uint256).max - _fuzz.tokenOutBalance);
    vm.assume(_fuzz.tokenOutBalance + _fuzz.tokenAmountOut < type(uint256).max / _fuzz.tokenOutDenorm);

    // internal calculation for calcSpotPrice (spotPriceBefore)
    _assumeCalcSpotPrice(
      _fuzz.tokenInBalance, _fuzz.tokenInDenorm, _fuzz.tokenOutBalance, _fuzz.tokenOutDenorm, _fuzz.swapFee
    );

    // MAX_OUT_RATIO
    vm.assume(_fuzz.tokenAmountOut <= bmul(_fuzz.tokenOutBalance, MAX_OUT_RATIO));

    // L364 BPool.sol
    uint256 _spotPriceBefore = calcSpotPrice(
      _fuzz.tokenInBalance, _fuzz.tokenInDenorm, _fuzz.tokenOutBalance, _fuzz.tokenOutDenorm, _fuzz.swapFee
    );

    // internal calculation for calcInGivenOut
    _assumeCalcInGivenOut(
      _fuzz.tokenOutDenorm, _fuzz.tokenInDenorm, _fuzz.tokenOutBalance, _fuzz.tokenAmountOut, _fuzz.tokenInBalance
    );

    uint256 _tokenAmountIn = calcInGivenOut(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.tokenAmountOut,
      _fuzz.swapFee
    );

    vm.assume(_tokenAmountIn > BONE);
    vm.assume(bmul(_spotPriceBefore, _fuzz.tokenAmountOut) <= _tokenAmountIn);

    // max - calcSpotPrice (spotPriceAfter)
    vm.assume(_tokenAmountIn < type(uint256).max - _fuzz.tokenInBalance);
    vm.assume(_fuzz.tokenInBalance + _tokenAmountIn < type(uint256).max / _fuzz.tokenInDenorm);

    // internal calculation for calcSpotPrice (spotPriceAfter)
    _assumeCalcSpotPrice(
      _fuzz.tokenInBalance + _tokenAmountIn,
      _fuzz.tokenInDenorm,
      _fuzz.tokenOutBalance - _fuzz.tokenAmountOut,
      _fuzz.tokenOutDenorm,
      _fuzz.swapFee
    );
  }

  modifier happyPath(SwapExactAmountOut_FuzzScenario memory _fuzz) {
    _assumeHappyPath(_fuzz);
    _setValues(_fuzz);
    _;
  }

  function test_HappyPath(SwapExactAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _maxPrice = type(uint256).max;
    uint256 _maxAmountIn = type(uint256).max;
    bPool.swapExactAmountOut(tokenIn, _maxAmountIn, tokenOut, _fuzz.tokenAmountOut, _maxPrice);
  }

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
  address tokenIn;

  struct JoinswapExternAmountIn_FuzzScenario {
    uint256 tokenAmountIn;
    uint256 tokenInBalance;
    uint256 tokenInDenorm;
    uint256 totalSupply;
    uint256 totalWeight;
    uint256 swapFee;
  }

  function _setValues(JoinswapExternAmountIn_FuzzScenario memory _fuzz) internal {
    tokenIn = tokens[0];

    // Create mocks for tokenIn
    _mockTransferFrom(tokenIn);

    // Set balances
    _setRecord(
      tokenIn,
      BPool.Record({
        bound: true,
        index: 0, // NOTE: irrelevant for this method
        denorm: _fuzz.tokenInDenorm,
        balance: _fuzz.tokenInBalance
      })
    );

    // Set swapFee
    _setSwapFee(_fuzz.swapFee);
    // Set public swap
    _setPublicSwap(true);
    // Set finalize
    _setFinalize(true);
    // Set totalSupply
    _setTotalSupply(_fuzz.totalSupply);
    // Set totalWeight
    _setTotalWeight(_fuzz.totalWeight);
  }

  function _assumeHappyPath(JoinswapExternAmountIn_FuzzScenario memory _fuzz) internal pure {
    // safe bound assumptions
    _fuzz.tokenInDenorm = bound(_fuzz.tokenInDenorm, MIN_WEIGHT, MAX_WEIGHT);
    _fuzz.swapFee = bound(_fuzz.swapFee, MIN_FEE, MAX_FEE);
    _fuzz.totalWeight = bound(_fuzz.totalWeight, MIN_WEIGHT * MAX_BOUND_TOKENS, MAX_WEIGHT * MAX_BOUND_TOKENS);

    vm.assume(_fuzz.totalSupply >= INIT_POOL_SUPPLY);

    // min
    vm.assume(_fuzz.tokenInBalance >= MIN_BALANCE);

    // max
    vm.assume(_fuzz.tokenInBalance < type(uint256).max - _fuzz.tokenAmountIn);

    // MAX_IN_RATIO
    vm.assume(_fuzz.tokenInBalance < type(uint256).max / MAX_IN_RATIO);
    vm.assume(_fuzz.tokenAmountIn <= bmul(_fuzz.tokenInBalance, MAX_IN_RATIO));

    // internal calculation for calcPoolOutGivenSingleIn
    _assumeCalcPoolOutGivenSingleIn(
      _fuzz.tokenInDenorm,
      _fuzz.tokenInBalance,
      _fuzz.tokenAmountIn,
      _fuzz.swapFee,
      _fuzz.totalWeight,
      _fuzz.totalSupply
    );
  }

  modifier happyPath(JoinswapExternAmountIn_FuzzScenario memory _fuzz) {
    _assumeHappyPath(_fuzz);
    _setValues(_fuzz);
    _;
  }

  function test_HappyPath(JoinswapExternAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _minPoolAmountOut = 0;
    bPool.joinswapExternAmountIn(tokenIn, _fuzz.tokenAmountIn, _minPoolAmountOut);
  }

  function test_Revert_NotFinalized() public {
    _setFinalize(false);

    vm.expectRevert('ERR_NOT_FINALIZED');
    bPool.joinswapExternAmountIn(tokenIn, 0, 0);
  }

  function test_Revert_NotBound(
    JoinswapExternAmountIn_FuzzScenario memory _fuzz,
    address _tokenIn
  ) public happyPath(_fuzz) {
    vm.assume(_tokenIn != VM_ADDRESS);

    vm.expectRevert('ERR_NOT_BOUND');
    bPool.joinswapExternAmountIn(_tokenIn, 0, 0);
  }

  function test_Revert_MaxInRatio(JoinswapExternAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _tokenAmountIn = bmul(_fuzz.tokenInBalance, MAX_IN_RATIO);

    vm.expectRevert('ERR_MAX_IN_RATIO');
    bPool.joinswapExternAmountIn(tokenIn, _tokenAmountIn + 1, 0);
  }

  function test_Revert_LimitOut(JoinswapExternAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _poolAmountIn = calcPoolOutGivenSingleIn(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.tokenAmountIn,
      _fuzz.swapFee
    );

    vm.expectRevert('ERR_LIMIT_OUT');
    bPool.joinswapExternAmountIn(tokenIn, _fuzz.tokenAmountIn, _poolAmountIn + 1);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.joinswapExternAmountIn(tokenIn, 0, 0);
  }

  function test_Set_Balance(JoinswapExternAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    bPool.joinswapExternAmountIn(tokenIn, _fuzz.tokenAmountIn, 0);

    assertEq(bPool.getBalance(tokenIn), _fuzz.tokenInBalance + _fuzz.tokenAmountIn);
  }

  function test_Emit_LogJoin(JoinswapExternAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    vm.expectEmit(true, true, true, true);
    emit BPool.LOG_JOIN(address(this), tokenIn, _fuzz.tokenAmountIn);

    bPool.joinswapExternAmountIn(tokenIn, _fuzz.tokenAmountIn, 0);
  }

  function test_Mint_PoolShare(JoinswapExternAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    (uint256 _poolAmountOut) = bPool.joinswapExternAmountIn(tokenIn, _fuzz.tokenAmountIn, 0);

    assertEq(bPool.totalSupply(), _fuzz.totalSupply + _poolAmountOut);
  }

  function test_Push_PoolShare(JoinswapExternAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _balanceBefore = bPool.balanceOf(address(this));

    (uint256 _poolAmountOut) = bPool.joinswapExternAmountIn(tokenIn, _fuzz.tokenAmountIn, 0);

    assertEq(bPool.balanceOf(address(this)), _balanceBefore + _poolAmountOut);
  }

  function test_Pull_Underlying(JoinswapExternAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    vm.expectCall(
      address(tokenIn),
      abi.encodeWithSelector(IERC20.transferFrom.selector, address(this), address(bPool), _fuzz.tokenAmountIn)
    );
    bPool.joinswapExternAmountIn(tokenIn, _fuzz.tokenAmountIn, 0);
  }

  function test_Returns_PoolAmountOut(JoinswapExternAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _expectedPoolAmountOut = calcPoolOutGivenSingleIn(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.tokenAmountIn,
      _fuzz.swapFee
    );

    (uint256 _poolAmountOut) = bPool.joinswapExternAmountIn(tokenIn, _fuzz.tokenAmountIn, 0);

    assertEq(_poolAmountOut, _expectedPoolAmountOut);
  }

  function test_Emit_LogCall(JoinswapExternAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    vm.expectEmit(true, true, true, true);
    bytes memory _data = abi.encodeWithSelector(BPool.joinswapExternAmountIn.selector, tokenIn, _fuzz.tokenAmountIn, 0);
    emit BPool.LOG_CALL(BPool.joinswapExternAmountIn.selector, address(this), _data);

    bPool.joinswapExternAmountIn(tokenIn, _fuzz.tokenAmountIn, 0);
  }
}

contract BPool_Unit_JoinswapPoolAmountOut is BasePoolTest {
  address tokenIn;

  struct JoinswapPoolAmountOut_FuzzScenario {
    uint256 poolAmountOut;
    uint256 tokenInBalance;
    uint256 tokenInDenorm;
    uint256 totalSupply;
    uint256 totalWeight;
    uint256 swapFee;
  }

  function _setValues(JoinswapPoolAmountOut_FuzzScenario memory _fuzz) internal {
    tokenIn = tokens[0];

    // Create mocks for tokenIn
    _mockTransferFrom(tokenIn);

    // Set balances
    _setRecord(
      tokenIn,
      BPool.Record({
        bound: true,
        index: 0, // NOTE: irrelevant for this method
        denorm: _fuzz.tokenInDenorm,
        balance: _fuzz.tokenInBalance
      })
    );

    // Set swapFee
    _setSwapFee(_fuzz.swapFee);
    // Set public swap
    _setPublicSwap(true);
    // Set finalize
    _setFinalize(true);
    // Set totalSupply
    _setTotalSupply(_fuzz.totalSupply);
    // Set totalWeight
    _setTotalWeight(_fuzz.totalWeight);
  }

  function _assumeHappyPath(JoinswapPoolAmountOut_FuzzScenario memory _fuzz) internal view {
    // safe bound assumptions
    _fuzz.tokenInDenorm = bound(_fuzz.tokenInDenorm, MIN_WEIGHT, MAX_WEIGHT);
    _fuzz.swapFee = bound(_fuzz.swapFee, MIN_FEE, MAX_FEE);
    _fuzz.totalWeight = bound(_fuzz.totalWeight, MIN_WEIGHT * MAX_BOUND_TOKENS, MAX_WEIGHT * MAX_BOUND_TOKENS);

    // min
    vm.assume(_fuzz.totalSupply >= INIT_POOL_SUPPLY);

    // max
    vm.assume(_fuzz.totalSupply < type(uint256).max - _fuzz.poolAmountOut);

    // min
    vm.assume(_fuzz.tokenInBalance >= MIN_BALANCE);

    // internal calculation for calcSingleInGivenPoolOut
    _assumeCalcSingleInGivenPoolOut(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.poolAmountOut,
      _fuzz.swapFee
    );

    uint256 _tokenAmountIn = calcSingleInGivenPoolOut(
      _fuzz.tokenInBalance,
      _fuzz.tokenInDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.poolAmountOut,
      _fuzz.swapFee
    );

    // L428 BPool.sol
    vm.assume(_tokenAmountIn > 0);

    // max
    vm.assume(_fuzz.tokenInBalance < type(uint256).max - _tokenAmountIn);

    // MAX_IN_RATIO
    vm.assume(_fuzz.tokenInBalance < type(uint256).max / MAX_IN_RATIO);
    vm.assume(_tokenAmountIn <= bmul(_fuzz.tokenInBalance, MAX_IN_RATIO));
  }

  modifier happyPath(JoinswapPoolAmountOut_FuzzScenario memory _fuzz) {
    _assumeHappyPath(_fuzz);
    _setValues(_fuzz);
    _;
  }

  function test_HappyPath(JoinswapPoolAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _maxAmountIn = type(uint256).max;
    bPool.joinswapPoolAmountOut(tokenIn, _fuzz.poolAmountOut, _maxAmountIn);
  }

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
  address tokenOut;

  struct ExitswapPoolAmountIn_FuzzScenario {
    uint256 poolAmountIn;
    uint256 tokenOutBalance;
    uint256 tokenOutDenorm;
    uint256 totalSupply;
    uint256 totalWeight;
    uint256 swapFee;
  }

  function _setValues(ExitswapPoolAmountIn_FuzzScenario memory _fuzz) internal {
    tokenOut = tokens[0];

    // Create mocks for tokenOut
    _mockTransfer(tokenOut);

    // Set balances
    _setRecord(
      tokenOut,
      BPool.Record({
        bound: true,
        index: 0, // NOTE: irrelevant for this method
        denorm: _fuzz.tokenOutDenorm,
        balance: _fuzz.tokenOutBalance
      })
    );

    // Set swapFee
    _setSwapFee(_fuzz.swapFee);
    // Set public swap
    _setPublicSwap(true);
    // Set finalize
    _setFinalize(true);
    // Set balance
    _setPoolBalance(address(this), _fuzz.poolAmountIn); // give LP tokens to fn caller
    // Set totalSupply
    _setTotalSupply(_fuzz.totalSupply - _fuzz.poolAmountIn);
    // Set totalWeight
    _setTotalWeight(_fuzz.totalWeight);
  }

  function _assumeHappyPath(ExitswapPoolAmountIn_FuzzScenario memory _fuzz) internal pure {
    // safe bound assumptions
    _fuzz.tokenOutDenorm = bound(_fuzz.tokenOutDenorm, MIN_WEIGHT, MAX_WEIGHT);
    _fuzz.swapFee = bound(_fuzz.swapFee, MIN_FEE, MAX_FEE);
    _fuzz.totalWeight = bound(_fuzz.totalWeight, MIN_WEIGHT * MAX_BOUND_TOKENS, MAX_WEIGHT * MAX_BOUND_TOKENS);

    // min
    vm.assume(_fuzz.totalSupply >= INIT_POOL_SUPPLY);

    // max
    vm.assume(_fuzz.poolAmountIn < _fuzz.totalSupply);
    vm.assume(_fuzz.totalSupply < type(uint256).max - _fuzz.poolAmountIn);

    // min
    vm.assume(_fuzz.tokenOutBalance >= MIN_BALANCE);

    // internal calculation for calcSingleOutGivenPoolIn
    _assumeCalcSingleOutGivenPoolIn(
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.poolAmountIn,
      _fuzz.swapFee
    );

    uint256 _tokenAmountOut = calcSingleOutGivenPoolIn(
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.poolAmountIn,
      _fuzz.swapFee
    );

    // max
    vm.assume(_fuzz.tokenOutBalance < type(uint256).max - _tokenAmountOut);

    // MAX_OUT_RATIO
    vm.assume(_fuzz.tokenOutBalance < type(uint256).max / MAX_OUT_RATIO);
    vm.assume(_tokenAmountOut <= bmul(_fuzz.tokenOutBalance, MAX_OUT_RATIO));
  }

  modifier happyPath(ExitswapPoolAmountIn_FuzzScenario memory _fuzz) {
    _assumeHappyPath(_fuzz);
    _setValues(_fuzz);
    _;
  }

  function test_HappyPath(ExitswapPoolAmountIn_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _minAmountOut = 0;
    bPool.exitswapPoolAmountIn(tokenOut, _fuzz.poolAmountIn, _minAmountOut);
  }

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

contract BPool_Unit_ExitswapExternAmountOut is BasePoolTest {
  address tokenOut;

  struct ExitswapExternAmountOut_FuzzScenario {
    uint256 tokenAmountOut;
    uint256 tokenOutBalance;
    uint256 tokenOutDenorm;
    uint256 totalSupply;
    uint256 totalWeight;
    uint256 swapFee;
  }

  function _setValues(ExitswapExternAmountOut_FuzzScenario memory _fuzz, uint256 _poolAmountIn) internal {
    tokenOut = tokens[0];

    // Create mocks for tokenOut
    _mockTransfer(tokenOut);

    // Set balances
    _setRecord(
      tokenOut,
      BPool.Record({
        bound: true,
        index: 0, // NOTE: irrelevant for this method
        denorm: _fuzz.tokenOutDenorm,
        balance: _fuzz.tokenOutBalance
      })
    );

    // Set swapFee
    _setSwapFee(_fuzz.swapFee);
    // Set public swap
    _setPublicSwap(true);
    // Set finalize
    _setFinalize(true);
    // Set balance
    _setPoolBalance(address(this), _poolAmountIn); // give LP tokens to fn caller
    // Set totalSupply
    _setTotalSupply(_fuzz.totalSupply - _poolAmountIn);
    // Set totalWeight
    _setTotalWeight(_fuzz.totalWeight);
  }

  function _assumeHappyPath(ExitswapExternAmountOut_FuzzScenario memory _fuzz)
    internal
    pure
    returns (uint256 _poolAmountIn)
  {
    // safe bound assumptions
    _fuzz.tokenOutDenorm = bound(_fuzz.tokenOutDenorm, MIN_WEIGHT, MAX_WEIGHT);
    _fuzz.swapFee = bound(_fuzz.swapFee, MIN_FEE, MAX_FEE);
    _fuzz.totalWeight = bound(_fuzz.totalWeight, MIN_WEIGHT * MAX_BOUND_TOKENS, MAX_WEIGHT * MAX_BOUND_TOKENS);

    // min
    vm.assume(_fuzz.totalSupply >= INIT_POOL_SUPPLY);

    // MAX_OUT_RATIO
    vm.assume(_fuzz.tokenOutBalance < type(uint256).max / MAX_OUT_RATIO);
    vm.assume(_fuzz.tokenAmountOut <= bmul(_fuzz.tokenOutBalance, MAX_OUT_RATIO));

    // min
    vm.assume(_fuzz.tokenOutBalance >= MIN_BALANCE);

    // max
    vm.assume(_fuzz.tokenOutBalance < type(uint256).max - _fuzz.tokenAmountOut);

    // internal calculation for calcPoolInGivenSingleOut
    _assumeCalcPoolInGivenSingleOut(
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.tokenAmountOut,
      _fuzz.swapFee
    );

    _poolAmountIn = calcPoolInGivenSingleOut(
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.tokenAmountOut,
      _fuzz.swapFee
    );

    // min
    vm.assume(_poolAmountIn > 0);

    // max
    vm.assume(_poolAmountIn < _fuzz.totalSupply);
    vm.assume(_fuzz.totalSupply < type(uint256).max - _poolAmountIn);
  }

  modifier happyPath(ExitswapExternAmountOut_FuzzScenario memory _fuzz) {
    uint256 _poolAmountIn = _assumeHappyPath(_fuzz);
    _setValues(_fuzz, _poolAmountIn);
    _;
  }

  function test_HappyPath(ExitswapExternAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _maxPoolAmountIn = type(uint256).max;
    bPool.exitswapExternAmountOut(tokenOut, _fuzz.tokenAmountOut, _maxPoolAmountIn);
  }

  function test_Revert_NotFinalized() public {
    _setFinalize(false);

    vm.expectRevert('ERR_NOT_FINALIZED');
    bPool.exitswapExternAmountOut(tokenOut, 0, 0);
  }

  function test_Revert_NotBound(
    ExitswapExternAmountOut_FuzzScenario memory _fuzz,
    address _tokenOut
  ) public happyPath(_fuzz) {
    vm.assume(_tokenOut != VM_ADDRESS);

    vm.expectRevert('ERR_NOT_BOUND');
    bPool.exitswapExternAmountOut(_tokenOut, 0, 0);
  }

  function test_Revert_MaxOutRatio(ExitswapExternAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _maxTokenAmountOut = bmul(_fuzz.tokenOutBalance, MAX_OUT_RATIO);

    vm.expectRevert('ERR_MAX_OUT_RATIO');
    bPool.exitswapExternAmountOut(tokenOut, _maxTokenAmountOut + 1, type(uint256).max);
  }

  function test_Revert_MathApprox(ExitswapExternAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    _fuzz.tokenAmountOut = 0;

    vm.expectRevert('ERR_MATH_APPROX');
    bPool.exitswapExternAmountOut(tokenOut, _fuzz.tokenAmountOut, type(uint256).max);
  }

  function test_Revert_LimitIn(ExitswapExternAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _poolAmountIn = calcPoolInGivenSingleOut(
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.tokenAmountOut,
      _fuzz.swapFee
    );

    vm.expectRevert('ERR_LIMIT_IN');
    bPool.exitswapExternAmountOut(tokenOut, _fuzz.tokenAmountOut, _poolAmountIn - 1);
  }

  function test_Revert_Reentrancy() public {
    // Assert that the contract is accesible
    assertEq(bPool.call__mutex(), false);

    // Simulate ongoing call to the contract
    bPool.set__mutex(true);

    vm.expectRevert('ERR_REENTRY');
    bPool.exitswapExternAmountOut(tokenOut, 0, 0);
  }

  function test_Set_Balance(ExitswapExternAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    bPool.exitswapExternAmountOut(tokenOut, _fuzz.tokenAmountOut, type(uint256).max);

    assertEq(bPool.getBalance(tokenOut), _fuzz.tokenOutBalance - _fuzz.tokenAmountOut);
  }

  function test_Emit_LogExit(ExitswapExternAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    vm.expectEmit(true, true, true, true);
    emit BPool.LOG_EXIT(address(this), tokenOut, _fuzz.tokenAmountOut);

    bPool.exitswapExternAmountOut(tokenOut, _fuzz.tokenAmountOut, type(uint256).max);
  }

  function test_Pull_PoolShare(ExitswapExternAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _balanceBefore = bPool.balanceOf(address(this));
    uint256 _poolAmountIn = calcPoolInGivenSingleOut(
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.tokenAmountOut,
      _fuzz.swapFee
    );
    uint256 _exitFee = bmul(_poolAmountIn, EXIT_FEE);

    bPool.exitswapExternAmountOut(tokenOut, _fuzz.tokenAmountOut, type(uint256).max);

    assertEq(bPool.balanceOf(address(this)), _balanceBefore - bsub(_poolAmountIn, _exitFee));
  }

  function test_Burn_PoolShare(ExitswapExternAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _totalSupplyBefore = bPool.totalSupply();
    uint256 _poolAmountIn = calcPoolInGivenSingleOut(
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.tokenAmountOut,
      _fuzz.swapFee
    );
    uint256 _exitFee = bmul(_poolAmountIn, EXIT_FEE);

    bPool.exitswapExternAmountOut(tokenOut, _fuzz.tokenAmountOut, type(uint256).max);

    assertEq(bPool.totalSupply(), _totalSupplyBefore - bsub(_poolAmountIn, _exitFee));
  }

  function test_Push_PoolShare(ExitswapExternAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    address _factoryAddress = bPool.call__factory();
    uint256 _balanceBefore = bPool.balanceOf(_factoryAddress);
    uint256 _poolAmountIn = calcPoolInGivenSingleOut(
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.tokenAmountOut,
      _fuzz.swapFee
    );
    uint256 _exitFee = bmul(_poolAmountIn, EXIT_FEE);

    bPool.exitswapExternAmountOut(tokenOut, _fuzz.tokenAmountOut, type(uint256).max);

    assertEq(bPool.balanceOf(_factoryAddress), _balanceBefore - _poolAmountIn + _exitFee);
  }

  function test_Push_Underlying(ExitswapExternAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    vm.expectCall(
      address(tokenOut), abi.encodeWithSelector(IERC20.transfer.selector, address(this), _fuzz.tokenAmountOut)
    );
    bPool.exitswapExternAmountOut(tokenOut, _fuzz.tokenAmountOut, type(uint256).max);
  }

  function test_Returns_PoolAmountIn(ExitswapExternAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    uint256 _expectedPoolAmountIn = calcPoolInGivenSingleOut(
      _fuzz.tokenOutBalance,
      _fuzz.tokenOutDenorm,
      _fuzz.totalSupply,
      _fuzz.totalWeight,
      _fuzz.tokenAmountOut,
      _fuzz.swapFee
    );

    (uint256 _poolAmountIn) = bPool.exitswapExternAmountOut(tokenOut, _fuzz.tokenAmountOut, type(uint256).max);

    assertEq(_expectedPoolAmountIn, _poolAmountIn);
  }

  function test_Emit_LogCall(ExitswapExternAmountOut_FuzzScenario memory _fuzz) public happyPath(_fuzz) {
    vm.expectEmit(true, true, true, true);
    bytes memory _data =
      abi.encodeWithSelector(BPool.exitswapExternAmountOut.selector, tokenOut, _fuzz.tokenAmountOut, type(uint256).max);
    emit BPool.LOG_CALL(BPool.exitswapExternAmountOut.selector, address(this), _data);

    bPool.exitswapExternAmountOut(tokenOut, _fuzz.tokenAmountOut, type(uint256).max);
  }
}
