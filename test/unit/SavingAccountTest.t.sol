// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {SavingAccount} from "../../src/SavingAccount.sol";
import {DecentralisedStablecoin} from "../../src/DecentralisedStablecoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SavingAccountTest is Test {
    DecentralisedStablecoin dsc;
    SavingAccount saver;
    address user = makeAddr("user");
    address user2 = makeAddr("user2");
    address owner = makeAddr("owner");

    function setUp() public {
        dsc = new DecentralisedStablecoin();
        saver = new SavingAccount(dsc);
    }

    // deposit tests
    function testDepositMustBeMoreThanZeroRevert() public {
        vm.expectRevert(SavingAccount.SavingAccount__MustBeMoreThanZero.selector);
        saver.deposit(0);
    }

    function testDepositUserMappingAndContractBalanceIncreases(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        dsc.mint(user, amount);
        vm.startPrank(user);
        dsc.approve(address(saver), amount);
        saver.deposit(amount);
        vm.stopPrank();
        uint256 contractBalance = dsc.balanceOf(address(saver));
        assertEq(saver.getUserDscDeposited(user), amount);
        assertEq(contractBalance, amount);
    }

    function testDepositAmountMoreThanBalanceRevert(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        dsc.mint(user, amount);
        vm.startPrank(user);
        dsc.approve(address(saver), amount + 1 ether);
        vm.expectRevert(SavingAccount.SavingAccount__InsufficientDscBalance.selector);
        saver.deposit(amount + 1 ether);
        vm.stopPrank();
    }

    // set interest rate tests

    function testInitialInterestRate() public view {
        assertEq((5 * 1e18) / 1e8, saver.getContractInterestRate());
    }

    function testOnlyOwnerCanSetInterestRateRevert() public {
        vm.prank(user);
        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        saver.setInterestRate(10);
    }

    function testInterestRateIsUpdated(uint256 newInterestRate) public {
        newInterestRate = bound(newInterestRate, 0, type(uint96).max);
        saver.setInterestRate(newInterestRate);
        assertEq(newInterestRate, saver.getContractInterestRate());
    }

    // redeem tests

    function testRedeemMustBeMoreThanZero() public {
        vm.expectRevert(SavingAccount.SavingAccount__MustBeMoreThanZero.selector);
        saver.redeem(0);
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        dsc.mint(user, amount);
        uint256 startingUserDscBalance = dsc.balanceOf(user);
        uint256 startingSaverBalance = dsc.balanceOf(address(saver));

        vm.startPrank(user);
        dsc.approve(address(saver), amount);
        saver.deposit(amount);
        uint256 middleUserBalance = dsc.balanceOf(user);
        uint256 middleSaverBalance = dsc.balanceOf(address(saver));

        saver.redeem(amount);
        uint256 endingUserBalance = dsc.balanceOf(user);
        uint256 endingSaverBalance = dsc.balanceOf(address(saver));
        vm.stopPrank();

        assertEq(startingUserDscBalance, amount);
        assertEq(startingSaverBalance, 0);

        assertEq(middleUserBalance, 0);
        assertEq(middleSaverBalance, amount);

        assertEq(endingSaverBalance, 0);
        assertEq(endingUserBalance, amount);
    }

    //     function testRedeemAfterTimeHasPassed(uint256 time, uint256 amount) public {
    //         time = bound(time, 1000, type(uint96).max);
    //         amount = bound(amount, 1e5, type(uint96).max);

    //         dsc.mint(user, amount);
    //         uint256 startingUserDscBalance = dsc.balanceOf(user);
    //         vm.startPrank(user);
    //         dsc.approve(address(saver), amount);
    //         saver.deposit(amount);

    //         vm.warp(block.timestamp + time);

    //         uint256 userBalanceAfterTime
    //         saver.redeem(type(uint256).max);
    //         console.log("user balance after redeem", dsc.balanceOf(user));
    //         uint256 endingUserBalance = dsc.balanceOf(user);
    //         vm.stopPrank();

    //         assertGt(endingUserBalance, startingUserDscBalance);
    //     }
}
