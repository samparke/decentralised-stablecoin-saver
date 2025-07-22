// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {DecentralisedStablecoin} from "../src/DecentralisedStablecoin.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {SavingAccount} from "../src/SavingAccount.sol";

contract DeployDSC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (DecentralisedStablecoin, DSCEngine, SavingAccount, HelperConfig) {
        HelperConfig config = new HelperConfig();
        // gets the price feeds and token addresses from anvil chain
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            config.activeNetworkConfig();
        // we put these variables into the tokenAddresses and priceFeedAddresses to pass into DSCEngine deployment
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        // deployer key is our anvil private key
        vm.startBroadcast(deployerKey);
        DecentralisedStablecoin dsc = new DecentralisedStablecoin();
        // constructor variables
        DSCEngine engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
        SavingAccount saver = new SavingAccount(dsc);
        // we want the engine to be the address which can mint and burn etc
        dsc.transferOwnership(address(engine));
        vm.stopBroadcast();
        return (dsc, engine, saver, config);
    }
}
