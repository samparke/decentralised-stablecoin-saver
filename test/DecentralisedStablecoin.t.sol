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
        vm.expectRevert(DecentralisedStablecoin.DecentralisedStablecoin__NeedsMoreThanZero.selector);
        dsc.mint(msg.sender, 0 ether);
    }

    // BURN FUNCTION
    function testBurn() public {
        dsc.mint(address(this), 1 ether);
        dsc.burn(0.5 ether);
        uint256 balance = dsc.balanceOf(address(this));
        assertEq(balance, 0.5 ether);
    }

    function testBurnRevertsWithZero() public {
        vm.expectRevert(DecentralisedStablecoin.DecentralisedStablecoin__NeedsMoreThanZero.selector);
        dsc.burn(0);
    }

    function testBurnRevertsIfInsufficentBalance() public {
        vm.expectRevert(DecentralisedStablecoin.DecentralisedStablecoin__BurnMoreThanBalance.selector);
        dsc.burn(1 ether);
    }
}
