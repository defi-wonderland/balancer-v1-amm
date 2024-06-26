// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Test} from 'forge-std/Test.sol';
import {IBPool} from 'interfaces/IBPool.sol';
import {MockBFactory} from 'test/smock/MockBFactory.sol';

abstract contract Base is Test {
  IBFactory public bFactory;
  address public owner = makeAddr('owner');

  function _configureBFactory() internal virtual returns (IBFactory);

  function _bPoolBytecode() internal virtual returns (bytes memory);

  function setUp() public virtual {
    bFactory = _configureBFactory();
  }
}

abstract contract BaseBFactory_Unit_Constructor is Base {
  /**
   * @notice Test that the owner is set correctly
   */
  function test_Deploy() public view {
    assertEq(owner, bFactory.getBLabs());
  }
}

abstract contract BaseBFactory_Internal_NewBPool is Base {
  function test_Deploy_NewBPool() public {
    IBPool _pool = MockBFactory(address(bFactory)).call__newBPool();

    assertEq(_bPoolBytecode(), address(_pool).code);
  }
}

abstract contract BaseBFactory_Unit_NewBPool is Base {
  /**
   * @notice Test that the pool is set on the mapping
   */
  function test_Set_Pool() public {
    IBPool _pool = bFactory.newBPool();
    assertTrue(bFactory.isBPool(address(_pool)));
  }

  /**
   * @notice Test that event is emitted
   */
  function test_Emit_Log(address _randomCaller) public {
    assumeNotForgeAddress(_randomCaller);

    vm.expectEmit();
    address _expectedPoolAddress = vm.computeCreateAddress(address(bFactory), 1);
    emit IBFactory.LOG_NEW_POOL(_randomCaller, _expectedPoolAddress);
    vm.prank(_randomCaller);
    bFactory.newBPool();
  }

  /**
   * @notice Test that msg.sender is set as the controller
   */
  function test_Set_Controller(address _randomCaller) public {
    assumeNotForgeAddress(_randomCaller);

    vm.prank(_randomCaller);
    IBPool _pool = bFactory.newBPool();
    assertEq(_randomCaller, _pool.getController());
  }

  /**
   * @notice Test that the pool address is returned
   */
  function test_Returns_Pool() public {
    address _expectedPoolAddress = vm.computeCreateAddress(address(bFactory), 1);
    IBPool _pool = bFactory.newBPool();
    assertEq(_expectedPoolAddress, address(_pool));
  }

  /**
   * @notice Test that the internal function is called
   */
  function test_Call_NewBPool(address _bPool) public {
    assumeNotForgeAddress(_bPool);
    MockBFactory(address(bFactory)).mock_call__newBPool(IBPool(_bPool));
    MockBFactory(address(bFactory)).expectCall__newBPool();
    vm.mockCall(_bPool, abi.encodeWithSignature('setController(address)'), abi.encode());

    IBPool _pool = bFactory.newBPool();

    assertEq(_bPool, address(_pool));
  }
}

import {BCoWPool} from 'contracts/BCoWPool.sol';
import {IBCoWFactory} from 'interfaces/IBCoWFactory.sol';
import {IBCoWPool} from 'interfaces/IBCoWPool.sol';
import {IBFactory} from 'interfaces/IBFactory.sol';
import {ISettlement} from 'interfaces/ISettlement.sol';
import {MockBCoWFactory} from 'test/manual-smock/MockBCoWFactory.sol';

abstract contract BCoWFactoryTest is Base {
  address public solutionSettler = makeAddr('solutionSettler');
  bytes32 public appData = bytes32('appData');

  function _configureBFactory() internal override returns (IBFactory) {
    vm.mockCall(solutionSettler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(bytes32(0)));
    vm.mockCall(
      solutionSettler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(makeAddr('vault relayer'))
    );
    vm.prank(owner);
    return new MockBCoWFactory(solutionSettler, appData);
  }

  function _bPoolBytecode() internal virtual override returns (bytes memory _bytecode) {
    // NOTE: "runtimeCode" is not available for contracts containing immutable variables.
    // so we the easiest way to know the bytecode is to deploy it with the same
    // parameters the factory would
    return address(new BCoWPool(solutionSettler, appData)).code;
  }
}

contract BCoWFactory_Unit_Constructor is BaseBFactory_Unit_Constructor, BCoWFactoryTest {
  function test_Set_SolutionSettler(address _settler) public {
    MockBCoWFactory factory = new MockBCoWFactory(_settler, appData);
    assertEq(factory.SOLUTION_SETTLER(), _settler);
  }

  function test_Set_AppData(bytes32 _appData) public {
    MockBCoWFactory factory = new MockBCoWFactory(solutionSettler, _appData);
    assertEq(factory.APP_DATA(), _appData);
  }
}

contract BCoWFactory_Unit_NewBPool is BaseBFactory_Unit_NewBPool, BCoWFactoryTest {
  function test_Set_SolutionSettler(address _settler) public {
    assumeNotForgeAddress(_settler);
    bFactory = new MockBCoWFactory(_settler, appData);
    vm.mockCall(_settler, abi.encodePacked(ISettlement.domainSeparator.selector), abi.encode(bytes32(0)));
    vm.mockCall(_settler, abi.encodePacked(ISettlement.vaultRelayer.selector), abi.encode(makeAddr('vault relayer')));
    IBCoWPool bCoWPool = IBCoWPool(address(bFactory.newBPool()));
    assertEq(address(bCoWPool.SOLUTION_SETTLER()), _settler);
  }

  function test_Set_AppData(bytes32 _appData) public {
    bFactory = new MockBCoWFactory(solutionSettler, _appData);
    IBCoWPool bCoWPool = IBCoWPool(address(bFactory.newBPool()));
    assertEq(bCoWPool.APP_DATA(), _appData);
  }
}

contract BCoWPoolFactory_Unit_LogBCoWPool is BCoWFactoryTest {
  function test_Revert_NotValidBCoWPool(address _pool) public {
    bFactory = new MockBCoWFactory(solutionSettler, appData);
    MockBCoWFactory(address(bFactory)).set__isBPool(address(_pool), false);

    vm.expectRevert(IBCoWFactory.BCoWFactory_NotValidBCoWPool.selector);

    vm.prank(_pool);
    IBCoWFactory(address(bFactory)).logBCoWPool();
  }

  function test_Emit_COWAMMPoolCreated(address _pool) public {
    bFactory = new MockBCoWFactory(solutionSettler, appData);
    MockBCoWFactory(address(bFactory)).set__isBPool(address(_pool), true);
    vm.expectEmit(address(bFactory));
    emit IBCoWFactory.COWAMMPoolCreated(_pool);

    vm.prank(_pool);
    IBCoWFactory(address(bFactory)).logBCoWPool();
  }
}

// solhint-disable-next-line no-empty-blocks
contract BCoWFactory_Internal_NewBPool is BaseBFactory_Internal_NewBPool, BCoWFactoryTest {}
