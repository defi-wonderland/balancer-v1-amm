// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.25;

import './BMath.sol';
import './BToken.sol';

import {ConditionalOrdersUtilsLib as Utils} from '../cow-swap/ConditionalOrdersUtilsLib.sol';
import {GPv2Order} from '../cow-swap/GPv2Order.sol';
import {IConditionalOrder} from '../cow-swap/IConditionalOrder.sol';
import {IERC1271} from 'interfaces/IERC1271.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';

/**
 * @title CoW AMM
 * @dev Automated market maker based on the concept of function-maximising AMMs.
 * It relies on the CoW Protocol infrastructure to guarantee batch execution of
 * its orders.
 */
abstract contract BaseBCoWPool is IERC1271 {
  using GPv2Order for GPv2Order.Data;

  /// All data used by an order to validate the AMM conditions.
  struct TradingParams {
    // TODO: add BAL related parameters
    /// The app data that must be used in the order.
    /// See `GPv2Order.Data` for more information on the app data.
    bytes32 appData;
  }

  /**
   * @notice The largest possible duration of any AMM order, starting from the
   * current block timestamp.
   */
  uint32 public constant MAX_ORDER_DURATION = 5 * 60;
  /**
   * @notice The value representing the absence of a commitment. It signifies
   * that the AMM will enforce that the order matches the order obtained from
   * calling `getTradeableOrder`.
   */
  bytes32 public constant EMPTY_COMMITMENT = bytes32(0);
  /**
   * @notice The value representing that no trading parameters are currently
   * accepted as valid by this contract, meaning that no trading can occur.
   */
  bytes32 public constant NO_TRADING = bytes32(0);
  /**
   * @notice The transient storage slot specified in this variable stores the
   * value of the order commitment, that is, the only order hash that can be
   * validated by calling `isValidSignature`.
   * The hash corresponding to the constant `EMPTY_COMMITMENT` has special
   * semantics, discussed in the related documentation.
   * @dev This value is:
   * uint256(keccak256("CoWAMM.ConstantProduct.commitment")) - 1
   */
  uint256 public constant COMMITMENT_SLOT = 0x6c3c90245457060f6517787b2c4b8cf500ca889d2304af02043bd5b513e3b593;

  /**
   * @notice The address of the CoW Protocol settlement contract. It is the
   * only address that can set commitments.
   */
  ISettlement public immutable solutionSettler;
  /**
   * @notice The address that can execute administrative tasks on this AMM,
   * as for example enabling/disabling trading or withdrawing funds.
   */
  address public immutable manager;
  /**
   * @notice The domain separator used for hashing CoW Protocol orders.
   */
  bytes32 public immutable solutionSettlerDomainSeparator;

  /**
   * The hash of the data describing which `TradingParams` currently apply
   * to this AMM. If this parameter is set to `NO_TRADING`, then the AMM
   * does not accept any order as valid.
   * If trading is enabled, then this value will be the [`hash`] of the only
   * admissible [`TradingParams`].
   */
  bytes32 public tradingParamsHash;

  /**
   * Emitted when the manager disables all trades by the AMM. Existing open
   * order will not be tradeable. Note that the AMM could resume trading with
   * different parameters at a later point.
   */
  event TradingDisabled();
  /**
   * Emitted when the manager enables the AMM to trade on CoW Protocol.
   * @param hash The hash of the trading parameters.
   * @param params Trading has been enabled for these parameters.
   */
  event TradingEnabled(bytes32 indexed hash, TradingParams params);

  /**
   * @notice This function is permissioned and can only be called by the
   * contract's manager.
   */
  error OnlyManagerCanCall();
  /**
   * @notice The `commit` function can only be called inside a CoW Swap
   * settlement. This error is thrown when the function is called from another
   * context.
   */
  error CommitOutsideOfSettlement();
  /**
   * @notice Error thrown when a solver tries to settle an AMM order on CoW
   * Protocol whose hash doesn't match the one that has been committed to.
   */
  error OrderDoesNotMatchCommitmentHash();
  /**
   * @notice If an AMM order is settled and the AMM committment is set to
   * empty, then that order must match the output of `getTradeableOrder`.
   * This error is thrown when some of the parameters don't match the expected
   * ones.
   */
  error OrderDoesNotMatchDefaultTradeableOrder();
  /**
   * @notice On signature verification, the hash of the order supplied as part
   * of the signature does not match the provided message hash.
   * This usually means that the verification function is being provided a
   * signature that belongs to a different order.
   */
  error OrderDoesNotMatchMessageHash();
  /**
   * @notice The order trade parameters that were provided during signature
   * verification does not match the data stored in this contract _or_ the
   * AMM has not enabled trading.
   */
  error TradingParamsDoNotMatchHash();

  modifier onlyManager() {
    if (manager != msg.sender) {
      revert OnlyManagerCanCall();
    }
    _;
  }

  /**
   * @param _solutionSettler The CoW Protocol contract used to settle user
   * orders on the current chain.
   */
  constructor(ISettlement _solutionSettler) {
    solutionSettler = _solutionSettler;
    solutionSettlerDomainSeparator = _solutionSettler.domainSeparator();
  }

  /**
   * @notice Once this function is called, it will be possible to trade with
   * this AMM on CoW Protocol.
   * @param tradingParams Trading is enabled with the parameters specified
   * here.
   */
  // TODO: move from O(0) to O(1) (mapping tradingParamsHash => true)
  function enableTrading(TradingParams calldata tradingParams) external onlyManager {
    bytes32 _tradingParamsHash = hash(tradingParams);
    tradingParamsHash = _tradingParamsHash;
    emit TradingEnabled(_tradingParamsHash, tradingParams);
  }

  /**
   * @notice Disable any form of trading on CoW Protocol by this AMM.
   */
  function disableTrading() external onlyManager {
    tradingParamsHash = NO_TRADING;
    emit TradingDisabled();
  }

  /**
   * @notice Restricts a specific AMM to being able to trade only the order
   * with the specified hash.
   * @dev The commitment is used to enforce that exactly one AMM order is
   * valid when a CoW Protocol batch is settled.
   * @param orderHash the order hash that will be enforced by the order
   * verification function.
   */
  function commit(bytes32 orderHash) external {
    if (msg.sender != address(solutionSettler)) {
      revert CommitOutsideOfSettlement();
    }
    assembly ("memory-safe") {
      tstore(COMMITMENT_SLOT, orderHash)
    }
  }

  /**
   * @inheritdoc IERC1271
   */
  function isValidSignature(bytes32 _hash, bytes calldata signature) external view returns (bytes4) {
    (GPv2Order.Data memory order, TradingParams memory tradingParams) =
      abi.decode(signature, (GPv2Order.Data, TradingParams));

    if (hash(tradingParams) != tradingParamsHash) {
      revert TradingParamsDoNotMatchHash();
    }
    bytes32 orderHash = order.hash(solutionSettlerDomainSeparator);
    if (orderHash != _hash) {
      revert OrderDoesNotMatchMessageHash();
    }

    requireMatchingCommitment(orderHash, tradingParams, order);

    verify(tradingParams, order);

    // A signature is valid according to EIP-1271 if this function returns
    // its selector as the so-called "magic value".
    return this.isValidSignature.selector;
  }

  /**
   * @notice The order returned by this function is the order that needs to be
   * executed for the price on this AMM to match that of the reference pair.
   * @param tradingParams the trading parameters of all discrete orders cut
   * from this AMM
   * @return order the tradeable order for submission to the CoW Protocol API
   */
  function getTradeableOrder(TradingParams memory tradingParams) public view returns (GPv2Order.Data memory order) {}

  /**
   * @notice This function checks that the input order is admissible for the
   * constant-product curve for the given trading parameters.
   * @param tradingParams the trading parameters of all discrete orders cut
   * from this AMM
   * @param order `GPv2Order.Data` of a discrete order to be verified.
   */
  function verify(TradingParams memory tradingParams, GPv2Order.Data memory order) public view virtual;

  function commitment() public view returns (bytes32 value) {
    assembly ("memory-safe") {
      value := tload(COMMITMENT_SLOT)
    }
  }

  /**
   * @notice Approves the spender to transfer an unlimited amount of tokens
   * and reverts if the approval was unsuccessful.
   * @param token The ERC-20 token to approve.
   * @param spender The address that can transfer on behalf of this contract.
   */
  function approveUnlimited(IERC20 token, address spender) internal {
    token.approve(spender, type(uint256).max);
  }

  /**
   * @notice This function triggers a revert if either (1) the order hash does
   * not match the current commitment, or (2) in the case of a commitment to
   * `EMPTY_COMMITMENT`, the non-constant parameters of the order from
   * `getTradeableOrder` don't match those of the input order.
   * @param orderHash the hash of the current order as defined by the
   * `GPv2Order` library.
   * @param tradingParams the trading parameters of all discrete orders cut
   * from this AMM
   * @param order `GPv2Order.Data` of a discrete order to be verified
   */
  function requireMatchingCommitment(
    bytes32 orderHash,
    TradingParams memory tradingParams,
    GPv2Order.Data memory order
  ) internal view {
    bytes32 committedOrderHash = commitment();

    if (orderHash != committedOrderHash) {
      if (committedOrderHash != EMPTY_COMMITMENT) {
        revert OrderDoesNotMatchCommitmentHash();
      }
      GPv2Order.Data memory computedOrder = getTradeableOrder(tradingParams);
      if (!matchFreeOrderParams(order, computedOrder)) {
        revert OrderDoesNotMatchDefaultTradeableOrder();
      }
    }
  }

  /**
   * @dev Computes an identifier that uniquely represents the parameters in
   * the function input parameters.
   * @param tradingParams Bytestring that decodes to `TradingParams`
   * @return The hash of the input parameter, intended to be used as a unique
   * identifier
   */
  function hash(TradingParams memory tradingParams) public pure returns (bytes32) {
    return keccak256(abi.encode(tradingParams));
  }

  /**
   * @notice Check if the parameters of the two input orders are the same,
   * with the exception of those parameters that have a single possible value
   * that passes the validation of `verify`.
   * @param lhs a CoW Swap order
   * @param rhs another CoW Swap order
   * @return true if the order parameters match, false otherwise
   */
  // TODO: make abstract and implement in the inheriting contract
  function matchFreeOrderParams(GPv2Order.Data memory lhs, GPv2Order.Data memory rhs) internal pure returns (bool) {
    bool sameSellToken = lhs.sellToken == rhs.sellToken;
    bool sameBuyToken = lhs.buyToken == rhs.buyToken;
    bool sameSellAmount = lhs.sellAmount == rhs.sellAmount;
    bool sameBuyAmount = lhs.buyAmount == rhs.buyAmount;
    bool sameValidTo = lhs.validTo == rhs.validTo;
    bool sameKind = lhs.kind == rhs.kind;
    bool samePartiallyFillable = lhs.partiallyFillable == rhs.partiallyFillable;

    // The following parameters are untested:
    // - receiver
    // - appData
    // - feeAmount
    // - sellTokenBalance
    // - buyTokenBalance

    return sameSellToken && sameBuyToken && sameSellAmount && sameBuyAmount && sameValidTo && sameKind
      && samePartiallyFillable;
  }
}
