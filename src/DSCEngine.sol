// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DecentralisedStablecoin} from "../src/DecentralisedStablecoin.sol";

contract DSCEngine {
    address[] private s_collateralTokenAddresses;

    mapping(address user => mapping(address token => uint256 amount)) private s_userCollateralDepositted;
    mapping(address user => uint256 dscMinted) private s_userDscMinted;
    mapping(address token => address priceFeed) private s_tokenPriceFeeds;

    DecentralisedStablecoin private immutable i_dsc;
}
