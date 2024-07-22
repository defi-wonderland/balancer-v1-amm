// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from '@cowprotocol/interfaces/IERC20.sol';

import {BCoWPoolBase} from './BCoWPoolBase.sol';

import {IBCoWFactory} from 'interfaces/IBCoWFactory.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';
import {MockBCoWPool} from 'test/manual-smock/MockBCoWPool.sol';

contract BCoWPool is BCoWPoolBase {
  uint256 public tokenWeight = 1e18;

  function setUp() public virtual override {
    super.setUp();
    bCoWPool.set__tokens(tokens);
    bCoWPool.set__records(tokens[0], IBPool.Record({bound: true, index: 0, denorm: tokenWeight}));
    bCoWPool.set__records(tokens[1], IBPool.Record({bound: true, index: 1, denorm: tokenWeight}));

    vm.mockCall(address(this), abi.encodeCall(IBCoWFactory.logBCoWPool, ()), abi.encode());

    vm.mockCall(tokens[0], abi.encodeCall(IERC20.approve, (vaultRelayer, type(uint256).max)), abi.encode(true));
    vm.mockCall(tokens[1], abi.encodeCall(IERC20.approve, (vaultRelayer, type(uint256).max)), abi.encode(true));
  }

  function test_ConstructorWhenCalled(
    address _settler,
    bytes32 _separator,
    address _relayer,
    bytes32 _appData
  ) external {
    assumeNotForgeAddress(_settler);
    vm.mockCall(_settler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(_separator));
    vm.mockCall(_settler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(_relayer));
    MockBCoWPool pool = new MockBCoWPool(_settler, _appData);
    // it should set the solution settler
    assertEq(address(pool.SOLUTION_SETTLER()), _settler);
    // it should set the domain separator
    assertEq(pool.SOLUTION_SETTLER_DOMAIN_SEPARATOR(), _separator);
    // it should set the vault relayer
    assertEq(pool.VAULT_RELAYER(), _relayer);
    // it should set the app data
    assertEq(pool.APP_DATA(), _appData);
  }

  function test__afterFinalize_WhenCalled() external {
    // it calls approve on every bound token
    vm.expectCall(tokens[0], abi.encodeCall(IERC20.approve, (vaultRelayer, type(uint256).max)));
    vm.expectCall(tokens[1], abi.encodeCall(IERC20.approve, (vaultRelayer, type(uint256).max)));
    // it calls logBCoWPool on the factory
    vm.expectCall(address(this), abi.encodeCall(IBCoWFactory.logBCoWPool, ()));
    bCoWPool.finalize();
  }

  function test__afterFinalize_WhenFactorysLogBCoWPoolDoesNotRevert() external {
    // it returns
    bCoWPool.call__afterFinalize();
  }

  function test__afterFinalize_WhenFactorysLogBCoWPoolReverts(bytes memory revertData) external {
    vm.mockCallRevert(address(this), abi.encodeCall(IBCoWFactory.logBCoWPool, ()), revertData);
    // it emits a COWAMMPoolCreated event
    vm.expectEmit(address(bCoWPool));
    emit IBCoWFactory.COWAMMPoolCreated(address(bCoWPool));
    bCoWPool.call__afterFinalize();
  }
}
