// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ATokenMock is ERC20("A-token", "A-token") {
    uint256 public startBlock = block.number;

    // increases over block
    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = super.balanceOf(account);
        uint256 profit = balance * (block.timestamp - startBlock) / startBlock;
        return balance + profit;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        if (amount > balanceOf(from)) {
            amount = balanceOf(from);
        }

        _burn(from, amount);
    }
}
