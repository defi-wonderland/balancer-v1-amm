// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {HalmosTest} from '../AdvancedTestsUtils.sol';
import {BNum} from 'contracts/BNum.sol';
import {Test} from 'forge-std/Test.sol';

contract SymbolicBNum is BNum, Test, HalmosTest {
  /////////////////////////////////////////////////////////////////////
  //                           Bnum::btoi                            //
  /////////////////////////////////////////////////////////////////////

  // btoi should always return the floor(a / BONE) == (a - a%BONE) / BONE
  // TODO: Too tightly coupled
  function check_btoi_alwaysFloor(uint256 _input) public pure {
    // action
    uint256 _result = btoi(_input);

    // post-conditionn
    assert(_result == _input / BONE);
  }

  /////////////////////////////////////////////////////////////////////
  //                          Bnum::bfloor                           //
  /////////////////////////////////////////////////////////////////////

  // btoi should always return the floor(a / BONE) == (a - a%BONE) / BONE
  function check_bfloor_shouldAlwaysRoundDown(uint256 _input) public pure {
    // action
    uint256 _result = bfloor(_input);

    // post condition
    assert(_result == (_input / BONE) * BONE);
  }

  /////////////////////////////////////////////////////////////////////
  //                           Bnum::badd                            //
  /////////////////////////////////////////////////////////////////////

  // badd should be commutative
  function check_baddCommut(uint256 _a, uint256 _b) public pure {
    // action
    uint256 _result1 = badd(_a, _b);
    uint256 _result2 = badd(_b, _a);

    // post condition
    assert(_result1 == _result2);
  }

  // badd should be associative
  function check_badd_assoc(uint256 _a, uint256 _b, uint256 _c) public pure {
    // action
    uint256 _result1 = badd(badd(_a, _b), _c);
    uint256 _result2 = badd(_a, badd(_b, _c));

    // post condition
    assert(_result1 == _result2);
  }

  // 0 should be identity for badd
  function check_badd_zeroIdentity(uint256 _a) public pure {
    // action
    uint256 _result = badd(_a, 0);

    // post condition
    assert(_result == _a);
  }

  // badd result should always be gte its terms
  function check_badd_resultGTE(uint256 _a, uint256 _b) public pure {
    // action
    uint256 _result = badd(_a, _b);

    // post condition
    assert(_result >= _a);
    assert(_result >= _b);
  }

  // badd should never sum terms which have a sum gt uint max
  function check_badd_overflow(uint256 _a, uint256 _b) public pure {
    // precondition
    vm.assume(_a != type(uint256).max);

    // action
    uint256 _result = badd(_a, _b);

    // post condition
    assert(_result == _a + _b);
  }

  // badd should have bsub as reverse operation
  function check_badd_bsub(uint256 _a, uint256 _b) public pure {
    // action
    uint256 _result = badd(_a, _b);
    uint256 _result2 = bsub(_result, _b);

    // post condition
    assert(_result2 == _a);
  }

  /////////////////////////////////////////////////////////////////////
  //                           Bnum::bsub                            //
  /////////////////////////////////////////////////////////////////////

  // bsub should not be commutative
  function check_bsub_notCommut(uint256 _a, uint256 _b) public pure {
    // precondition
    vm.assume(_a != _b);

    // action
    uint256 _result1 = bsub(_a, _b);
    uint256 _result2 = bsub(_b, _a);

    // post condition
    assert(_result1 != _result2);
  }

  // bsub should not be associative
  function check_bsub_notAssoc(uint256 _a, uint256 _b, uint256 _c) public pure {
    // precondition
    vm.assume(_a != _b && _b != _c && _a != _c);
    vm.assume(_a != 0 && _b != 0 && _c != 0);

    // action
    uint256 _result1 = bsub(bsub(_a, _b), _c);
    uint256 _result2 = bsub(_a, bsub(_b, _c));

    // post condition
    assert(_result1 != _result2);
  }

  // bsub should have 0 as identity
  function check_bsub_zeroIdentity(uint256 _a) public pure {
    // action
    uint256 _result = bsub(_a, 0);

    // post condition
    assert(_result == _a);
  }

  // bsub result should always be lte a
  function check_bsub_resultLTE(uint256 _a, uint256 _b) public pure {
    // precondition
    vm.assume(_a >= _b); // Avoid underflow

    // action
    uint256 _result = bsub(_a, _b);

    // post condition
    assert(_result <= _a);
  }

  // todo
  // bsub should alway revert if b > a (duplicate with previous tho)
  function check_bsub_revert(uint256 _a, uint256 _b) public pure {
    vm.assume(_b > _a);
    //bsub(_a, _b);
  }

  /////////////////////////////////////////////////////////////////////
  //                         Bnum::bsubSign                          //
  /////////////////////////////////////////////////////////////////////

  // bsubSign result should always be negative if b > a
  function check_bsubSign_negative(uint256 _a, uint256 _b) public pure {
    // precondition
    vm.assume(_b > _a);

    // action
    (uint256 _result, bool _flag) = bsubSign(_a, _b);

    // post condition
    assert(_result == _b - _a);
    assert(_flag);
  }

  // bsubSign result should always be positive if a > b
  function check_bsubSign_positive(uint256 _a, uint256 _b) public pure {
    // precondition
    vm.assume(_a > _b);

    // action
    (uint256 _result, bool _flag) = bsubSign(_a, _b);

    // post condition
    assert(_result == _a - _b);
    assert(!_flag);
  }

  // bsubSign result should always be 0 if a == b
  function check_bsubSign_zero(uint256 _a) public pure {
    // action
    (uint256 _result, bool _flag) = bsubSign(_a, _a);

    // post condition
    assert(_result == 0);
    assert(!_flag);
  }

  /////////////////////////////////////////////////////////////////////
  //                           Bnum::bmul                            //
  /////////////////////////////////////////////////////////////////////

  // bmul should be commutative
  function check_bmul_commutative(uint256 _a, uint256 _b) public pure {
    // action
    uint256 _result1 = bmul(_a, _b);
    uint256 _result2 = bmul(_b, _a);

    // post condition
    assert(_result1 == _result2);
  }

  //todo hangs
  // bmul should be associative
  function testCheck_bmul_associative(uint256 _a, uint256 _b, uint256 _c) public pure {
    // precondition
    if (_b != 0) vm.assume(_a < type(uint256).max / _b); // Avoid mul overflow
    if (_c != 0) vm.assume(_b < type(uint256).max / _c); // Avoid mul overflow
    vm.assume(_a * _b + _c / 2 < type(uint256).max); // Avoid add overflow

    vm.assume(_a >= BONE);
    vm.assume(_b >= BONE);
    vm.assume(_c >= BONE);

    // action
    uint256 _result1 = bmul(bmul(_a, _b), _c);
    uint256 _result2 = bmul(_a, bmul(_b, _c));

    // post condition
    //   assert(_result1 == _result2);
    assertApproxEqAbs(_result1, _result2, 10 * BONE);
  }

  //todo hangs
  // bmul should be distributive
  // function check_bmul_distributive(uint256 _a, uint256 _b, uint256 _c) public pure {
  //     uint256 _result1 = bmul(_a, badd(_b, _c));
  //     uint256 _result2 = badd(bmul(_a, _b), bmul(_a, _c));
  //     assert(_result1 == _result2);
  // }

  //todo
  // 1 should be identity for bmul
  // function check_bmul_identity(uint256 _a) public pure {
  //     vm.assume(_a < type(uint256).max / BONE); // Avoid mul overflow
  //     uint256 _result = bmul(_a, BONE);
  //     assert(_result == _a);
  // }

  // 0 should be absorbing for mul
  function check_bmul_absorbing(uint256 _a) public pure {
    // action
    uint256 _result = bmul(_a, 0);

    // post condition
    assert(_result == 0);
  }

  //todo
  //➜ bmul(57896044618658097711785492504343953926634992332820282019728792003956564819968, 1) >= 57896044618658097711785492504343953926634992332820282019728792003956564819968
  // Type: bool
  // └ Value: false
  // bmul result should always be gte a and b
  // function check_bmul_resultGTE(uint256 _a, uint256 _b) public pure {
  //     vm.assume(_a != 0 && _b != 0); // Avoid absorbing
  //     vm.assume(_a < type(uint256).max / BONE); // Avoid mul overflow
  //     vm.assume(_b < type(uint256).max / BONE); // Avoid mul overflow
  //     vm.assume(_a * BONE + _b / 2 < type(uint256).max); // Avoid add overflow

  //     uint256 _result = bmul(_a, _b);
  //     assert(_result >= _a);
  //     assert(_result >= _b);
  // }

  /////////////////////////////////////////////////////////////////////
  //                           Bnum::bdiv                            //
  /////////////////////////////////////////////////////////////////////

  //todo: Halmos times out vs foundry passes
  // 1 should be identity for bdiv
  // function check_bdiv_identity(uint256 _a) public pure {
  //     vm.assume(_a < type(uint256).max / BONE); // Avoid add overflow
  //     uint256 _result = bdiv(_a, BONE);
  //     assert(_result == _a);
  // }

  // uint256[] public fixtureA = [
  //     BONE,
  //     BONE * 2,
  //     BONE / 2,
  //     BONE * 2 - 1,
  //     BONE * 2 + 1,
  //     BONE / 2 - 1,
  //     BONE / 2 + 1,
  //     BONE * 3,
  //     BONE * 4,
  //     BONE * 5,
  //     BONE * 6,
  //     BONE * 7,
  //     BONE * 8,
  //     BONE * 9,
  //     BONE * 10,
  //     type(uint256).max / 10**18,
  //     type(uint256).max / 10**18 - 1,
  //     type(uint256).max / 10**18 - 10,
  //     type(uint256).max / 10**18 - BONE / 2,
  //     type(uint256).max / 10**18 - BONE / 2 + 1,
  //     type(uint256).max / 10**18 - BONE / 2 - 1,
  //     type(uint256).max / 10**18 - BONE / 2 - 10,
  //     0,
  //     1,
  //     2
  // ];

  // /// forge-config: default.fuzz.runs = 1000000
  // function test_bdiv_identity(uint256 a) public pure {
  //     a = bound(a, 0, type(uint256).max  / 10**18);
  //     uint256 _result = bdiv(a, BONE);
  //     assertEq(_result, a);
  // }

  //todo
  // bdiv should revert if b is 0
  // function check_bdiv_revert(uint256 _a) public pure {
  // }

  //todo hangs
  // bdiv result should be lte a
  // function test_bdiv_resultLTE(uint256 _a, uint256 _b) public pure {
  //     vm.assume(_b != 0);
  //     vm.assume(_a < type(uint256).max / BONE); // Avoid mul overflow
  //     //todo: overconstrained next line? Too tightly coupled?
  //     vm.assume(_a * BONE + _b / 2 < type(uint256).max); // Avoid add overflow

  //     uint256 _result = bdiv(_a, _b);
  //     assert(_result <= _a * BONE);
  //     assertLe(_result, _a * BONE);
  // }

  //todo hangs
  // bdiv should be bmul reverse operation
  //   function check_bdiv_bmul(uint256 _a, uint256 _b) public pure {
  //       vm.assume(_b > 0);
  //       vm.assume(_a > _b); // todo: overconstrained?

  //       uint256 _bdivResult = bdiv(_a, _b);
  //       uint256 _result = bmul(_bdivResult, _b);
  //       assert(_result == _a);
  //   }

  /////////////////////////////////////////////////////////////////////
  //                           Bnum::bpowi                           //
  /////////////////////////////////////////////////////////////////////

  // bpowi should return 1 if exp is 0
  function check_bpowi_zeroExp(uint256 _a) public pure {
    // action
    uint256 _result = bpowi(_a, 0);

    // post condition
    assert(_result == BONE);
  }

  //todo echidna (loop unrolling bound hit)
  // 0 should be absorbing if base
  //   function check_bpowi_absorbingBase(uint256 _exp) public pure {
  //     vm.assume(_exp != 0); // Consider 0^0 as undetermined

  //     uint256 _result = bpowi(0, _exp);
  //     assert(_result == 0);
  //   }

  //todo echidna (loop unrolling bound hit)
  // 1 should be identity if base
  //   function check_bpowi_identityBase(uint256 _exp) public pure {
  //     uint256 _result = bpowi(BONE, _exp);
  //     assert(_result == BONE);
  //   }

  //todo echidna (loop unrolling bound hit)
  // 1 should be identity if exp
  //   function check_bpowi_identityExp(uint256 _base) public pure {
  //     uint256 _result = bpowi(_base, BONE);
  //     assert(_result == _base);
  //   }

  /**
   * // bpowi should be distributive over mult of the same base x^a * x^b == x^(a+b)
   *   function check_bpowi_distributiveBase(uint256 _base, uint256 _a, uint256 _b) public pure {
   *       uint256 _result1 = bpowi(_base, badd(_a, _b));
   *       uint256 _result2 = bmul(bpowi(_base, _a), bpowi(_base, _b));
   *       assert(_result1 == _result2);
   *   }
   *
   *   // bpowi should be distributive over mult of the same exp  a^x * b^x == (a*b)^x
   *   function check_bpowi_distributiveExp(uint256 _a, uint256 _b, uint256 _exp) public pure {
   *       uint256 _result1 = bpowi(bmul(_a, _b), _exp);
   *       uint256 _result2 = bmul(bpowi(_a, _exp), bpowi(_b, _exp));
   *       assert(_result1 == _result2);
   *   }
   *
   *   // power of a power should mult the exp (x^a)^b == x^(a*b)
   *   function check_bpowi_powerOfPower(uint256 _base, uint256 _a, uint256 _b) public pure {
   *       uint256 _result1 = bpowi(bpowi(_base, _a), _b);
   *       uint256 _result2 = bpowi(_base, bmul(_a, _b));
   *       assert(_result1 == _result2);
   *   }
   */

  /////////////////////////////////////////////////////////////////////
  //                           Bnum::bpow                            //
  /////////////////////////////////////////////////////////////////////

  // bpow should return 1 if exp is 0
  function check_bpow_zeroExp(uint256 _a) public pure {
    // action
    uint256 _result = bpow(_a, 0);

    // post condition
    assert(_result == BONE);
  }

  //todo min base is 1wei -> can never be 0 instead (echidna)
  // 0 should be absorbing if base
  // function check_bpow_absorbingBase(uint256 _exp) public pure {
  //     uint256 _result = bpow(0, _exp);
  //     assert(_result == 0);
  // }

  //todo echidna (loop unrolling bound hit)
  // 1 should be identity if base
  //   function check_bpow_identityBase(uint256 _exp) public pure {
  //     uint256 _result = bpow(BONE, _exp);
  //     assert(_result == BONE);
  //   }

  // 1 should be identity if exp
  function check_bpow_identityExp(uint256 _base) public pure {
    // action
    uint256 _result = bpow(_base, BONE);

    // post condition
    assert(_result == _base);
  }

  //todo infinite loop
  // bpow should be distributive over mult of the same base x^a * x^b == x^(a+b)
  // function check_bpow_distributiveBase(uint256 _base, uint256 _a, uint256 _b) public pure {
  //     uint256 _result1 = bpow(_base, badd(_a, _b));
  //     uint256 _result2 = bmul(bpow(_base, _a), bpow(_base, _b));
  //     assert(_result1 == _result2);
  // }

  //todo loop
  // bpow should be distributive over mult of the same exp  a^x * b^x == (a*b)^x
  // function check_bpow_distributiveExp(uint256 _a, uint256 _b, uint256 _exp) public pure {
  //     uint256 _result1 = bpow(bmul(_a, _b), _exp);
  //     uint256 _result2 = bmul(bpow(_a, _exp), bpow(_b, _exp));
  //     assert(_result1 == _result2);
  // }

  // todo
  // // power of a power should mult the exp (x^a)^b == x^(a*b)
  // function check_bpow_powerOfPower(uint256 _base, uint256 _a, uint256 _b) public pure {
  //     uint256 _result1 = bpow(bpow(_base, _a), _b);
  //     uint256 _result2 = bpow(_base, bmul(_a, _b));
  //     assert(_result1 == _result2);
  // }
}
