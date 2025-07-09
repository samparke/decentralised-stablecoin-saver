// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {DecentralisedStablecoin} from "../src/DecentralisedStablecoin.sol";

contract DeployDSC is Script {
    function run() external returns (DecentralisedStablecoin) {
        vm.startBroadcast();
        DecentralisedStablecoin dsc = new DecentralisedStablecoin();
        vm.stopBroadcast();
        return dsc;
    }
}
