// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DecentralisedStablecoin} from "../src/DecentralisedStablecoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";

contract SavingAccount is Ownable {
    // state variables
    uint256 s_interestRate;
    mapping(address user => uint256 interestRate) private s_userInterestRate;

    DecentralisedStablecoin private immutable i_dsc;
    DSCEngine private immutable i_engine;

    constructor() Ownable(msg.sender) {}

    function deposit(uint256 _amount) external payable {}

    function redeem(uint256 _amount) external {}

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
}
