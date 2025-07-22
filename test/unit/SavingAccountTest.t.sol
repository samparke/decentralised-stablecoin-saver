// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {SavingAccount} from "../../src/SavingAccount.sol";
import {DecentralisedStablecoin} from "../../src/DecentralisedStablecoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {Test, console} from "forge-std/Test.sol";

contract SavingAccountTest is Test {
    DecentralisedStablecoin dsc;
    SavingAccount saver;
    address user = makeAddr("user");
    address user2 = makeAddr("user2");
    address owner = makeAddr("owner");
    uint256 constant USER_BALANCE = 100 ether;

    function setUp() public {
        dsc = new DecentralisedStablecoin();
        saver = new SavingAccount(dsc);
        dsc.mint(user, 100 ether);
    }

    function testUserInitialDscBalance() public view {
        uint256 userBalance = dsc.balanceOf(user);
        console.log(userBalance);
        assertEq(userBalance, 100 ether);
    }

    // deposit tests
    function testDepositMustBeMoreThanZeroRevert() public {
        vm.expectRevert(SavingAccount.SavingAccount__MustBeMoreThanZero.selector);
        saver.deposit(0);
    }

    function testDepositUserMappingAndContractBalanceIncreases() public {
        vm.startPrank(user);
        dsc.approve(address(saver), USER_BALANCE);
        saver.deposit(USER_BALANCE);
        vm.stopPrank();
        uint256 contractBalance = dsc.balanceOf(address(saver));
        assertEq(saver.getUserDscDeposited(user), USER_BALANCE);
        assertEq(contractBalance, USER_BALANCE);
    }

    function testDepositAmountMoreThanBalanceRevert() public {
        vm.startPrank(user);
        dsc.approve(address(saver), USER_BALANCE + 1 ether);
        vm.expectRevert(SavingAccount.SavingAccount__InsufficientDscBalance.selector);
        saver.deposit(USER_BALANCE + 1 ether);
        vm.stopPrank();
    }
}
