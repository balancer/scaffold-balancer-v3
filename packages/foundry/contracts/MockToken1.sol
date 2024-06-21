//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockToken1
 * @notice A mock ERC20 that is to be deployed when a user runs the ScaffoldBalancer default deployment scripts.
 * @dev When creating your own pool that will be used on actual mainnet networks, one would use proper ERC20s accordingly instead of fake testnet ones.
 */
contract MockToken1 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000 ether); // mints 1000 to deployer. Precision is 18 decimals.
    }

    /**
     * @notice allows any user to mint any amount of tokens to their wallet for frontend pool action testing
     */
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
