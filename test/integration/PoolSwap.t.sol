pragma solidity 0.8.25;

import {GPv2TradeEncoder} from './GPv2TradeEncoder.sol';
import {IERC20} from '@cowprotocol/interfaces/IERC20.sol';
import {GPv2Interaction} from '@cowprotocol/libraries/GPv2Interaction.sol';
import {GPv2Order} from '@cowprotocol/libraries/GPv2Order.sol';
import {GPv2Trade} from '@cowprotocol/libraries/GPv2Trade.sol';
import {GPv2Signing} from '@cowprotocol/mixins/GPv2Signing.sol';
import {BCoWConst} from 'contracts/BCoWConst.sol';
import {BCoWPool} from 'contracts/BCoWPool.sol';
import {GasSnapshot} from 'forge-gas-snapshot/GasSnapshot.sol';
import {Test, Vm} from 'forge-std/Test.sol';
import {IBCoWPool} from 'interfaces/IBCoWPool.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';

abstract contract PoolSwapIntegrationTest is Test, BCoWConst, GasSnapshot {
  IBCoWPool public pool;

  IERC20 public dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  IERC20 public weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ISettlement public settlement = ISettlement(0x9008D19f58AAbD9eD0D60971565AA8510560ab41);
  address public solver = address(0xa5559C2E1302c5Ce82582A6b1E4Aec562C2FbCf4);

  address public controller = makeAddr('controller');
  address public lp = makeAddr('lp');
  Vm.Wallet swapper = vm.createWallet('swapper');

  bytes32 public constant APP_DATA = bytes32('exampleIntegrationAppData');

  uint256 public constant HUNDRED_UNITS = 100 ether;
  uint256 public constant ONE_UNIT = 1 ether;
  uint256 public constant WETH_AMOUNT = 0.096397921069149814e18;
  uint256 public constant DAI_AMOUNT = 0.5e18;

  function setUp() public {
    vm.createSelectFork('mainnet', 20_012_063);

    deal(address(dai), address(lp), HUNDRED_UNITS);
    deal(address(weth), address(lp), HUNDRED_UNITS);

    deal(address(dai), address(swapper.addr), ONE_UNIT);

    vm.startPrank(lp);
    // TODO: deploy using BCoWFactory
    pool = new BCoWPool(address(settlement));

    dai.approve(address(pool), type(uint256).max);
    weth.approve(address(pool), type(uint256).max);
    pool.bind(address(dai), ONE_UNIT, 2e18); // 20% weight?
    pool.bind(address(weth), ONE_UNIT, 8e18); // 80%
    // finalize
    pool.finalize();
    // enable trading
    pool.enableTrading(APP_DATA);

    // clean dai and weth from the settlement
    vm.startPrank(address(settlement));
    dai.transfer(address(0), dai.balanceOf(address(settlement)));
    weth.transfer(address(0), weth.balanceOf(address(settlement)));
  }

  function testSimpleSwap() public {
    _makeSwap();
    assertEq(dai.balanceOf(swapper.addr), DAI_AMOUNT);
    // NOTE: hardcoded from test result
    assertEq(weth.balanceOf(swapper.addr), WETH_AMOUNT);

    vm.startPrank(lp);

    uint256 lpBalance = pool.balanceOf(lp);
    pool.exitPool(lpBalance, new uint256[](2));

    // NOTE: no swap fees involved
    assertEq(dai.balanceOf(lp), HUNDRED_UNITS + DAI_AMOUNT); // initial 100 + 0.5 dai
    // NOTE: hardcoded from test result
    assertEq(weth.balanceOf(lp), HUNDRED_UNITS - WETH_AMOUNT); // initial 100 - ~0.09 weth
  }

  function _makeSwap() internal virtual;
}

contract DirectPoolSwapIntegrationTest is PoolSwapIntegrationTest {
  function _makeSwap() internal override {
    vm.startPrank(swapper.addr);
    dai.approve(address(pool), type(uint256).max);

    // swap 0.5 dai for weth
    snapStart('swapExactAmountIn');
    pool.swapExactAmountIn(address(dai), DAI_AMOUNT, address(weth), 0, type(uint256).max);
    snapEnd();

    vm.stopPrank();
  }
}

contract IndirectPoolSwapIntegrationTest is PoolSwapIntegrationTest {
  using GPv2Order for GPv2Order.Data;

  function _makeSwap() internal override {
    uint32 latestValidTimestamp = uint32(block.timestamp) + MAX_ORDER_DURATION - 1;

    // swapper approves weth to vaultRelayer
    vm.startPrank(swapper.addr);
    dai.approve(settlement.vaultRelayer(), type(uint256).max);

    // swapper creates the order
    GPv2Order.Data memory swapperOrder = GPv2Order.Data({
      sellToken: dai,
      buyToken: weth,
      receiver: GPv2Order.RECEIVER_SAME_AS_OWNER,
      sellAmount: DAI_AMOUNT,
      buyAmount: WETH_AMOUNT,
      validTo: latestValidTimestamp,
      appData: APP_DATA,
      feeAmount: 0,
      kind: GPv2Order.KIND_BUY,
      partiallyFillable: false,
      buyTokenBalance: GPv2Order.BALANCE_ERC20,
      sellTokenBalance: GPv2Order.BALANCE_ERC20
    });

    // swapper signs the order
    (uint8 v, bytes32 r, bytes32 s) =
      vm.sign(swapper.privateKey, GPv2Order.hash(swapperOrder, settlement.domainSeparator()));
    bytes memory swapperSig = abi.encodePacked(r, s, v);

    // order for bPool is generated
    GPv2Order.Data memory poolOrder = GPv2Order.Data({
      sellToken: weth,
      buyToken: dai,
      receiver: GPv2Order.RECEIVER_SAME_AS_OWNER,
      sellAmount: WETH_AMOUNT,
      buyAmount: DAI_AMOUNT,
      validTo: latestValidTimestamp,
      appData: APP_DATA,
      feeAmount: 0,
      kind: GPv2Order.KIND_SELL,
      partiallyFillable: true,
      sellTokenBalance: GPv2Order.BALANCE_ERC20,
      buyTokenBalance: GPv2Order.BALANCE_ERC20
    });
    bytes memory poolSig = abi.encode(poolOrder);

    // solver prepares for call settle()
    IERC20[] memory tokens = new IERC20[](2);
    tokens[0] = IERC20(weth);
    tokens[1] = IERC20(dai);

    uint256[] memory clearingPrices = new uint256[](2);
    // TODO: we can use more accurate clearing prices here
    clearingPrices[0] = DAI_AMOUNT;
    clearingPrices[1] = WETH_AMOUNT;

    GPv2Trade.Data[] memory trades = new GPv2Trade.Data[](2);

    // pool's trade
    trades[0] = GPv2Trade.Data({
      sellTokenIndex: 0,
      buyTokenIndex: 1,
      receiver: poolOrder.receiver,
      sellAmount: poolOrder.sellAmount,
      buyAmount: poolOrder.buyAmount,
      validTo: poolOrder.validTo,
      appData: poolOrder.appData,
      feeAmount: poolOrder.feeAmount,
      flags: GPv2TradeEncoder.encodeFlags(poolOrder, GPv2Signing.Scheme.Eip1271),
      executedAmount: poolOrder.sellAmount,
      signature: abi.encodePacked(address(pool), poolSig)
    });

    // swapper's trade
    trades[1] = GPv2Trade.Data({
      sellTokenIndex: 1,
      buyTokenIndex: 0,
      receiver: swapperOrder.receiver,
      sellAmount: swapperOrder.sellAmount,
      buyAmount: swapperOrder.buyAmount,
      validTo: swapperOrder.validTo,
      appData: swapperOrder.appData,
      feeAmount: swapperOrder.feeAmount,
      flags: GPv2TradeEncoder.encodeFlags(swapperOrder, GPv2Signing.Scheme.Eip712),
      executedAmount: swapperOrder.sellAmount,
      signature: swapperSig
    });

    // in the first interactions, save the commitment
    GPv2Interaction.Data[][3] memory interactions =
      [new GPv2Interaction.Data[](1), new GPv2Interaction.Data[](0), new GPv2Interaction.Data[](0)];

    interactions[0][0] = GPv2Interaction.Data({
      target: address(pool),
      value: 0,
      callData: abi.encodeWithSelector(
        IBCoWPool.commit.selector, poolOrder.hash(pool.SOLUTION_SETTLER_DOMAIN_SEPARATOR())
      )
    });

    // finally, settle
    vm.startPrank(solver);
    snapStart('settle');
    settlement.settle(tokens, clearingPrices, trades, interactions);
    snapEnd();
  }
}
