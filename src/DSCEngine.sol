// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DecentralisedStablecoin} from "../src/DecentralisedStablecoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DSCEngine {
    // error
    error DSCEngine__TokenAddressesAndPriceFeedAddressesDoNotMatch();
    error DSCEngine__TransferFailed();
    error DSCEngine__MintFailed();
    error DSCEngine__BurnFailed();
    error DSCEngine_RedeemFailed();

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
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountToDeposit);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function mintDsc(uint256 amountDscToMint) public {
        s_userDscMinted[msg.sender] += amountDscToMint;
        bool success = i_dsc.mint(msg.sender, amountDscToMint);
        if (!success) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc(uint256 amountDscToBurn) public {
        _burnDsc(amountDscToBurn, msg.sender, msg.sender);
    }

    function redeemCollateral(address tokenCollateralAddress, uint256 amountToRedeem) public {
        _redeemCollateral(tokenCollateralAddress, amountToRedeem, msg.sender, msg.sender);
    }

    // internal functions

    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) private {
        s_userDscMinted[onBehalfOf] -= amountDscToBurn;
        // transfer dsc from msg.sender/liquidator (in burn function), to this address (equivalient to burn)
        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);
        if (!success) {
            revert DSCEngine__BurnFailed();
        }
        i_dsc.burn(amountDscToBurn);
    }

    function _redeemCollateral(address tokenCollateralAddress, uint256 amountToRedeem, address from, address to)
        private
    {
        s_userCollateralDepositted[from][tokenCollateralAddress] -= amountToRedeem;
        // transfer instead of transferFrom function as collateral is already stored within this contract
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountToRedeem);
        if (!success) {
            revert DSCEngine_RedeemFailed();
        }
    }
}
