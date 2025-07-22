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
    uint256 constant STARTING_USER_BALANCE = 100 ether;
    uint256 constant STARTING_SAVER_BALANCE = 1000 ether;

    function setUp() public {
        dsc = new DecentralisedStablecoin();
        saver = new SavingAccount(dsc);
        dsc.mint(user, STARTING_USER_BALANCE);
        dsc.mint(address(saver), STARTING_SAVER_BALANCE);
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
        dsc.approve(address(saver), STARTING_USER_BALANCE);
        saver.deposit(STARTING_USER_BALANCE);
        vm.stopPrank();
        uint256 contractBalance = dsc.balanceOf(address(saver));
        assertEq(saver.getUserDscDeposited(user), STARTING_USER_BALANCE);
        assertEq(contractBalance, STARTING_USER_BALANCE);
    }

    function testDepositAmountMoreThanBalanceRevert() public {
        vm.startPrank(user);
        dsc.approve(address(saver), STARTING_USER_BALANCE + 1 ether);
        vm.expectRevert(SavingAccount.SavingAccount__InsufficientDscBalance.selector);
        saver.deposit(STARTING_USER_BALANCE + 1 ether);
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

    function testRedeemStraightAway() public {
        uint256 startingUserDscBalance = dsc.balanceOf(user);
        uint256 startingSaverBalance = dsc.balanceOf(address(saver));
        vm.startPrank(user);
        dsc.approve(address(saver), STARTING_USER_BALANCE);
        saver.deposit(STARTING_USER_BALANCE);
        uint256 middleUserBalance = dsc.balanceOf(user);
        uint256 middleSaverBalance = dsc.balanceOf(address(saver));
        saver.redeem(STARTING_USER_BALANCE);
        uint256 endingUserBalance = dsc.balanceOf(user);
        uint256 endingSaverBalance = dsc.balanceOf(address(saver));
        vm.stopPrank();

        assertEq(startingUserDscBalance, STARTING_USER_BALANCE);
        assertEq(startingSaverBalance, STARTING_SAVER_BALANCE);

        assertEq(middleUserBalance, 0);
        assertEq(middleSaverBalance, STARTING_SAVER_BALANCE + STARTING_USER_BALANCE);

        assertEq(endingSaverBalance, STARTING_SAVER_BALANCE);
        assertEq(endingUserBalance, STARTING_USER_BALANCE);
    }
}
