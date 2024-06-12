// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from '@cowprotocol/interfaces/IERC20.sol';
import {GPv2Order} from '@cowprotocol/libraries/GPv2Order.sol';
import {BCoWPool} from 'contracts/BCoWPool.sol';

import {BConst} from 'contracts/BConst.sol';
import {BNum} from 'contracts/BNum.sol';
import {Test} from 'forge-std/Test.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';

// TODO: add GasSnapshot
contract BCowPoolIntegrationTest is Test, BConst, BNum {
  BCoWPool public pool;

  IERC20 public dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  IERC20 public weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ISettlement public settlement = ISettlement(0x9008D19f58AAbD9eD0D60971565AA8510560ab41);

  address public controller = makeAddr('controller');
  address public lp = makeAddr('lp');
  address public swapper = makeAddr('swapper');
  address public solver = makeAddr('solver');

  bytes32 public constant APP_DATA = bytes32('exampleIntegrationAppData');

  function setUp() public {
    vm.createSelectFork('mainnet', 12_593_265);

    // deal controller
    deal(address(dai), controller, 100e18);
    deal(address(weth), controller, 100e18);

    // deal LP
    deal(address(dai), address(lp), 100e18);
    deal(address(weth), address(lp), 100e18);

    // deal swapper
    deal(address(weth), address(swapper), 1e18);

    vm.startPrank(controller);
    // deploy
    // TODO: deploy with BCoWFactory
    pool = new BCoWPool(address(settlement));
    // bind
    dai.approve(address(pool), type(uint256).max);
    weth.approve(address(pool), type(uint256).max);
    IBPool(pool).bind(address(dai), 1e18, 2e18);
    IBPool(pool).bind(address(weth), 1e18, 8e18);
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

    // ConstantProduct.TradingParams memory data = ConstantProduct.TradingParams({
    //     minTradedToken0: minTradedToken0,
    //     priceOracle: uniswapV2PriceOracle,
    //     priceOracleData: priceOracleData,
    //     appData: appData
    // });

    uint256 sellAmount = 1 ether;
    uint256 buyAmount = 100 ether;

    // swapper approves weth to vaultRelayer
    vm.prank(swapper);
    // TODO: add vaultRelayer() to BCoWPool interface
    // weth.approve(pool.vaultRelayer(), type(uint256).max);

    // swapper creates the order
    // TODO: add MAX_ORDER_DURATION() to BCoWPool interface
    uint32 latestValidTimestamp = uint32(block.timestamp); // + pool.MAX_ORDER_DURATION();
    GPv2Order.Data memory order = GPv2Order.Data({
      sellToken: weth,
      buyToken: dai,
      receiver: GPv2Order.RECEIVER_SAME_AS_OWNER,
      sellAmount: sellAmount,
      buyAmount: buyAmount,
      validTo: latestValidTimestamp,
      appData: APP_DATA,
      feeAmount: 0,
      kind: GPv2Order.KIND_SELL,
      partiallyFillable: true,
      sellTokenBalance: GPv2Order.BALANCE_ERC20,
      buyTokenBalance: GPv2Order.BALANCE_ERC20
    });
    // TODO: use `data` struct
    // bytes memory sig = abi.encode(order, data);
    bytes memory sig = abi.encode(order, '');

    // order for bPool is generated

    // solver checks isValidSignature

    // solver calls settle()
  }
}
