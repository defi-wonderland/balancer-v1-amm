// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BConst} from 'contracts/BConst.sol';
import {Test} from 'forge-std/Test.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {MockBPool} from 'test/smock/MockBPool.sol';
import {Utils} from 'test/utils/Utils.sol';

contract BPoolBase is Test, BConst, Utils {
  MockBPool public bPool;
  address public deployer = makeAddr('deployer');

  function setUp() public virtual {
    vm.prank(deployer);
    bPool = new MockBPool();
  }

  function _setRandomTokens(uint256 _length) internal returns (address[] memory _tokensToAdd) {
    _tokensToAdd = _getDeterministicTokenArray(_length);
    for (uint256 i = 0; i < _length; i++) {
      _setRecord(_tokensToAdd[i], IBPool.Record({bound: true, index: i, denorm: 0}));
    }
    _setTokens(_tokensToAdd);
  }

  function _setTokens(address[] memory _tokens) internal {
    bPool.set__tokens(_tokens);
  }

  function _setRecord(address _token, IBPool.Record memory _record) internal {
    bPool.set__records(_token, _record);
  }
}

contract BPool is BPoolBase {
  function test_ConstructorWhenCalled(address _deployer) external {
    vm.prank(_deployer);
    MockBPool _newBPool = new MockBPool();

    // it sets caller as controller
    assertEq(_newBPool.call__controller(), _deployer);
    // it sets caller as factory
    assertEq(_newBPool.call__factory(), _deployer);
    // it sets swap fee to MIN_FEE
    assertEq(_newBPool.call__swapFee(), MIN_FEE);
    // it is NOT finalized
    assertEq(_newBPool.call__finalized(), false);
  }

  function test_IsFinalizedWhenPoolIsFinalized() external {
    // it returns true
    bPool.set__finalized(true);
    assertTrue(bPool.isFinalized());
  }

  function test_IsFinalizedWhenPoolIsNOTFinalized() external {
    bPool.set__finalized(false);
    // it returns false
    assertFalse(bPool.isFinalized());
  }

  function test_IsBoundWhenTokenIsBound(address _token) external {
    _setRecord(_token, IBPool.Record({bound: true, index: 0, denorm: 0}));
    // it returns true
    assertTrue(bPool.isBound(_token));
  }

  function test_IsBoundWhenTokenIsNOTBound(address _token) external {
    _setRecord(_token, IBPool.Record({bound: false, index: 0, denorm: 0}));
    // it returns false
    assertFalse(bPool.isBound(_token));
  }

  function test_GetNumTokensWhenCalled(uint256 _tokensToAdd) external {
    _tokensToAdd = bound(_tokensToAdd, 0, MAX_BOUND_TOKENS);
    _setRandomTokens(_tokensToAdd);
    // it returns number of tokens
    assertEq(bPool.getNumTokens(), _tokensToAdd);
  }
}
