// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

contract BCoWConst {
  /**
   * @notice The value representing the absence of a commitment.
   * @return _emptyCommitment The commitment value representing no commitment.
   */
  bytes32 public constant EMPTY_COMMITMENT = bytes32(0);

  /**
   * @notice The largest possible duration of any AMM order, starting from the
   * current block timestamp.
   * @return _maxOrderDuration The maximum order duration.
   */
  uint32 public constant MAX_ORDER_DURATION = 5 * 60;
}
