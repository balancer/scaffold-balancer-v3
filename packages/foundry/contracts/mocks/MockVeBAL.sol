//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockVeBAL is ERC20 {
    // Mint the initial supply to the deployer
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    // Allow any user to mint any amount of tokens to their wallet
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
