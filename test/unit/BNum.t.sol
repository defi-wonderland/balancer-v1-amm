// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from 'forge-std/Test.sol';

contract BNumTest is Test {
  function test_BtoiWhenPassingZero() external {
    // it should return zero
    vm.skip(true);
  }

  function test_BtoiWhenPassingBONE() external {
    // it should return one
    vm.skip(true);
  }

  function test_BtoiWhenPassingAValueLessThanBONE() external {
    // it should return zero
    vm.skip(true);
  }

  function test_BtoiWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BfloorWhenPassingZero() external {
    // it should return zero
    vm.skip(true);
  }

  function test_BfloorWhenPassingAValueLessThanBONE() external {
    // it should return zero
    vm.skip(true);
  }

  function test_BfloorWhenUsingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BaddWhenPassingZeroAndZero() external {
    // it should return zero
    vm.skip(true);
  }

  function test_BaddRevertWhen_PassingAAsUint256MaxAndBNonZero() external {
    // it should revert
    vm.skip(true);
  }

  function test_BaddRevertWhen_PassingBAsUint256MaxAndANonZero() external {
    // it should revert
    vm.skip(true);
  }

  function test_BaddWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BsubWhenPassingZeroAndZero() external {
    // it should return zero
    vm.skip(true);
  }

  function test_BsubRevertWhen_PassingALessThanB() external {
    // it should revert
    vm.skip(true);
  }

  function test_BsubWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BsubSignWhenPassingZeroAndZero() external {
    // it should return zero and false
    vm.skip(true);
  }

  function test_BsubSignWhenPassingALessThanB() external {
    // it should return correct value and true
    vm.skip(true);
  }

  function test_BsubSignWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BmulWhenPassingZeroAndZero() external {
    // it should return zero
    vm.skip(true);
  }

  function test_BmulRevertWhen_PassingAAsUint256MaxAndBNonZero() external {
    // it should revert
    vm.skip(true);
  }

  function test_BmulRevertWhen_PassingBAsUint256MaxAndANonZero() external {
    // it should revert
    vm.skip(true);
  }

  function test_BmulWhenPassingAMulBTooBig() external {
    // it should revert
    //     a * b + BONE / 2 > uint256 max
    vm.skip(true);
  }

  function test_BmulWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BdivRevertWhen_PassingBAsZero() external {
    // it should revert
    vm.skip(true);
  }

  function test_BdivRevertWhen_PassingAAsUint256Max() external {
    // it should revert
    vm.skip(true);
  }

  function test_BdivWhenPassingAAndBTooBig() external {
    // it should revert
    //     a*BONE/b + b/2 > uint256 max
    vm.skip(true);
  }

  function test_BdivWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BpowiWhenPassingAAsZero() external {
    // it should return zero
    vm.skip(true);
  }

  function test_BpowiWhenPassingBAsZero() external {
    // it should return BONE
    vm.skip(true);
  }

  function test_BpowiWhenPassingAAsOne() external {
    // it should return BONE
    vm.skip(true);
  }

  function test_BpowiWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }

  function test_BpowWhenPassingBaseAsZero() external {
    // it should return zero
    vm.skip(true);
  }

  function test_BpowWhenPassingExponentAsZero() external {
    // it should return BONE
    vm.skip(true);
  }

  function test_BpowRevertWhen_PassingBaseLteThanMIN_BPOW_BASE() external {
    // it should revert
    vm.skip(true);
  }

  function test_BpowRevertWhen_PassingBaseGteMAX_BPOW_BASE() external {
    // it should revert
    vm.skip(true);
  }

  function test_BpowWhenPassingKnownValues() external {
    // it should return correct value
    vm.skip(true);
  }
}
