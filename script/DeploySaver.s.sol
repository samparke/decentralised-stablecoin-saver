// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {DecentralisedStablecoin} from "../src/DecentralisedStablecoin.sol";
import {SavingAccount} from "../src/SavingAccount.sol";
import {SaverHelperConfig} from "../script/SaverHelperConfig.s.sol";

contract DeploySaver is Script {
    function run() external {
        SaverHelperConfig config = new SaverHelperConfig();
        uint256 deployerKey = config.deployerKey();
        address dsc = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        vm.startBroadcast(deployerKey);
        new SavingAccount(DecentralisedStablecoin(dsc));
        vm.stopBroadcast();
    }
}
