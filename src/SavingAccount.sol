// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DecentralisedStablecoin} from "../src/DecentralisedStablecoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";

contract SavingAccount is Ownable {
    // errors
    error SavingAccount__MustBeMoreThanZero();
    error SavingAccount__InsufficientDscBalance();
    error SavingAccount__DepositFailed();

    // state variables
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8;
    mapping(address user => uint256 time) private s_userSinceLastUpdated;
    mapping(address user => uint256 amount) private s_amountDscUserDeposited;

    uint256 private constant PRECISION_FACTOR = 1e18;
    DecentralisedStablecoin private immutable i_dsc;
    DSCEngine private immutable i_engine;

    // events
    event UpdatedInterestRate(uint256 newInterestRate);

    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert SavingAccount__MustBeMoreThanZero();
        }
        _;
    }

    constructor() Ownable(msg.sender) {}

    function deposit(uint256 _amount) external moreThanZero {
        s_amountDscUserDeposited[msg.sender] += _amount;
        // need to address multiple deposits, if a user deposits after an initial deposit, it will cause an error in interest calculation
        s_userSinceLastUpdated[msg.sender] = block.timestamp;
        if (i_dsc.balanceOf(msg.sender) != _amount) {
            revert SavingAccount__InsufficientDscBalance();
        }
        (bool success,) = i_dsc.transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert SavingAccount__DepositFailed();
        }
    }

    function redeem(uint256 _amount) external moreThanZero {}

    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        s_interestRate = _newInterestRate;
        emit UpdatedInterestRate(_newInterestRate);
    }

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

    function getUserDscDeposited(address user) external view returns (uint256) {
        return s_amountDscUserDeposited[user];
    }
}
