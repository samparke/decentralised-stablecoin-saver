// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DecentralisedStablecoin} from "../../src/DecentralisedStablecoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {MockMintFail} from "../mocks/MockMintFail.sol";

contract DSCEngineTest is Test {
    DecentralisedStablecoin dsc;
    DeployDSC deployer;
    DSCEngine dsce;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address public user = makeAddr("user");
    uint256 STARTING_ERC20_BALANCE = 10 ether;
    uint256 amountCollateral = 10 ether;
    uint256 amountMint = 100 ether;
    uint256 amountBurn = 1 ether;

    address[] tokenAddresses;
    address[] priceFeedAddresses;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(user, STARTING_ERC20_BALANCE);
    }

    // MODIFERS
    modifier depositCollateral() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(weth, amountCollateral);
        vm.stopPrank();
        _;
    }

    // GETTER TESTS

    function testGetPrecision() public view {
        assertEq(dsce.getPrecision(), 1e18);
    }

    function testGetAdditionalFeedPrecision() public view {
        assertEq(dsce.getAdditionalFeedPrecision(), 1e10);
    }

    function testGetMinHealthFactor() public view {
        assertEq(dsce.getMinHealthFactor(), 1e18);
    }

    function testGetLiquidationPrecision() public view {
        assertEq(dsce.getLiquidationPrecision(), 100);
    }

    function testGetLiquidationThreshold() public view {
        assertEq(dsce.getLiquidationThreshold(), 50);
    }

    function testGetLiquidationBonus() public view {
        assertEq(dsce.getLiquidationBonus(), 10);
    }

    // DEPOSIT COLLATERAL TESTS
    function testDepositCollateralMustBeMoreThanZeroRevert() public {
        vm.prank(user);
        vm.expectRevert();
        dsce.depositCollateral(weth, 0);
    }

    function testDepositCollateralSuccessfullyTransferedToDsce() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(weth, amountCollateral);
        uint256 contractBalance = ERC20Mock(weth).balanceOf(address(dsce));
        vm.stopPrank();
        assertEq(contractBalance, amountCollateral);
    }

    // MINT TESTS
    function testMintDscSuccess() public depositCollateral {
        vm.startPrank(user);
        dsce.mintDsc(amountMint);
        uint256 dscBalanceOfUser = dsc.balanceOf(user);
        vm.stopPrank();
        assertEq(dscBalanceOfUser, amountMint);
    }

    function testMintMustBeMoreThanZeroRevert() public depositCollateral {
        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine__MustBeMoreThanZero.selector);
        dsce.mintDsc(0);
        vm.stopPrank();
    }

    function testMintUserMintedMappingIncreases() public depositCollateral {
        uint256 dscMintedBefore = dsce.getUserDscMinted(address(user));
        vm.startPrank(user);
        dsce.mintDsc(amountMint);
        vm.stopPrank();
        uint256 dscMintedAfter = dsce.getUserDscMinted(address(user));
        assert(dscMintedAfter > dscMintedBefore);
    }

    function testMintFail() public {
        MockMintFail mockToken = new MockMintFail();
        tokenAddresses = [weth];
        priceFeedAddresses = [ethUsdPriceFeed];
        address owner = makeAddr("owner");
        vm.prank(owner);
        DSCEngine mockDsce = new DSCEngine(tokenAddresses, priceFeedAddresses, address(mockToken));
        mockToken.transferOwnership(address(mockDsce));

        vm.startPrank(user);
        ERC20Mock(weth).approve(address(mockDsce), amountCollateral);
        mockDsce.depositCollateral(weth, amountCollateral);
        vm.expectRevert(DSCEngine.DSCEngine__MintFailed.selector);
        mockDsce.mintDsc(amountMint);
        vm.stopPrank();
    }

    // BURN TESTS
    function testBurnSuccessUserDscDecreases() public depositCollateral {
        vm.startPrank(user);
        dsce.mintDsc(amountMint);
        uint256 dscBalanceBefore = dsc.balanceOf(address(user));
        dsc.approve(address(dsce), amountBurn);
        dsce.burnDsc(amountBurn);
        vm.stopPrank();
        uint256 dscBalanceAfter = dsc.balanceOf(address(user));
        assert(dscBalanceBefore > dscBalanceAfter);
    }

    function testBurnMustBeMoreThanZeroRevert() public {
        vm.expectRevert(DSCEngine.DSCEngine__MustBeMoreThanZero.selector);
        dsce.burnDsc(0);
    }

    function testBurnUserMintedMappingDecreases() public depositCollateral {
        vm.startPrank(user);
        dsce.mintDsc(amountMint);
        uint256 dscMintedBefore = dsce.getUserDscMinted(address(user));
        dsc.approve(address(dsce), amountBurn);
        dsce.burnDsc(amountBurn);
        vm.stopPrank();
        uint256 dscMintedAfter = dsce.getUserDscMinted(address(user));
        assert(dscMintedBefore > dscMintedAfter);
    }
}
