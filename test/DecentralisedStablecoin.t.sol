// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DecentralisedStablecoin} from "../src/DecentralisedStablecoin.sol";
import {DeployDSC} from "../script/DeployDSC.s.sol";

contract DecentralisedStablecoinTest is Test {
    DecentralisedStablecoin dsc;

    function setUp() public {
        dsc = new DecentralisedStablecoin();
    }

    function testInitialBalanceIsZero() public view {
        uint256 balance = dsc.balanceOf(msg.sender);
        assertEq(balance, 0);
    }

    // MINT FUNCTIONS
    function testMint() public {
        bool mintSuccess = dsc.mint(msg.sender, 1 ether);
        uint256 balance = dsc.balanceOf(msg.sender);

        assertTrue(mintSuccess);
        assertEq(balance, 1 ether);
    }

    function testMintRevertsWithZero() public {
        vm.expectRevert();
        dsc.mint(msg.sender, 0 ether);
    }
}
