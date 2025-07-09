// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract DecentralisedStablecoin is ERC20, ERC20Burnable, Ownable(msg.sender) {
    // errors
    error DecentralisedStablecoin__NeedsMoreThanZero();
    error DecentralisedStablecoin__BurnMoreThanBalance();

    constructor() ERC20("DecentralisedStablecoin", "DSC") {}

    function mint(address to, uint256 amount) external onlyOwner returns (bool) {
        if (amount <= 0) {
            revert DecentralisedStablecoin__NeedsMoreThanZero();
        }
        _mint(to, amount);
        return true;
    }

    function burn(address user, uint256 amount) public onlyOwner returns (bool) {
        uint256 balance = balanceOf(msg.sender);
        if (amount <= 0) {
            revert DecentralisedStablecoin__NeedsMoreThanZero();
        }
        if (balance < amount) {
            revert DecentralisedStablecoin__BurnMoreThanBalance();
        }
        _burn(user, amount);
        return true;
    }
}
