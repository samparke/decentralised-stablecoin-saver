// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DecentralisedStablecoin} from "../src/DecentralisedStablecoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DSCEngine {
    // error
    error DSCEngine__TokenAddressesAndPriceFeedAddressesDoNotMatch();

    address[] private s_collateralTokenAddresses;

    mapping(address user => mapping(address token => uint256 amount)) private s_userCollateralDepositted;
    mapping(address user => uint256 dscMinted) private s_userDscMinted;
    mapping(address token => address priceFeed) private s_tokenPriceFeeds;

    DecentralisedStablecoin private immutable i_dsc;

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dsc) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesDoNotMatch();
        }
        // for the length of our tokenAddresses input, add the token address and equivalent price feed to the s_tokenPriceFeed mapping
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_tokenPriceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokenAddresses.push(tokenAddresses[i]);
        }
        i_dsc = DecentralisedStablecoin(dsc);
    }

    function depositCollateral(address tokenCollateralAddress, uint256 amountToDeposit) public {
        s_userCollateralDepositted[msg.sender][tokenCollateralAddress] += amountToDeposit;
    }

    function mintDsc(uint256 amountDscToMint) public {
        s_userDscMinted[msg.sender] += amountDscToMint;
    }

    function burnDsc(uint256 amountDscToBurn) public {}

    function redeemCollateral(address tokenCollateralAddress, uint256 amountToRedeem) public {
        s_userCollateralDepositted[msg.sender][tokenCollateralAddress] -= amountToRedeem;
    }
}
