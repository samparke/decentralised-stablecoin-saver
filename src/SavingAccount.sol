// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DecentralisedStablecoin} from "../src/DecentralisedStablecoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";

contract SavingAccount is Ownable {
    // errors
    error SavingAccount__MustBeMoreThanZero();

    // state variables
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8;
    mapping(address user => uint256 interestRate) private s_userInterestRate;
    mapping(address user => uint256 time) private s_userSinceLastUpdated;

    uint256 private constant PRECISION_FACTOR = 1e18;
    DecentralisedStablecoin private immutable i_dsc;
    DSCEngine private immutable i_engine;

    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert SavingAccount__MustBeMoreThanZero();
        }
        _;
    }

    constructor() Ownable(msg.sender) {}

    function deposit(uint256 _amount) external moreThanZero {}

    function redeem(uint256 _amount) external moreThanZero {}

    function setInterestRate() external onlyOwner {}

    function _accrueInterest() internal {}

    function _calculateUserInterestAccumulatedSinceLastUpdate() internal {}

    // getter functions

    function getUserInterestRate(address user) external view returns (uint256) {
        return s_userInterestRate[user];
    }

    function getContractInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    function getUserLastUpdate(address user) external view returns (uint256) {
        return s_userSinceLastUpdated[user];
    }
}
