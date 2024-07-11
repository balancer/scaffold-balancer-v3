//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Mock Token 2
 * @notice Entire initial supply is minted to the deployer
 * @dev Default decimals is 18, but you can override the decimals function from ERC20
 */
contract MockToken2 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * Allow any user to mint any amount of tokens to their wallet
     * This function is accessible on the frontend's "Debug" page
     */
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
