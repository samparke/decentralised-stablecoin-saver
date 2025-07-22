// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

contract SaverHelperConfig is Script {
    uint256 public deployerKey;
    uint256 public DEFAULT_ANVIL_CONFIG = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        deployerKey = DEFAULT_ANVIL_CONFIG;
    }
}
