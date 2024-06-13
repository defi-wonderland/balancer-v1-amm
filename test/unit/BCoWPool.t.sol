// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from '@cowprotocol/interfaces/IERC20.sol';

import {GPv2Order} from '@cowprotocol/libraries/GPv2Order.sol';

import {BasePoolTest} from './BPool.t.sol';

import {BMath} from 'contracts/BMath.sol';
import {IBCoWPool} from 'interfaces/IBCoWPool.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';
import {MockBCoWPool} from 'test/manual-smock/MockBCoWPool.sol';
import {MockBPool} from 'test/smock/MockBPool.sol';

abstract contract BaseCoWPoolTest is BasePoolTest {
  address public cowSolutionSettler = makeAddr('cowSolutionSettler');
  bytes32 public domainSeparator = bytes32(bytes2(0xf00b));
  address public vaultRelayer = makeAddr('vaultRelayer');
  GPv2Order.Data correctOrder;

  MockBCoWPool bCoWPool;

  function setUp() public override {
    super.setUp();
    vm.mockCall(cowSolutionSettler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(domainSeparator));
    vm.mockCall(cowSolutionSettler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(vaultRelayer));
    bCoWPool = new MockBCoWPool(cowSolutionSettler);
    bPool = MockBPool(address(bCoWPool));
    _setRandomTokens(TOKENS_AMOUNT);
    correctOrder = GPv2Order.Data({
      sellToken: IERC20(tokens[0]),
      buyToken: IERC20(tokens[1]),
      receiver: makeAddr('unimportant'),
      sellAmount: 0,
      buyAmount: 0,
      validTo: uint32(block.timestamp + 1 minutes),
      appData: bytes32(0),
      feeAmount: 0,
      kind: GPv2Order.KIND_SELL,
      partiallyFillable: false,
      sellTokenBalance: GPv2Order.BALANCE_ERC20,
      buyTokenBalance: GPv2Order.BALANCE_ERC20
    });
  }
}

contract BCoWPool_Unit_Constructor is BaseCoWPoolTest {
  function test_Set_SolutionSettler(address _settler) public {
    assumeNotForgeAddress(_settler);
    vm.mockCall(_settler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(domainSeparator));
    vm.mockCall(_settler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(vaultRelayer));
    MockBCoWPool pool = new MockBCoWPool(_settler);
    assertEq(address(pool.SOLUTION_SETTLER()), _settler);
  }

  function test_Set_DomainSeparator(address _settler, bytes32 _separator) public {
    assumeNotForgeAddress(_settler);
    vm.mockCall(_settler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(_separator));
    vm.mockCall(_settler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(vaultRelayer));
    MockBCoWPool pool = new MockBCoWPool(_settler);
    assertEq(pool.SOLUTION_SETTLER_DOMAIN_SEPARATOR(), _separator);
  }

  function test_Set_VaultRelayer(address _settler, address _relayer) public {
    assumeNotForgeAddress(_settler);
    vm.mockCall(_settler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(domainSeparator));
    vm.mockCall(_settler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(_relayer));
    MockBCoWPool pool = new MockBCoWPool(_settler);
    assertEq(pool.VAULT_RELAYER(), _relayer);
  }
}

contract BCoWPool_Unit_Finalize is BaseCoWPoolTest {
  function test_Set_Approvals() public {
    for (uint256 i = 0; i < TOKENS_AMOUNT; i++) {
      vm.mockCall(tokens[i], abi.encodePacked(IERC20.approve.selector), abi.encode(true));
      vm.expectCall(tokens[i], abi.encodeCall(IERC20.approve, (vaultRelayer, type(uint256).max)), 1);
    }
    bCoWPool.finalize();
  }
}

/// @notice this tests both commit and commitment
contract BCoWPool_Unit_Commit is BaseCoWPoolTest {
  function test_Revert_NonSolutionSettler(address sender, bytes32 orderHash) public {
    vm.assume(sender != cowSolutionSettler);
    vm.prank(sender);
    vm.expectRevert(IBCoWPool.CommitOutsideOfSettlement.selector);
    bCoWPool.commit(orderHash);
  }

  function test_Set_Commitment(bytes32 orderHash) public {
    vm.prank(cowSolutionSettler);
    bCoWPool.commit(orderHash);
    assertEq(bCoWPool.commitment(), orderHash);
  }
}

contract BCoWPool_Unit_DisableTranding is BaseCoWPoolTest {
  function test_Revert_NonController(address sender) public {
    // contract is deployed by this contract without any pranks
    vm.assume(sender != address(this));
    vm.prank(sender);
    vm.expectRevert(IBPool.BPool_CallerIsNotController.selector);
    bCoWPool.disableTrading();
  }

  function test_Clear_AppdataHash(bytes32 appDataHash) public {
    vm.assume(appDataHash != bytes32(0));
    bCoWPool.set_appDataHash(appDataHash);
    bCoWPool.disableTrading();
    assertEq(bCoWPool.appDataHash(), bytes32(0));
  }

  function test_Emit_TradingDisabledEvent() public {
    vm.expectEmit();
    emit IBCoWPool.TradingDisabled();
    bCoWPool.disableTrading();
  }

  function test_Succeed_AlreadyZeroAppdata() public {
    bCoWPool.set_appDataHash(bytes32(0));
    bCoWPool.disableTrading();
  }
}

contract BCoWPool_Unit_EnableTrading is BaseCoWPoolTest {
  function test_Revert_NonController(address sender, bytes32 appDataHash) public {
    // contract is deployed by this contract without any pranks
    vm.assume(sender != address(this));
    vm.prank(sender);
    vm.expectRevert(IBPool.BPool_CallerIsNotController.selector);
    bCoWPool.enableTrading(appDataHash);
  }

  function test_Set_AppDataHash(bytes32 appData) public {
    bytes32 appDataHash = keccak256(abi.encode(appData));
    bCoWPool.enableTrading(appData);
    assertEq(bCoWPool.appDataHash(), appDataHash);
  }

  function test_Emit_TradingEnabled(bytes32 appData) public {
    bytes32 appDataHash = keccak256(abi.encode(appData));
    vm.expectEmit();
    emit IBCoWPool.TradingEnabled(appDataHash, appData);
    bCoWPool.enableTrading(appData);
  }
}

contract BCoWPool_Unit_Verify is BaseCoWPoolTest {
  function test_Revert_NonBoundToken() public {
    GPv2Order.Data memory order = correctOrder;
    order.buyToken = IERC20(makeAddr('other token'));
    order = correctOrder;
    order.sellToken = IERC20(makeAddr('other token'));
    vm.expectRevert(IBPool.BPool_TokenNotBound.selector);
    bCoWPool.verify(order);
  }

  function test_Revert_LargeDurationOrder() public {
    GPv2Order.Data memory order = correctOrder;
    order.validTo = uint32(block.timestamp + 6 minutes);
    vm.expectRevert(IBCoWPool.BCoWPool_OrderValidityTooLong.selector);
    bCoWPool.verify(order);
  }

  function test_Revert_NonZeroFee() public {
    GPv2Order.Data memory order = correctOrder;
    order.feeAmount = 100;
    vm.expectRevert(IBCoWPool.BCoWPool_FeeMustBeZero.selector);
    bCoWPool.verify(order);
  }

  function test_Revert_InvalidOrderKind(bytes32 _orderKind) public {
    vm.assume(_orderKind != GPv2Order.KIND_SELL);
    GPv2Order.Data memory order = correctOrder;
    order.kind = _orderKind;
    vm.expectRevert(IBCoWPool.BCoWPool_InvalidOperation.selector);
    bCoWPool.verify(order);
  }

  function test_Revert_InvalidBalanceKind(bytes32 _balanceKind) public {
    vm.assume(_balanceKind != GPv2Order.BALANCE_ERC20);
    GPv2Order.Data memory order = correctOrder;
    order.sellTokenBalance = _balanceKind;
    vm.expectRevert(IBCoWPool.BCoWPool_InvalidBalanceMarker.selector);
    bCoWPool.verify(order);
    order = correctOrder;
    order.buyTokenBalance = _balanceKind;
    vm.expectRevert(IBCoWPool.BCoWPool_InvalidBalanceMarker.selector);
    bCoWPool.verify(order);
  }

  function test_Revert_InsufficientReturn(uint256 _buyAmount, uint256 _offset) public {
    _buyAmount = bound(_buyAmount, 1, type(uint128).max);
    _offset = bound(_offset, 1, _buyAmount);
    GPv2Order.Data memory order = correctOrder;
    order.buyAmount = _buyAmount;
    vm.mockCall(tokens[0], abi.encodePacked(IERC20.balanceOf.selector), abi.encode(1 ether));
    vm.mockCall(tokens[1], abi.encodePacked(IERC20.balanceOf.selector), abi.encode(1 ether));
    vm.mockCall(address(bCoWPool), abi.encodePacked(BMath.calcOutGivenIn.selector), abi.encode(_buyAmount - _offset));

    vm.expectRevert(IBPool.BPool_TokenAmountOutBelowMinOut.selector);
    bCoWPool.verify(order);
  }

  function test_Call_CalcOutGivenIn(
    uint256 _sellAmount,
    uint256 _buyTokenBalance,
    uint256 _sellTokenBalance,
    uint256 _inRecordDenorm,
    uint256 _outRecordDenorm
  ) public {
    GPv2Order.Data memory order = correctOrder;
    order.sellAmount = _sellAmount;
    _setRecord(tokens[0], IBPool.Record({bound: true, index: 0, denorm: _inRecordDenorm}));
    _setRecord(tokens[1], IBPool.Record({bound: true, index: 1, denorm: _outRecordDenorm}));
    bCoWPool.mock_call_calcOutGivenIn(
      _sellTokenBalance, _inRecordDenorm, _buyTokenBalance, _outRecordDenorm, _sellAmount, 0, 1
    );
    vm.mockCall(tokens[0], abi.encodePacked(IERC20.balanceOf.selector), abi.encode(_sellTokenBalance));
    vm.mockCall(tokens[1], abi.encodePacked(IERC20.balanceOf.selector), abi.encode(_buyTokenBalance));

    bCoWPool.expect_call_calcOutGivenIn(
      _sellTokenBalance, _inRecordDenorm, _buyTokenBalance, _outRecordDenorm, _sellAmount, 0
    );
    bCoWPool.verify(order);
  }
}
