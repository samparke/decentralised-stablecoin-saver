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
    error DSCEngine__BrokenHealthFactor(uint256 healthFactor);
    error DSCEngine__HealthFactorIsGood();
    error DSCEngine__HealthFactorHasNotImproved();

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10; // 1 followed by 10 zeros
    uint256 private constant PRECISION = 1e18; // 1 followed by 18 zeros
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18; // 1 followed by 18 zeros

    address[] private s_collateralTokenAddresses;
    mapping(address user => mapping(address token => uint256 amount)) private s_userCollateralDeposited;
    mapping(address user => uint256 dscMinted) private s_userDscMinted;
    mapping(address token => address priceFeed) private s_tokenPriceFeeds;

    // EVENTS
    event CollateralDeposited(address indexed user, address indexed token, uint256 amountDeposited);
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amountRedeemed
    );

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
        s_userCollateralDeposited[msg.sender][tokenCollateralAddress] += amountToDeposit;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountToDeposit);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountToDeposit);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function depositCollateralAndMintDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountToMint)
        public
    {
        // we don't need to emit the deposit collateral event, as it emits in the depositCollateral function
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountToMint);
    }

    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) {
        s_userDscMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool success = i_dsc.mint(msg.sender, amountDscToMint);
        if (!success) {
            revert DSCEngine__MintFailed();
        }
    }

    function burnDsc(uint256 amountDscToBurn) public moreThanZero(amountDscToBurn) {
        _burnDsc(amountDscToBurn, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function redeemCollateral(address tokenCollateralAddress, uint256 amountToRedeem)
        public
        moreThanZero(amountToRedeem)
    {
        _redeemCollateral(tokenCollateralAddress, amountToRedeem, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountToBurn)
        public
    {
        burnDsc(amountToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
    }

    // HEALTH FACTOR FUNCTIONS

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // stages in fetching heath factor:
        // 1. pass the user address we are trying to calculate the health factor for
        // 2. this function gets the account information, including the totalDscMinted and collateralValueInUsd
        // 3. this gets passed to the _calculateHealthFactor function, which contains:
        //          if (totalDscMinted == 0){
        //              return type(uint256).max;
        //          }
        // uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        // return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;

        uint256 userHealthFactor = _healthFactor(user);
        // we now have a health factor
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            // if this health factor is below 1e18, it is broken, and reverts
            revert DSCEngine__BrokenHealthFactor(userHealthFactor);
        }
    }

    function calculateHealthFactor(uint256 totalDscMinted, uint256 collateralValueInUsd)
        public
        pure
        returns (uint256)
    {
        return (_calculateHealthFactor(totalDscMinted, collateralValueInUsd));
    }

    function getAccountInformation(address user)
        public
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        (totalDscMinted, collateralValueInUsd) = _getAccountInformation(user);
    }

    function getAccountCollateralValue(address user) public view returns (uint256 collateralValue) {
        for (uint256 i = 0; i < s_collateralTokenAddresses.length; i++) {
            address token = s_collateralTokenAddresses[i];
            uint256 amount = s_userCollateralDeposited[user][token];
            collateralValue += getUsdValue(token, amount);
        }
        return collateralValue;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        // retreives the price feed for the token we pass into the function, such as weth/eth on sepolia
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_tokenPriceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // converts into the correct decimals for our contract
        // the price will be originally in 8 decimals. we multiply by 1e10 to convert to 18 decimals
        // we then multiple by amount, which will also be 18 decimals, which would give us 36 decimals
        // // finally we divide by 1e18 to convert back into 18 decimals
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
        // gets the price for token
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_tokenPriceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // returns the USD amount
        return ((usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION));
    }

    // LIQUIDATION

    function liquidate(address collateral, address user, uint256 debtToCover) external moreThanZero(debtToCover) {
        // if the health factor is good, this function should not execute. Liquidation should only happen if health factor is bad
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorIsGood();
        }
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;
        // the liquidator is able to redeem the collateral token, for the totalCollateralToRedeem, from the user with bad health factor
        _redeemCollateral(collateral, totalCollateralToRedeem, user, msg.sender);
        // we must then burn the liquidators dsc
        _burnDsc(debtToCover, user, msg.sender);
        uint256 endingUserHealthFactor = _healthFactor(user);
        // check function actually worked as intended
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__HealthFactorHasNotImproved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
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
        s_userCollateralDeposited[from][tokenCollateralAddress] -= amountToRedeem;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountToRedeem);
        // transfer instead of transferFrom function as collateral is already stored within this contract
        bool success = IERC20(tokenCollateralAddress).transfer(to, amountToRedeem);
        if (!success) {
            revert DSCEngine_RedeemFailed();
        }
    }

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_userDscMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    function _calculateHealthFactor(uint256 totalDscMinted, uint256 collateralValueInUsd)
        internal
        pure
        returns (uint256)
    {
        if (totalDscMinted == 0) {
            return type(uint256).max;
        }
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        return _calculateHealthFactor(totalDscMinted, collateralValueInUsd);
    }

    // GETTER FUNCTIONS

    function getLiquidationPrecision() public pure returns (uint256) {
        return LIQUIDATION_PRECISION;
    }

    function getLiquidationThreshold() public pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationBonus() public pure returns (uint256) {
        return LIQUIDATION_BONUS;
    }

    function getAdditionalFeedPrecision() public pure returns (uint256) {
        return ADDITIONAL_FEED_PRECISION;
    }

    function getPrecision() public pure returns (uint256) {
        return PRECISION;
    }

    function getMinHealthFactor() public pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }

    function getUserCollateralDeposited(address user, address token) public view returns (uint256) {
        return s_userCollateralDeposited[user][token];
    }

    function getUserDscMinted(address user) public view returns (uint256) {
        return s_userDscMinted[user];
    }
}
