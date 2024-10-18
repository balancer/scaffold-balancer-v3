// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FeeTokenMock is ERC20("FeeToken", "FT") {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        if (amount > balanceOf(from)) {
            amount = balanceOf(from);
        }
        _burn(from, amount);
    }
}
