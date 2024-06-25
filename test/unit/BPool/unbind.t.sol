// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BConst} from 'contracts/BConst.sol';
import {BPool, IBPool, IERC20} from 'contracts/BPool.sol';
import {StdStorage, Test, stdStorage} from 'forge-std/Test.sol';

// For test contract: execute a reentering call to an arbitrary function
contract BPoolReentering is BPool {
  event HAS_REENTERED();

  function TestTryToReenter(bytes calldata _calldata) external _lock_ {
    (bool success, bytes memory ret) = address(this).call(_calldata);

    if (!success) {
      assembly {
        revert(add(ret, 0x20), mload(ret))
      }
    }
  }
}

// For test contract: expose and modify the internal state variables of BPool
contract BPoolExposed is BPool {
  function forTest_getRecord(address token) external view returns (IBPool.Record memory) {
    return _records[token];
  }

  function forTest_setFinalize(bool _isFinalized) external {
    _finalized = _isFinalized;
  }

  function forTest_setTokens(address[] memory __tokens) external {
    _tokens = __tokens;
  }

  function forTest_setRecords(address _token, bool _bound, uint256 _index, uint256 _denorm) external {
    _records[_token].bound = _bound;
    _records[_token].index = _index;
    _records[_token].denorm = _denorm;
  }

  function forTest_setTotalWeight(uint256 __totalWeight) external {
    _totalWeight = __totalWeight;
  }
}

// Main test contract
contract BPoolTest is Test, BConst {
  using stdStorage for StdStorage;

  BPool pool;

  address deployer = makeAddr('deployer');

  function setUp() external {
    vm.prank(deployer);
    pool = new BPool();
  }

  modifier whenTheFunctionRequirementsAreMet() {
    _;
  }

  function test_UnbindRevertWhen_PoolIsTheReenteringCaller() external {
    // Pre Condition
    BPoolReentering poolReentering = new BPoolReentering();

    // it should revert
    vm.expectRevert('ERR_REENTRY');

    // Action
    poolReentering.TestTryToReenter(abi.encodeCall(poolReentering.unbind, makeAddr('token')));
  }

  function test_UnbindRevertWhen_CalledByANon_controller(address _caller) external {
    // Pre condition
    vm.assume(_caller != deployer);

    // it should revert
    vm.expectRevert('ERR_NOT_CONTROLLER');

    // Action
    vm.prank(_caller);
    pool.unbind(makeAddr('token'));
  }

  function test_UnbindRevertWhen_TheTokenToUnbindIsNotBound() external {
    // Pre condition
    vm.startPrank(deployer);
    BPoolExposed poolExposed = new BPoolExposed();
    address _token = makeAddr('token');
    poolExposed.forTest_setRecords({_token: _token, _bound: false, _index: 0, _denorm: 1});

    // it should revert
    vm.expectRevert('ERR_NOT_BOUND');

    // Action
    poolExposed.unbind(_token);
  }

  function test_UnbindRevertWhen_ThePoolIsFinalized() external {
    // Pre condition
    vm.startPrank(deployer);
    address _token = makeAddr('token');
    BPoolExposed poolExposed = new BPoolExposed();
    poolExposed.forTest_setRecords({_token: _token, _bound: true, _index: 0, _denorm: 1});
    poolExposed.forTest_setFinalize(true);

    // it should revert
    vm.expectRevert('ERR_IS_FINALIZED');

    // Action
    poolExposed.unbind(_token);
  }

  function test_UnbindWhenTheFunctionRequirementsAreMet() external whenTheFunctionRequirementsAreMet {
    // Pre condition
    vm.startPrank(deployer);

    BPoolExposed poolExposed = new BPoolExposed();
    uint256 _balance = 100;
    uint256 _denorm = 5;
    uint256 _totalWeight = 10;
    address _token = makeAddr('token');
    address[] memory _tokens = new address[](1);
    _tokens[0] = _token;

    poolExposed.forTest_setRecords({_token: _token, _bound: true, _index: 0, _denorm: _denorm});
    poolExposed.forTest_setTotalWeight(_totalWeight);
    poolExposed.forTest_setTokens(_tokens);

    // it should emit LOG_CALL
    vm.expectEmit(address(poolExposed));
    emit IBPool.LOG_CALL(poolExposed.unbind.selector, deployer, abi.encodeCall(poolExposed.unbind, _token));

    // it should transfer the token balance to the caller
    vm.mockCall(_token, abi.encodeCall(IERC20.balanceOf, (address(poolExposed))), abi.encode(_balance));
    vm.expectCall(_token, abi.encodeCall(IERC20.balanceOf, (address(poolExposed))));
    vm.mockCall(_token, abi.encodeCall(IERC20.transfer, (deployer, _balance)), abi.encode(true));
    vm.expectCall(_token, abi.encodeCall(IERC20.transfer, (deployer, _balance)));

    // Action
    poolExposed.unbind(_token);

    // Post condition

    // it should update the total weight
    assertEq(poolExposed.getTotalDenormalizedWeight(), _totalWeight - _denorm);

    // it should remove the token from the token array
    address[] memory _currTokens = poolExposed.getCurrentTokens();
    for (uint256 i = 0; i < _currTokens.length; i++) {
      if (_currTokens[i] == _token) {
        emit log('Pool token not removed');
        fail();
      }
    }

    // it should update the token record to unbound
    IBPool.Record memory _record = poolExposed.forTest_getRecord(_token);
    assertFalse(_record.bound);
  }

  function test_UnbindRevertWhen_TheTokenTransferFails() external whenTheFunctionRequirementsAreMet {
    // Pre condition
    vm.startPrank(deployer);

    BPoolExposed poolExposed = new BPoolExposed();
    uint256 _balance = 100;
    uint256 _denorm = 5;
    uint256 _totalWeight = 10;
    address _token = makeAddr('token');
    address[] memory _tokens = new address[](1);
    _tokens[0] = _token;

    poolExposed.forTest_setRecords({_token: _token, _bound: true, _index: 0, _denorm: _denorm});
    poolExposed.forTest_setTotalWeight(_totalWeight);
    poolExposed.forTest_setTokens(_tokens);

    // it should transfer the token balance to the caller
    vm.mockCall(_token, abi.encodeCall(IERC20.balanceOf, (address(poolExposed))), abi.encode(_balance));
    vm.expectCall(_token, abi.encodeCall(IERC20.balanceOf, (address(poolExposed))));
    vm.mockCall(_token, abi.encodeCall(IERC20.transfer, (deployer, _balance)), abi.encode(false));
    vm.expectCall(_token, abi.encodeCall(IERC20.transfer, (deployer, _balance)));

    // it should revert
    vm.expectRevert('ERR_ERC20_FALSE');

    // Action
    poolExposed.unbind(_token);
  }
}
