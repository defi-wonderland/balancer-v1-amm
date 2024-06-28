// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {BNum} from 'contracts/BNum.sol';
import {Test} from 'forge-std/Test.sol';
import {MockBNum} from 'test/smock/MockBNum.sol';

contract BNumTest is Test {
  MockBNum bNum;

  uint256 BONE;

  function setUp() public {
    bNum = new MockBNum();
    BONE = bNum.BONE();
  }

  function test_BtoiWhenPassingZero() external {
    uint256 _result = bNum.call_btoi(0);

    // it should return zero
    assertEq(_result, 0);
  }

  function test_BtoiWhenPassingBONE() external {
    uint256 _result = bNum.call_btoi(BONE);

    // it should return one
    assertEq(_result, 1);
  }

  function test_BtoiWhenPassingAValueLessThanBONE(uint256 _a) external {
    _a = bound(_a, 0, BONE - 1);

    uint256 _result = bNum.call_btoi(_a);

    // it should return zero
    assertEq(_result, 0);
  }

  function test_BtoiWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BfloorWhenPassingZero() external {
    uint256 _result = bNum.call_bfloor(0);

    // it should return zero
    assertEq(_result, 0);
  }

  function test_BfloorWhenPassingAValueLessThanBONE(uint256 _a) external {
    _a = bound(_a, 0, BONE - 1);

    uint256 _result = bNum.call_bfloor(_a);

    // it should return zero
    assertEq(_result, 0);
  }

  function test_BfloorWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BaddWhenPassingZeroAndZero() external {
    uint256 _result = bNum.call_badd(0, 0);

    // it should return zero
    assertEq(_result, 0);
  }

  function test_BaddRevertWhen_PassingAAsUint256MaxAndBNonZero(uint256 _b) external {
    uint256 _a = type(uint256).max;
    _b = bound(_b, 1, type(uint256).max);

    // it should revert
    vm.expectRevert(BNum.BNum_AddOverflow.selector);

    bNum.call_badd(_a, _b);
  }

  function test_BaddRevertWhen_PassingBAsUint256MaxAndANonZero(uint256 _a) external {
    _a = bound(_a, 1, type(uint256).max);
    uint256 _b = type(uint256).max;

    // it should revert
    vm.expectRevert(BNum.BNum_AddOverflow.selector);

    bNum.call_badd(_a, _b);
  }

  function test_BaddWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BsubRevertWhen_PassingALessThanB(uint256 _a, uint256 _b) external {
    _a = bound(_a, 0, type(uint256).max - 1);
    _b = bound(_b, _a + 1, type(uint256).max);

    // it should revert
    vm.expectRevert(BNum.BNum_SubUnderflow.selector);

    bNum.call_bsub(_a, _b);
  }

  function test_BsubWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BsubSignWhenPassingZeroAndZero() external {
    (uint256 _result, bool _flag) = bNum.call_bsubSign(0, 0);

    // it should return zero and false
    assertEq(_result, 0);
    assertFalse(_flag);
  }

  function test_BsubSignWhenPassingALessThanB(uint256 _a, uint256 _b) external {
    _a = bound(_a, 0, type(uint256).max - 1);
    _b = bound(_b, _a + 1, type(uint256).max);

    (uint256 _result, bool _flag) = bNum.call_bsubSign(_a, _b);

    // it should return correct value and true
    assertEq(_result, _b - _a);
    assertTrue(_flag);
  }

  function test_BsubSignWhenPassingKnownValues() external {
    (uint256 _result, bool _flag) = bNum.call_bsubSign(5 * BONE, 3 * BONE);

    // it should return correct value
    assertEq(_result, 2 * BONE);
    assertFalse(_flag);
  }

  function test_BmulWhenPassingZeroAndZero() external {
    uint256 _result = bNum.call_bmul(0, 0);

    // it should return zero
    assertEq(_result, 0);
  }

  function test_BmulRevertWhen_PassingAAsUint256MaxAndBNonZero(uint256 _b) external {
    uint256 _a = type(uint256).max;
    _b = bound(_b, 1, type(uint256).max);

    // it should revert
    vm.expectRevert(BNum.BNum_MulOverflow.selector);

    bNum.call_bmul(_a, _b);
  }

  function test_BmulRevertWhen_PassingBAsUint256MaxAndANonZero(uint256 _a) external {
    _a = bound(_a, 1, type(uint256).max);
    uint256 _b = type(uint256).max;

    // it should revert
    vm.expectRevert(BNum.BNum_MulOverflow.selector);

    bNum.call_bmul(_a, _b);
  }

  function test_BmulWhenPassingAMulBTooBig(uint256 _a, uint256 _b) external {
    _a = bound(_a, type(uint256).max / 2, type(uint256).max);
    _b = bound(_b, type(uint256).max / 2, type(uint256).max);

    // it should revert
    //     a * b + BONE / 2 > uint256 max
    vm.expectRevert(BNum.BNum_MulOverflow.selector);

    bNum.call_bmul(_a, _b);
  }

  function test_BmulWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BdivRevertWhen_PassingBAsZero() external {
    // it should revert
    vm.expectRevert(BNum.BNum_DivZero.selector);

    bNum.call_bdiv(1, 0);
  }

  function test_BdivRevertWhen_PassingAAsUint256Max() external {
    // it should revert
    vm.expectRevert(BNum.BNum_DivInternal.selector);

    bNum.call_bdiv(type(uint256).max, 1);
  }

  function test_BdivWhenPassingAAndBTooBig() external {
    uint256 _a = type(uint256).max;
    uint256 _b = BONE;

    // it should revert
    //     a*BONE/b + b/2 > uint256 max
    vm.expectRevert(BNum.BNum_DivInternal.selector);

    bNum.call_bdiv(_a, _b);
  }

  function test_BDivWhenFlooringToZero(uint256 _a, uint256 _b) external {
    _a = bound(_a, 1, (type(uint256).max / (BONE * 2)) - 1);
    _b = bound(_b, (2 * BONE * _a) + 1, type(uint256).max);

    uint256 _result = bNum.call_bdiv(_a, _b);

    // it should return 0
    assertEq(_result, 0);
  }

  function test_BdivWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BpowiWhenPassingAAsZero() external {
    uint256 _result = bNum.call_bpowi(0, 3);

    // it should return zero
    assertEq(_result, 0);
  }

  function test_BpowiWhenPassingBAsZero() external {
    uint256 _result = bNum.call_bpowi(3 * BONE, 0);

    // it should return BONE
    assertEq(_result, BONE);
  }

  function test_BpowiWhenPassingAAsOne() external {
    uint256 _result = bNum.call_bpowi(BONE, 3);

    // it should return BONE
    assertEq(_result, BONE);
  }

  function test_BpowiWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BpowWhenPassingExponentAsZero() external {
    uint256 _result = bNum.call_bpow(BONE, 0);

    // it should return BONE
    assertEq(_result, BONE);
  }

  function test_BpowRevertWhen_PassingBaseLteThanMIN_BPOW_BASE(uint256 _base) external {
    _base = bound(_base, 0, bNum.MIN_BPOW_BASE());

    // it should revert
    vm.expectRevert(BNum.BNum_BPowBaseTooLow.selector);

    bNum.call_bpow(0, 3 * BONE);
  }

  function test_BpowRevertWhen_PassingBaseGteMAX_BPOW_BASE(uint256 _base) external {
    _base = bound(_base, bNum.MAX_BPOW_BASE(), type(uint256).max);

    // it should revert
    vm.expectRevert(BNum.BNum_BPowBaseTooHigh.selector);

    bNum.call_bpow(type(uint256).max, 3 * BONE);
  }

  function test_BpowWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }
}
