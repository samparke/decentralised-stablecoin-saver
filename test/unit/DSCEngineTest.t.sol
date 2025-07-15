// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DecentralisedStablecoin} from "../../src/DecentralisedStablecoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

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

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(user, STARTING_ERC20_BALANCE);
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
}
