// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {Test} from 'forge-std/Test.sol';

import {IERC20} from '@cowprotocol/interfaces/IERC20.sol';

import {IBCoWPool} from 'interfaces/IBCoWPool.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';

import {ICOWAMMPoolHelper} from '@cow-amm/interfaces/ICOWAMMPoolHelper.sol';
import {GPv2Interaction} from '@cowprotocol/libraries/GPv2Interaction.sol';
import {GPv2Order} from '@cowprotocol/libraries/GPv2Order.sol';
import {GPv2Trade} from '@cowprotocol/libraries/GPv2Trade.sol';
import {GPv2Signing} from '@cowprotocol/mixins/GPv2Signing.sol';

import {GPv2TradeEncoder} from '@composable-cow/test/vendored/GPv2TradeEncoder.sol';

import {BCoWFactory} from 'contracts/BCoWFactory.sol';
import {BCoWHelper} from 'contracts/BCoWHelper.sol';

contract ConstantProductHelperForkedTest is Test {
  using GPv2Order for GPv2Order.Data;

  BCoWHelper private helper;

  // All hardcoded addresses are mainnet addresses
  address public lp = makeAddr('lp');

  ISettlement private settlement = ISettlement(0x9008D19f58AAbD9eD0D60971565AA8510560ab41);
  address private vaultRelayer;

  address private solver = 0x423cEc87f19F0778f549846e0801ee267a917935;

  BCoWFactory private ammFactory;
  IBPool private weightedPool;
  IBPool private basicPool;

  IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  IERC20 private constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  IERC20 private constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  uint256 constant VALID_AMOUNT = 1e6;
  uint256 constant TEN_PERCENT = 0.1 ether;

  function setUp() public {
    vm.createSelectFork('mainnet', 20_012_063);

    vaultRelayer = address(settlement.vaultRelayer());

    ammFactory = new BCoWFactory(address(settlement), bytes32('appData'));
    helper = new BCoWHelper(address(ammFactory));

    deal(address(DAI), lp, 2 * VALID_AMOUNT);
    deal(address(WETH), lp, 2 * VALID_AMOUNT);

    vm.startPrank(lp);
    weightedPool = ammFactory.newBPool();
    basicPool = ammFactory.newBPool();

    DAI.approve(address(weightedPool), type(uint256).max);
    WETH.approve(address(weightedPool), type(uint256).max);
    weightedPool.bind(address(DAI), VALID_AMOUNT, 8e18); // 80% weight
    weightedPool.bind(address(WETH), VALID_AMOUNT, 2e18); // 20% weight

    DAI.approve(address(basicPool), type(uint256).max);
    WETH.approve(address(basicPool), type(uint256).max);
    basicPool.bind(address(DAI), VALID_AMOUNT, 4.2e18); // no weight
    basicPool.bind(address(WETH), VALID_AMOUNT, 4.2e18); // no weight

    // finalize
    weightedPool.finalize();
    basicPool.finalize();

    vm.stopPrank();
  }

  // NOTE: 1 ETH = 1000e6 DAI
  uint256 constant INITIAL_SPOT_PRICE = 0.001e18;

  function testBasicOrder() public {
    IBCoWPool pool = IBCoWPool(address(basicPool));

    uint256 ammWethInitialBalance = 1 ether;
    uint256 ammDaiInitialBalance = 1000 ether;

    deal(address(WETH), address(pool), ammWethInitialBalance);
    deal(address(DAI), address(pool), ammDaiInitialBalance);

    uint256 spotPrice = pool.getSpotPriceSansFee(address(WETH), address(DAI));
    assertEq(spotPrice, INITIAL_SPOT_PRICE);

    _executeHelperOrder(pool, ammWethInitialBalance, ammDaiInitialBalance);

    uint256 postSpotPrice = pool.getSpotPriceSansFee(address(WETH), address(DAI));
    assertEq(postSpotPrice, 1_052_631_578_947_368);
  }

  // NOTE: reverting test, weighted pools are not supported
  function testWeightedOrder() public {
    IBCoWPool pool = IBCoWPool(address(weightedPool));

    uint256 ammWethInitialBalance = 1 ether;
    uint256 ammDaiInitialBalance = 1000 ether;

    deal(address(WETH), address(pool), ammWethInitialBalance);
    // NOTE: pool is 80-20 DAI-WETH, has 4xDAI balance than basic, same spot price
    deal(address(DAI), address(pool), 4 * ammDaiInitialBalance);

    uint256 spotPrice = pool.getSpotPriceSansFee(address(WETH), address(DAI));
    assertEq(spotPrice, INITIAL_SPOT_PRICE);

    vm.expectRevert(ICOWAMMPoolHelper.PoolDoesNotExist.selector);
    helper.order(address(pool), new uint256[](2));

    // NOTE: not supported
    // _executeHelperOrder(pool, ammWethInitialBalance, ammDaiInitialBalance);
    // uint256 postSpotPrice = pool.getSpotPriceSansFee(address(WETH), address(DAI));
    // assertEq(postSpotPrice, 1_052_631_578_947_368);
  }

  function addressVecToIerc20Vec(address[] memory addrVec) private pure returns (IERC20[] memory ierc20vec) {
    assembly {
      ierc20vec := addrVec
    }
  }

  function _executeHelperOrder(IBPool pool, uint256 ammWethInitialBalance, uint256 ammDaiInitialBalance) internal {
    IERC20[] memory tokens = addressVecToIerc20Vec(helper.tokens(address(pool)));
    uint256 daiIndex = 0;
    uint256 wethIndex = 1;
    assertEq(tokens.length, 2);
    assertEq(address(tokens[daiIndex]), address(DAI));
    assertEq(address(tokens[wethIndex]), address(WETH));

    // Prepare the price vector used in the execution of the settlement in
    // CoW Protocol. We skew the price by ~5% towards a cheaper WETH, so
    // that the AMM wants to buy WETH.
    uint256[] memory prices = new uint256[](2);
    // Note: oracle price are expressed in the same format as prices in
    // a call to `settle`, where the  price vector is expressed so that
    // if the first token is DAI and the second WETH then a price of 3000
    // DAI per WETH means a price vector of [1, 3000] (if the decimals are
    // different, as in WETH/USDC, then the atom amount is what counts).
    prices[daiIndex] = ammWethInitialBalance;
    prices[wethIndex] = ammDaiInitialBalance * 95 / 100;

    // The helper generates the AMM order
    GPv2Order.Data memory ammOrder;
    GPv2Interaction.Data[] memory preInteractions;
    GPv2Interaction.Data[] memory postInteractions;
    bytes memory sig;
    (ammOrder, preInteractions, postInteractions, sig) = helper.order(address(pool), prices);

    // We expect a commit interaction in pre interactions
    assertEq(preInteractions.length, 1);
    assertEq(postInteractions.length, 0);

    // Because of how we changed the price, we expect to buy DAI
    assertEq(address(ammOrder.sellToken), address(DAI));
    assertEq(address(ammOrder.buyToken), address(WETH));

    // Check that the amounts and price aren't unreasonable. We changed the
    // price by about 5%, so the amounts aren't expected to change
    // significantly more (say, about 2.5% of the original balance).
    assertApproxEqRel(ammOrder.sellAmount, ammDaiInitialBalance * 25 / 1000, TEN_PERCENT);
    assertApproxEqRel(ammOrder.buyAmount, ammWethInitialBalance * 25 / 1000, TEN_PERCENT);

    GPv2Trade.Data[] memory trades = new GPv2Trade.Data[](1);

    // pool's trade
    trades[0] = GPv2Trade.Data({
      sellTokenIndex: 0,
      buyTokenIndex: 1,
      receiver: ammOrder.receiver,
      sellAmount: ammOrder.sellAmount,
      buyAmount: ammOrder.buyAmount,
      validTo: ammOrder.validTo,
      appData: ammOrder.appData,
      feeAmount: ammOrder.feeAmount,
      flags: GPv2TradeEncoder.encodeFlags(ammOrder, GPv2Signing.Scheme.Eip1271),
      executedAmount: ammOrder.sellAmount,
      signature: sig
    });

    GPv2Interaction.Data[][3] memory interactions =
      [new GPv2Interaction.Data[](1), new GPv2Interaction.Data[](0), new GPv2Interaction.Data[](0)];

    interactions[0][0] = preInteractions[0];

    // finally, settle
    vm.prank(solver);
    settlement.settle(tokens, prices, trades, interactions);
  }
}
