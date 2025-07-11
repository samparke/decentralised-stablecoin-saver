// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DecentralisedStablecoin} from "../src/DecentralisedStablecoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DSCEngine {
    // ERRORS
    error DSCEngine__TokenAddressesAndPriceFeedAddressesDoNotMatch();
    error DSCEngine__TransferFailed();
    error DSCEngine__MintFailed();
    error DSCEngine__BurnFailed();
    error DSCEngine_RedeemFailed();
    error DSCEngine__MustBeMoreThanZero();

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;

    address[] private s_collateralTokenAddresses;
    mapping(address user => mapping(address token => uint256 amount)) private s_userCollateralDepositted;
    mapping(address user => uint256 dscMinted) private s_userDscMinted;
    mapping(address token => address priceFeed) private s_tokenPriceFeeds;

    DecentralisedStablecoin private immutable i_dsc;

    // MODIFERS
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__MustBeMoreThanZero();
        }
        _;
    }

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

    // DEPOSIT COLLATERAL, DEPOSIT AND MINT DSC, MINT DSC, BURN DSC, REDEEM COLLATERAL, REDEEM COLLATERAL FOR DSC
    function depositCollateral(address tokenCollateralAddress, uint256 amountToDeposit)
        public
        moreThanZero(amountToDeposit)
    {
        s_userCollateralDepositted[msg.sender][tokenCollateralAddress] += amountToDeposit;
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountToDeposit);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function depositCollateralAndMintDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountToMint)
        public
    {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountToMint);
    }

    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) {
        s_userDscMinted[msg.sender] += amountDscToMint;
        bool success = i_dsc.mint(msg.sender, amountDscToMint);
        if (!success) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc(uint256 amountDscToBurn) public moreThanZero(amountDscToBurn) {
        _burnDsc(amountDscToBurn, msg.sender, msg.sender);
    }

    function redeemCollateral(address tokenCollateralAddress, uint256 amountToRedeem)
        public
        moreThanZero(amountToRedeem)
    {
        _redeemCollateral(tokenCollateralAddress, amountToRedeem, msg.sender, msg.sender);
    }

    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountToBurn)
        public
    {
        burnDsc(amountToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    // HEALTH FACTOR FUNCTIONS

    function revertIfHealthFactorIsBroken() public {}

    function calculateHealthFactor() public {}

    function getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_userDscMinted[user];
        // collateralValueInUsd = _getAccountCollateralValue();
    }

    function getAccountCollateralValue(address user) private returns (uint256 collateralValue) {
        for (uint256 i = 0; i < s_collateralTokenAddresses.length; i++) {
            address token = s_collateralTokenAddresses[i];
            uint256 amount = s_userCollateralDepositted[user][token];
            // collateralValue = _getUsdValue(token, amount);
        }
    }

    function getUsdValue(address token, uint256 amount) private returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_tokenPriceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    // PRIVATE AND INTERNAL FUNCTIONS
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
