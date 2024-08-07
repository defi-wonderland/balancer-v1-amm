// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BConst} from 'contracts/BConst.sol';
import {Test} from 'forge-std/Test.sol';
import {IBPool} from 'interfaces/IBPool.sol';

import {LibString} from 'solmate/utils/LibString.sol';
import {MockBPool} from 'test/smock/MockBPool.sol';

contract BPoolBase is Test, BConst {
  using LibString for uint256;

  address[] public tokens;

  MockBPool public bPool;
  string constant ERC20_NAME = 'Balancer Pool Token';
  string constant ERC20_SYMBOL = 'BPT';

  function setUp() public virtual {
    bPool = new MockBPool(ERC20_NAME, ERC20_SYMBOL);
    tokens.push(makeAddr('token0'));
    tokens.push(makeAddr('token1'));
  }

  function _getDeterministicTokenArray(uint256 _length) internal returns (address[] memory _tokenArray) {
    _tokenArray = new address[](_length);
    for (uint256 i = 0; i < _length; i++) {
      _tokenArray[i] = makeAddr(i.toString());
    }
  }

  function _tokensToMemory() internal view returns (address[] memory _tokens) {
    _tokens = new address[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      _tokens[i] = tokens[i];
    }
  }

  function _setRandomTokens(uint256 _length) internal returns (address[] memory _tokensToAdd) {
    _tokensToAdd = _getDeterministicTokenArray(_length);
    for (uint256 i = 0; i < _length; i++) {
      bPool.set__records(_tokensToAdd[i], IBPool.Record({bound: true, index: i, denorm: 0}));
    }
    bPool.set__tokens(_tokensToAdd);
  }
}
