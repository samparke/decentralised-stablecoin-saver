// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DecentralisedStablecoin} from "../src/DecentralisedStablecoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";

contract SavingAccount is Ownable {
    // errors
    error SavingAccount__MustBeMoreThanZero();
    error SavingAccount__InsufficientDscBalance();
    error SavingAccount__DepositFailed();
    error SavingAccount__RedeemFailed();
    error SavingAccount__SavingAccountDoesNotHaveSufficientBalanceToTransfer();

    // state variables
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8;
    mapping(address user => uint256 time) private s_userSinceLastUpdated;
    mapping(address user => uint256 amount) private s_amountDscUserDeposited;

    uint256 private constant PRECISION_FACTOR = 1e18;
    DecentralisedStablecoin private immutable i_dsc;

    // events
    event UpdatedInterestRate(uint256 newInterestRate);

    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert SavingAccount__MustBeMoreThanZero();
        }
        _;
    }

    constructor(DecentralisedStablecoin dsc) Ownable(msg.sender) {
        i_dsc = dsc;
    }

    /**
     * @notice deposits dsc to the saving account
     * @param _amount the amount the user wants to deposit
     * @dev it accrues the msg.sender's current interest (from previous deposit, and adds to deposit mapping)
     * it adds the now-deposited amount to the user dsc deposited mapping, and sends the amount to the contract
     */
    function deposit(uint256 _amount) external moreThanZero(_amount) {
        _accrue(msg.sender);

        if (i_dsc.balanceOf(msg.sender) < _amount) {
            revert SavingAccount__InsufficientDscBalance();
        }
        s_amountDscUserDeposited[msg.sender] += _amount;
        s_userSinceLastUpdated[msg.sender] = block.timestamp;
        (bool success) = i_dsc.transferFrom(msg.sender, address(this), _amount);
        if (!success) {
            revert SavingAccount__DepositFailed();
        }
    }

    /**
     * @notice calculates user interest accumulated, stores this whole user dsc balance in principle variable,
     * reduces the desired amount to redeem from total balance, and sends this to the user
     * @param _amount the amount the msg.sender wants to redeem (removed dsc from the contract)
     */
    function redeem(uint256 _amount) external moreThanZero(_amount) {
        _accrue(msg.sender);

        uint256 principle = s_amountDscUserDeposited[msg.sender];

        if (_amount == type(uint256).max) {
            _amount = principle;
        }

        s_amountDscUserDeposited[msg.sender] = principle - _amount;
        s_userSinceLastUpdated[msg.sender] = block.timestamp;
        (bool success) = i_dsc.transfer(msg.sender, _amount);
        if (!success) {
            revert SavingAccount__RedeemFailed();
        }
    }

    /**
     * @notice set new interest rate
     * @param _newInterestRate the new interest rate to be set
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        s_interestRate = _newInterestRate;
        emit UpdatedInterestRate(_newInterestRate);
    }

    /**
     * @notice calculates the interest gained for the user
     * @param _user the user to calculate interest for
     * @return principle the original user dsc balance before calculating interest
     * @return interest the user dsc balance has accumulated
     */
    function calculateAccruedInterest(address _user) public view returns (uint256 principle, uint256 interest) {
        principle = s_amountDscUserDeposited[_user];
        uint256 timeElapsed = block.timestamp - s_userSinceLastUpdated[_user];
        interest = principle * s_interestRate * timeElapsed / PRECISION_FACTOR;
    }

    // internal functions

    /**
     * @notice adds the accumulated interest and the original balance to the user deposit mapping
     * @param _user the user we are calculating the interest for
     */
    function _accrue(address _user) internal {
        (uint256 principle, uint256 interest) = calculateAccruedInterest(_user);
        if (interest > 0) {
            s_amountDscUserDeposited[_user] = principle + interest;
        }
        s_userSinceLastUpdated[_user] = block.timestamp;
    }

    // getter functions

    function getContractInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    function getUserLastUpdate(address _user) external view returns (uint256) {
        return s_userSinceLastUpdated[_user];
    }

    function getUserDscDeposited(address _user) external view returns (uint256) {
        return s_amountDscUserDeposited[_user];
    }
}
