//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin-npm/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin-npm/access/Ownable.sol";

contract MockLinked is ERC20, Ownable {
    // Mint the initial supply to the deployer
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) Ownable() {
        _mint(msg.sender, initialSupply);
    }

    // Allow any user to mint any amount of tokens to their wallet
    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount);
    }
}
