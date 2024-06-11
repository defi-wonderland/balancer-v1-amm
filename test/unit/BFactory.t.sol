// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";

contract BFactory is Test {
    function test_NewBPoolWhenCalled() external {
        // it should deploy a new newBPool
        // it should add the newBPool to the list of pools
        // it should emit a PoolCreated event
        // it should call set the controller of the newBPool to the caller
        vm.skip(true);
    }

    function test_SetBLabsRevertWhen_TheSenderIsNotTheCurrentSetBLabs() external {
        // it should revert
        vm.skip(true);
    }

    function test_SetBLabsWhenTheSenderIsTheCurrentSetBLabs() external {
        // it should set the new setBLabs address
        // it should emit a BLabsSet event
        vm.skip(true);
    }

    function test_CollectRevertWhen_TheSenderIsNotTheCurrentSetBLabs() external {
        // it should revert
        vm.skip(true);
    }

    modifier whenTheSenderIsTheCurrentSetBLabs() {
        _;
    }

    function test_CollectWhenTheSenderIsTheCurrentSetBLabs() external whenTheSenderIsTheCurrentSetBLabs {
        // it should get the pool's btoken balance of the factory
        // it should transfer the btoken balance of the factory to BLabs
        vm.skip(true);
    }

    function test_CollectRevertWhen_TheBtokenTransferFails() external whenTheSenderIsTheCurrentSetBLabs {
        // it should revert
        vm.skip(true);
    }
}
