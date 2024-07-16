// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {
  BCoWHelper,
  BMath,
  GPv2Interaction,
  GPv2Order,
  GetTradeableOrder,
  IBCoWFactory,
  IBCoWPool,
  ICOWAMMPoolHelper,
  IERC20
} from '../../src/contracts/BCoWHelper.sol';
import {Test} from 'forge-std/Test.sol';

contract MockBCoWHelper is BCoWHelper, Test {
  // NOTE: manually added methods (internal immutable exposers not supported in smock)
  function call__APP_DATA() external view returns (bytes32) {
    return _APP_DATA;
  }

  // BCoWHelper methods
  constructor(address factory_) BCoWHelper(factory_) {}

  function mock_call_order(
    address pool,
    uint256[] calldata prices,
    GPv2Order.Data memory order_,
    GPv2Interaction.Data[] memory preInteractions,
    GPv2Interaction.Data[] memory postInteractions,
    bytes memory sig
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature('order(address,uint256[])', pool, prices),
      abi.encode(order_, preInteractions, postInteractions, sig)
    );
  }

  function mock_call_tokens(address pool, address[] memory tokens_) public {
    vm.mockCall(address(this), abi.encodeWithSignature('tokens(address)', pool), abi.encode(tokens_));
  }
}
