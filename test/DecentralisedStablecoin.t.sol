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
}
