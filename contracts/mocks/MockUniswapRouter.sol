// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockUniswapRouter {
    uint256 private mockAmountOut;

    function setMockAmountOut(uint256 _amount) external {
        mockAmountOut = _amount;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(path.length >= 2, "Invalid path");
        require(block.timestamp <= deadline, "Deadline exceeded");
        require(mockAmountOut >= amountOutMin, "Insufficient output amount");

        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[path.length - 1]).transfer(to, mockAmountOut);

        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        amounts[path.length - 1] = mockAmountOut;

        return amounts;
    }
}