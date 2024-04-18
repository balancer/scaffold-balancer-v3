//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title FakeTestERC20 Example ERC20
 * @notice An example ERC20 that is to be deployed when a user runs the ScaffoldBalancer default deployment scripts.
 * @dev When creating your own pool that will be used on actual mainnet networks, one would use proper ERC20s accordingly instead of fake testnet ones.
 */
contract FakeTestERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000 ether); // mints 1000 scBAL! Precision is 18 decimals.
    }
}