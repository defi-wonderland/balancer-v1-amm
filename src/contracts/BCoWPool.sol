// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import './BMath.sol';
import './BToken.sol';

import {GPv2Order} from '../cow-swap/GPv2Order.sol';

import {BPool} from './BPool.sol';
import {IBCoWPool} from 'interfaces/IBCoWPool.sol';

import {IERC1271} from 'interfaces/IERC1271.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';

contract BCoWPool is BPool, IBCoWPool {
  using GPv2Order for GPv2Order.Data;

  /**
   * @notice The address that can pull funds from the AMM vault to execute an order
   */
  address public immutable vaultRelayer;

  /**
   * @notice The domain separator used for hashing CoW Protocol orders.
   */
  bytes32 public immutable solutionSettlerDomainSeparator;

  /**
   * @notice The value representing the absence of a commitment.
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
   * TODO: review natspec
   * The hash of the data describing which `TradingParams` currently apply
   * to this AMM. If this parameter is set to `NO_TRADING`, then the AMM
   * does not accept any order as valid.
   * If trading is enabled, then this value will be the [`hash`] of the only
   * admissible [`TradingParams`].
   */
  mapping(bytes32 => bool) public tradingParamsHash;

  constructor(address _cowSolutionSettler) BPool() {
    solutionSettler = ISettlement(_cowSolutionSettler);
    solutionSettlerDomainSeparator = ISettlement(_cowSolutionSettler).domainSeparator();
    vaultRelayer = ISettlement(_cowSolutionSettler).vaultRelayer();
  }

  /**
   * @notice This function checks that the input order is admissible for the
   * constant-product curve for the given trading parameters.
   * @param tradingParams the trading parameters of all discrete orders cut
   * from this AMM
   * @param order `GPv2Order.Data` of a discrete order to be verified.
   */
  function verify(TradingParams memory tradingParams, GPv2Order.Data memory order) public view {
    Record memory inRecord = _records[address(order.sellToken)];
    Record memory outRecord = _records[address(order.buyToken)];

    uint256 tokenAmountOut = calcOutGivenIn(
      order.sellToken.balanceOf(address(this)),
      inRecord.denorm,
      order.buyToken.balanceOf(address(this)),
      outRecord.denorm,
      order.sellAmount,
      0
    );

    // TODO: Add more checks depending on the order data
    require(tokenAmountOut >= order.buyAmount, 'BCoWPool: INSUFFICIENT_OUTPUT_AMOUNT');

    // NOTE: struct is just to temporarily display the information inside GPv2Order.Data
    GPv2Order.Data({
      sellToken: tradingParams.sellToken,
      buyToken: tradingParams.buyToken,
      receiver: address(0),
      sellAmount: order.sellAmount,
      buyAmount: order.buyAmount,
      validTo: uint32(0),
      appData: order.appData,
      feeAmount: uint256(0),
      kind: bytes32(0),
      partiallyFillable: false,
      sellTokenBalance: bytes32(0),
      buyTokenBalance: bytes32(0)
    });
  }

  /**
   * @notice Once this function is called, it will be possible to trade with
   * this AMM on CoW Protocol.
   * @param tradingParams Trading is enabled with the parameters specified
   * here.
   */
  // TODO: unify with BPool
  function enableTrading(TradingParams calldata tradingParams) external onlyController {
    bytes32 _tradingParamsHash = hash(tradingParams);
    tradingParamsHash[_tradingParamsHash] = true;
    emit TradingEnabled(_tradingParamsHash, tradingParams);
  }

  /**
   * @notice Disable a specific form of trading on CoW Protocol by this AMM.
   */
  // TODO: unify with BPool
  function disableTrading(TradingParams calldata tradingParams) external onlyController {
    bytes32 _tradingParamsHash = hash(tradingParams);
    tradingParamsHash[_tradingParamsHash] = false;
    emit TradingDisabled(_tradingParamsHash, tradingParams);
  }

  /**
   * @notice Disable any form of trading on CoW Protocol by this AMM.
   */
  // TODO: unify with BPool
  function disableTrading() external onlyController {
    // TODO: loop through tokens and set tradingParamsHash[tokenA,tokenB] = false
    tradingParamsHash[NO_TRADING];
    // tradingParamsHash = NO_TRADING;
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

    if (!tradingParamsHash[hash(tradingParams)]) {
      revert TradingParamsDoNotMatchHash();
    }
    bytes32 orderHash = order.hash(solutionSettlerDomainSeparator);
    if (orderHash != _hash) {
      revert OrderDoesNotMatchMessageHash();
    }

    requireMatchingCommitment(orderHash);

    verify(tradingParams, order);

    // A signature is valid according to EIP-1271 if this function returns
    // its selector as the so-called "magic value".
    return this.isValidSignature.selector;
  }

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
   */
  function requireMatchingCommitment(bytes32 orderHash) internal view {
    bytes32 committedOrderHash = commitment();

    if (orderHash != committedOrderHash) {
      if (committedOrderHash != EMPTY_COMMITMENT) {
        revert OrderDoesNotMatchCommitmentHash();
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
   * @dev Grants infinite approval to the vault relayer for all tokens in the
   * pool after the finalization of the setup.
   */
  function _afterFinalize() internal override {
    for (uint256 i; i < _tokens.length; i++) {
      address token = _tokens[i];
      approveUnlimited(IERC20(token), vaultRelayer);
    }
  }

  // TODO: unify with BPool
  modifier onlyController() {
    require(msg.sender == _controller, 'ERR_NOT_CONTROLLER');
    _;
  }
}
