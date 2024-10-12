// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IBasePool } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol"; // Import VaultTypes.sol

contract TWAMM {
    IVault private vault;
    address private tokenA;
    address private tokenB;
    IERC20 public tokenIn;
    IERC20 public tokenOut;
    uint256 public totalAmountIn;
    uint256 public totalAmountOut;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public interval;
    uint256 public lastExecutionTime;

    struct Order {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool isBuy;
    }

    mapping(address => Order[]) public orders;

    event TWAMMOrderExecuted(uint256 amountIn, uint256 amountOut, uint256 timestamp);

    constructor(
        IVault _vault,
        address _tokenA,
        address _tokenB,
        IERC20 _tokenIn,
        IERC20 _tokenOut,
        uint256 _totalAmountIn,
        uint256 _totalAmountOut,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _interval
    ) {
        vault = _vault;
        tokenA = _tokenA;
        tokenB = _tokenB;
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        totalAmountIn = _totalAmountIn;
        totalAmountOut = _totalAmountOut;
        startTime = _startTime;
        endTime = _endTime;
        interval = _interval;
        lastExecutionTime = _startTime;
    }

    function createOrder(uint256 amount, uint256 duration, bool isBuy) external {
        require(amount > 0, "Amount must be greater than zero");
        require(duration > 0, "Duration must be greater than zero");

        IERC20 token = isBuy ? IERC20(tokenA) : IERC20(tokenB);
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        orders[msg.sender].push(
            Order({ amount: amount, startTime: block.timestamp, endTime: block.timestamp + duration, isBuy: isBuy })
        );
    }

    function cancelOrder(uint256 orderIndex) external {
        require(orderIndex < orders[msg.sender].length, "Invalid order index");

        Order memory order = orders[msg.sender][orderIndex];
        IERC20 token = order.isBuy ? IERC20(tokenA) : IERC20(tokenB);
        require(token.transfer(msg.sender, order.amount), "Transfer failed");

        // Remove the order
        orders[msg.sender][orderIndex] = orders[msg.sender][orders[msg.sender].length - 1];
        orders[msg.sender].pop();
    }

    function executeOrders() external {
        for (uint256 i = 0; i < orders[msg.sender].length; i++) {
            Order storage order = orders[msg.sender][i];
            if (block.timestamp >= order.endTime) {
                uint256 amountOut = getAmountOut(order.amount, order.isBuy);
                tokenIn = order.isBuy ? IERC20(tokenA) : IERC20(tokenB);
                tokenOut = order.isBuy ? IERC20(tokenB) : IERC20(tokenA);

                require(tokenOut.transfer(msg.sender, amountOut), "Transfer failed");
                order.amount = 0; // Mark order as executed
            }
        }
    }

    function getAmountOut(uint256 amountIn, bool isBuy) internal pure returns (uint256) {
        // Implement the logic to calculate the amount out based on the TWAMM algorithm
        // This is a placeholder and should be replaced with actual logic
        return amountIn;
    }

    function swap(
        VaultSwapParams memory vaultSwapParams
    ) external returns (uint256 amountCalculatedRaw, uint256 amountInRaw, uint256 amountOutRaw) {
        return vault.swap(vaultSwapParams); // Adjust the function call accordingly
    }

    function executeTWAMMOrder() external {
        require(block.timestamp >= startTime, "TWAMM: Not started yet");
        require(block.timestamp <= endTime, "TWAMM: Already ended");
        require(block.timestamp >= lastExecutionTime + interval, "TWAMM: Interval not reached");

        uint256 elapsedTime = block.timestamp - lastExecutionTime;
        uint256 amountIn = (totalAmountIn * elapsedTime) / (endTime - startTime);
        uint256 amountOut = (totalAmountOut * elapsedTime) / (endTime - startTime);

        tokenIn.approve(address(vault), amountIn);

        VaultSwapParams memory vaultSwapParams = VaultSwapParams({
            kind: SwapKind.EXACT_IN,
            pool: address(this),
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountGivenRaw: amountIn,
            limitRaw: 0,
            userData: ""
        });

        vault.swap(vaultSwapParams);

        lastExecutionTime = block.timestamp;

        emit TWAMMOrderExecuted(amountIn, amountOut, block.timestamp);
    }

    function withdrawRemainingFunds() external {
        require(block.timestamp > endTime, "TWAMM: Not ended yet");

        uint256 remainingTokenIn = tokenIn.balanceOf(address(this));
        uint256 remainingTokenOut = tokenOut.balanceOf(address(this));

        if (remainingTokenIn > 0) {
            tokenIn.transfer(address(this), remainingTokenIn);
        }

        if (remainingTokenOut > 0) {
            tokenOut.transfer(address(this), remainingTokenOut);
        }
    }

    function getOrders(address user) public view returns (Order[] memory) {
        return orders[user];
    }
}
