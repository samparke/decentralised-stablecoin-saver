// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract DecentralisedStablecoin is ERC20, ERC20Burnable, Ownable(msg.sender) {
    constructor() ERC20("DecentralisedStablecoin", "DSC") {}
}
