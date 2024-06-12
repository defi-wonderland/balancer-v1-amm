// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {GPv2TradeEncoder} from './GPv2TradeEncoder.sol';
import {IERC20} from '@cowprotocol/interfaces/IERC20.sol';
import {GPv2Interaction} from '@cowprotocol/libraries/GPv2Interaction.sol';
import {GPv2Order} from '@cowprotocol/libraries/GPv2Order.sol';
import {GPv2Trade} from '@cowprotocol/libraries/GPv2Trade.sol';
import {GPv2Signing} from '@cowprotocol/mixins/GPv2Signing.sol';
import {BCoWPool} from 'contracts/BCoWPool.sol';
import {BConst} from 'contracts/BConst.sol';
import {BNum} from 'contracts/BNum.sol';
import {Test, Vm} from 'forge-std/Test.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';

// TODO: add GasSnapshot
contract BCowPoolIntegrationTest is Test, BConst, BNum {
  using GPv2Order for GPv2Order.Data;

  BCoWPool public pool;

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

  function setUp() public {
    vm.createSelectFork('mainnet', 20_012_063);

    // deal controller
    deal(address(dai), controller, HUNDRED_UNITS);
    deal(address(weth), controller, HUNDRED_UNITS);

    // deal LP
    deal(address(dai), address(lp), HUNDRED_UNITS);
    deal(address(weth), address(lp), HUNDRED_UNITS);

    // deal swapper
    deal(address(weth), swapper.addr, ONE_UNIT);

    vm.startPrank(controller);
    // deploy
    // TODO: deploy with BCoWFactory
    pool = new BCoWPool(address(settlement));
    // bind
    dai.approve(address(pool), type(uint256).max);
    weth.approve(address(pool), type(uint256).max);
    IBPool(pool).bind(address(dai), ONE_UNIT, 2e18);
    IBPool(pool).bind(address(weth), ONE_UNIT, 8e18);
    // finalize
    IBPool(pool).finalize();
    // enable trading
    pool.enableTrading(APP_DATA);

    vm.startPrank(lp);
    // join pool
    dai.approve(address(pool), type(uint256).max);
    weth.approve(address(pool), type(uint256).max);
    uint256 _daiToDeposit = bmul(dai.balanceOf(address(pool)), MAX_IN_RATIO);
    uint256 _wethToDeposit = bmul(weth.balanceOf(address(pool)), MAX_IN_RATIO);
    // TODO: join pool using joinPool()
    IBPool(pool).joinswapExternAmountIn(address(dai), _daiToDeposit, 0);
    IBPool(pool).joinswapExternAmountIn(address(weth), _wethToDeposit, 0);
  }

  function testBCowPoolSwap() public {
    vm.skip(true);

    uint256 sellAmount = ONE_UNIT;
    uint256 buyAmount = HUNDRED_UNITS;

    // TODO: add MAX_ORDER_DURATION() to BCoWPool interface
    uint32 latestValidTimestamp = uint32(block.timestamp); // + pool.MAX_ORDER_DURATION();

    // swapper approves weth to vaultRelayer
    vm.prank(swapper.addr);
    weth.approve(settlement.vaultRelayer(), type(uint256).max);

    // swapper creates the order
    GPv2Order.Data memory swapperOrder = GPv2Order.Data({
      sellToken: weth,
      buyToken: dai,
      receiver: GPv2Order.RECEIVER_SAME_AS_OWNER,
      sellAmount: sellAmount,
      buyAmount: buyAmount,
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
      sellToken: dai,
      buyToken: weth,
      receiver: GPv2Order.RECEIVER_SAME_AS_OWNER,
      sellAmount: buyAmount,
      buyAmount: sellAmount,
      validTo: latestValidTimestamp,
      appData: APP_DATA,
      feeAmount: 0,
      kind: GPv2Order.KIND_SELL,
      partiallyFillable: true,
      sellTokenBalance: GPv2Order.BALANCE_ERC20,
      buyTokenBalance: GPv2Order.BALANCE_ERC20
    });
    bytes memory poolSig = abi.encode(poolOrder);

    // solver calls settle()
    IERC20[] memory tokens = new IERC20[](2);
    tokens[0] = IERC20(weth);
    tokens[1] = IERC20(dai);

    uint256[] memory clearingPrices = new uint256[](2);
    clearingPrices[0] = sellAmount;
    clearingPrices[1] = buyAmount;

    GPv2Trade.Data[] memory trades = new GPv2Trade.Data[](2);

    // pool's order
    trades[0] = GPv2Trade.Data({
      sellTokenIndex: 1,
      buyTokenIndex: 0,
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

    // swapper's order
    trades[1] = GPv2Trade.Data({
      sellTokenIndex: 0,
      buyTokenIndex: 1,
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

    // declare the interactions
    GPv2Interaction.Data[][3] memory interactions =
      [new GPv2Interaction.Data[](0), new GPv2Interaction.Data[](0), new GPv2Interaction.Data[](0)];

    bytes32 swapperOrderHash = swapperOrder.hash(settlement.domainSeparator());
    interactions[0] = new GPv2Interaction.Data[](1);
    interactions[0][0] = GPv2Interaction.Data({
      target: address(pool),
      value: 0,
      // TODO: change BCoWPool for IBCoWPool
      callData: abi.encodeWithSelector(BCoWPool.commit.selector, swapperOrderHash)
    });

    vm.prank(solver);
    settlement.settle(tokens, clearingPrices, trades, interactions);

    // TODO: assert balances
  }
}
