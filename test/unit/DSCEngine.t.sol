// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {DecentralisedStablecoin} from "../../src/DecentralisedStablecoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";

contract DSCEngineTest is Test {
    DecentralisedStablecoin dsc;
    DeployDSC deployer;
    DSCEngine dsce;

    function setUp() public {
        deployer = new DeployDSC();
    }
}
