// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {BFactory, BPool, IBFactory, IBPool, SafeERC20} from '../../src/contracts/BFactory.sol';
import {Test} from 'forge-std/Test.sol';

contract MockBFactory is BFactory, Test {
  function set__isBPool(address _key0, bool _value) public {
    _isBPool[_key0] = _value;
  }

  function call__isBPool(address _key0) public view returns (bool) {
    return _isBPool[_key0];
  }

  function set__bDao(address __bDao) public {
    _bDao = __bDao;
  }

  function call__bDao() public view returns (address) {
    return _bDao;
  }

  constructor() BFactory() {}

  function mock_call_newBPool(string memory name, string memory symbol, IBPool bPool) public {
    vm.mockCall(address(this), abi.encodeWithSignature('newBPool(string,string)', name, symbol), abi.encode(bPool));
  }

  function mock_call_setBDao(address bDao) public {
    vm.mockCall(address(this), abi.encodeWithSignature('setBDao(address)', bDao), abi.encode());
  }

  function mock_call_collect(IBPool bPool) public {
    vm.mockCall(address(this), abi.encodeWithSignature('collect(IBPool)', bPool), abi.encode());
  }

  function mock_call_isBPool(address bPool, bool _returnParam0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('isBPool(address)', bPool), abi.encode(_returnParam0));
  }

  function mock_call_getBDao(address _returnParam0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('getBDao()'), abi.encode(_returnParam0));
  }

  function mock_call__newBPool(string memory name, string memory symbol, IBPool bPool) public {
    vm.mockCall(address(this), abi.encodeWithSignature('_newBPool(string,string)', name, symbol), abi.encode(bPool));
  }

  function _newBPool(string memory name, string memory symbol) internal override returns (IBPool bPool) {
    (bool _success, bytes memory _data) =
      address(this).call(abi.encodeWithSignature('_newBPool(string,string)', name, symbol));

    if (_success) return abi.decode(_data, (IBPool));
    else return super._newBPool(name, symbol);
  }

  function call__newBPool(string memory name, string memory symbol) public returns (IBPool bPool) {
    return _newBPool(name, symbol);
  }

  function expectCall__newBPool(string memory name, string memory symbol) public {
    vm.expectCall(address(this), abi.encodeWithSignature('_newBPool(string,string)', name, symbol));
  }
}
