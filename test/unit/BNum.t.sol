// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BNum} from 'contracts/BNum.sol';
import {Test} from 'forge-std/Test.sol';

// For test contract: expose the internal functions of BNum
contract BNumExposed is BNum {
  function btoiExposed(uint256 a) external pure returns (uint256) {
    return btoi(a);
  }

  function bfloorExposed(uint256 a) external pure returns (uint256) {
    return bfloor(a);
  }

  function baddExposed(uint256 a, uint256 b) external pure returns (uint256) {
    return badd(a, b);
  }

  function bsubExposed(uint256 a, uint256 b) external pure returns (uint256) {
    return bsub(a, b);
  }

  function bsubSignExposed(uint256 a, uint256 b) external pure returns (uint256, bool) {
    return bsubSign(a, b);
  }

  function bmulExposed(uint256 a, uint256 b) external pure returns (uint256) {
    return bmul(a, b);
  }

  function bdivExposed(uint256 a, uint256 b) external pure returns (uint256) {
    return bdiv(a, b);
  }

  function bpowiExposed(uint256 a, uint256 n) external pure returns (uint256) {
    return bpowi(a, n);
  }

  function bpowExposed(uint256 base, uint256 exp) external pure returns (uint256) {
    return bpow(base, exp);
  }
}

// Test contract
contract BNumTest is Test {
  BNumExposed bNum;

  uint256 BONE;

  function setUp() public {
    bNum = new BNumExposed();
    BONE = bNum.BONE();
  }

  function test_BtoiWhenPassingZero() external {
    // Action
    uint256 _result = bNum.btoiExposed(0);

    // Post Condition
    // it should return zero
    assertEq(_result, 0);
  }

  function test_BtoiWhenPassingBONE() external {
    // Action
    uint256 _result = bNum.btoiExposed(BONE);

    // it should return one
    assertEq(_result, 1);
  }

  function test_BtoiWhenPassingAValueLessThanBONE(uint256 _a) external {
    // Preconditions
    _a = bound(_a, 0, BONE - 1);

    // Action
    uint256 _result = bNum.btoiExposed(_a);

    // it should return zero
    assertEq(_result, 0);
  }

  function test_BtoiWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BfloorWhenPassingZero() external {
    // Action
    uint256 _result = bNum.bfloorExposed(0);

    // Post Condition
    // it should return zero
    assertEq(_result, 0);
  }

  function test_BfloorWhenPassingAValueLessThanBONE(uint256 _a) external {
    // Preconditions
    _a = bound(_a, 0, BONE - 1);

    // Action
    uint256 _result = bNum.bfloorExposed(_a);

    // Post Condition
    // it should return zero
    assertEq(_result, 0);
  }

  function test_BfloorWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BaddWhenPassingZeroAndZero() external {
    // Action
    uint256 _result = bNum.baddExposed(0, 0);

    // Post Condition
    // it should return zero
    assertEq(_result, 0);
  }

  function test_BaddRevertWhen_PassingAAsUint256MaxAndBNonZero(uint256 _b) external {
    // Preconditions
    uint256 _a = type(uint256).max;
    _b = bound(_b, 1, type(uint256).max);

    // Post Condition
    // it should revert
    vm.expectRevert('ERR_ADD_OVERFLOW');

    // Action
    bNum.baddExposed(_a, _b);
  }

  function test_BaddRevertWhen_PassingBAsUint256MaxAndANonZero(uint256 _a) external {
    // Preconditions
    _a = bound(_a, 1, type(uint256).max);
    uint256 _b = type(uint256).max;

    // Post Condition
    // it should revert
    vm.expectRevert('ERR_ADD_OVERFLOW');

    // Action
    bNum.baddExposed(_a, _b);
  }

  function test_BaddWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BsubRevertWhen_PassingALessThanB(uint256 _a, uint256 _b) external {
    // Preconditions
    _a = bound(_a, 0, type(uint256).max - 1);
    _b = bound(_b, _a + 1, type(uint256).max);

    // Post Condition
    // it should revert
    vm.expectRevert('ERR_SUB_UNDERFLOW');

    // Action
    bNum.bsubExposed(_a, _b);
  }

  function test_BsubWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BsubSignWhenPassingZeroAndZero() external {
    // Action
    (uint256 _result, bool _flag) = bNum.bsubSignExposed(0, 0);

    // Post Condition
    // it should return zero and false
    assertEq(_result, 0);
    assertFalse(_flag);
  }

  function test_BsubSignWhenPassingALessThanB(uint256 _a, uint256 _b) external {
    // Preconditions
    _a = bound(_a, 0, type(uint256).max - 1);
    _b = bound(_b, _a + 1, type(uint256).max);

    // Action
    (uint256 _result, bool _flag) = bNum.bsubSignExposed(_a, _b);

    // Post Condition
    // it should return correct value and true
    assertEq(_result, _b - _a);
    assertTrue(_flag);
  }

  function test_BsubSignWhenPassingKnownValues() external {
    // Action
    (uint256 _result, bool _flag) = bNum.bsubSignExposed(5 * BONE, 3 * BONE);

    // Post Condition
    // it should return correct value
    assertEq(_result, 2 * BONE);
    assertFalse(_flag);
  }

  function test_BmulWhenPassingZeroAndZero() external {
    // Action
    uint256 _result = bNum.bmulExposed(0, 0);

    // Post Condition
    // it should return zero
    assertEq(_result, 0);
  }

  function test_BmulRevertWhen_PassingAAsUint256MaxAndBNonZero(uint256 _b) external {
    // Preconditions
    uint256 _a = type(uint256).max;
    _b = bound(_b, 1, type(uint256).max);

    // Post Condition
    // it should revert
    vm.expectRevert('ERR_MUL_OVERFLOW');

    // Action
    bNum.bmulExposed(_a, _b);
  }

  function test_BmulRevertWhen_PassingBAsUint256MaxAndANonZero(uint256 _a) external {
    // Preconditions
    _a = bound(_a, 1, type(uint256).max);
    uint256 _b = type(uint256).max;

    // Post Condition
    // it should revert
    vm.expectRevert('ERR_MUL_OVERFLOW');

    // Action
    bNum.bmulExposed(_a, _b);
  }

  function test_BmulWhenPassingAMulBTooBig(uint256 _a, uint256 _b) external {
    // Preconditions
    _a = bound(_a, type(uint256).max / 2, type(uint256).max);
    _b = bound(_b, type(uint256).max / 2, type(uint256).max);

    // Post Condition
    // it should revert
    //     a * b + BONE / 2 > uint256 max
    vm.expectRevert('ERR_MUL_OVERFLOW');

    // Action
    bNum.bmulExposed(_a, _b);
  }

  function test_BmulWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BdivRevertWhen_PassingBAsZero() external {
    // Post Condition
    // it should revert
    vm.expectRevert('ERR_DIV_ZERO');

    // Action
    bNum.bdivExposed(1, 0);
  }

  function test_BdivRevertWhen_PassingAAsUint256Max() external {
    // Post Condition
    // it should revert
    vm.expectRevert('ERR_DIV_INTERNAL');

    // Action
    bNum.bdivExposed(type(uint256).max, 1);
  }

  function test_BdivWhenPassingAAndBTooBig() external {
    // Preconditions
    uint256 _a = type(uint256).max;
    uint256 _b = BONE;

    // Post Condition
    // it should revert
    //     a*BONE/b + b/2 > uint256 max
    vm.expectRevert('ERR_DIV_INTERNAL');

    // Action
    bNum.bdivExposed(_a, _b);
  }

  function test_BDivWhenFlooringToZero(uint256 _a, uint256 _b) external {
    // Preconditions
    _a = bound(_a, 1, (type(uint256).max / (BONE * 2)) - 1);
    _b = bound(_b, (2 * BONE * _a) + 1, type(uint256).max);

    // Action
    uint256 _result = bNum.bdivExposed(_a, _b);

    // Post Condition
    // it should return 0
    assertEq(_result, 0);
  }

  function test_BdivWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BpowiWhenPassingAAsZero() external {
    // Action
    uint256 _result = bNum.bpowiExposed(0, 3);

    // Post Condition
    // it should return zero
    assertEq(_result, 0);
  }

  function test_BpowiWhenPassingBAsZero() external {
    // Action
    uint256 _result = bNum.bpowiExposed(3 * BONE, 0);

    // Post Condition
    // it should return BONE
    assertEq(_result, BONE);
  }

  function test_BpowiWhenPassingAAsOne() external {
    // Action
    uint256 _result = bNum.bpowiExposed(BONE, 3);

    // Post Condition
    // it should return BONE
    assertEq(_result, BONE);
  }

  function test_BpowiWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BpowWhenPassingExponentAsZero() external {
    // Action
    uint256 _result = bNum.bpowExposed(BONE, 0);

    // Post Condition
    // it should return BONE
    assertEq(_result, BONE);
  }

  function test_BpowRevertWhen_PassingBaseLteThanMIN_BPOW_BASE(uint256 _base) external {
    // Preconditions
    _base = bound(_base, 0, bNum.MIN_BPOW_BASE());

    // Post Condition
    // it should revert
    vm.expectRevert('ERR_BPOW_BASE_TOO_LOW');

    // Action
    bNum.bpowExposed(0, 3 * BONE);
  }

  function test_BpowRevertWhen_PassingBaseGteMAX_BPOW_BASE(uint256 _base) external {
    // Preconditions
    _base = bound(_base, bNum.MAX_BPOW_BASE(), type(uint256).max);

    // Post Condition
    // it should revert
    vm.expectRevert('ERR_BPOW_BASE_TOO_HIGH');

    // Action
    bNum.bpowExposed(type(uint256).max, 3 * BONE);
  }

  function test_BpowWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }
}
