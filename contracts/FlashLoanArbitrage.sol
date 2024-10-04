// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IBalancerVault {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

enum SwapKind { GIVEN_IN, GIVEN_OUT }

contract BalancerV3ArbitrageBot is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IBalancerVault public balancerVault;
    IUniswapV2Router public uniswapRouter;

    event ArbitrageExecuted(address indexed token0, address indexed token1, uint256 profit);
    event ArbitrageError(string reason);

    constructor(address _balancerVault, address _uniswapRouter) {
        balancerVault = IBalancerVault(_balancerVault);
        uniswapRouter = IUniswapV2Router(_uniswapRouter);
    }

    event DebugLog(string message);
    event DebugLogUint(string message, uint256 value);

    function executeArbitrage(
        address token0,
        address token1,
        uint256 flashLoanAmount,
        uint256 minProfit,
        bytes32 balancerPoolId
    ) external onlyOwner nonReentrant {
        emit DebugLog("Executing arbitrage");
        address[] memory tokens = new address[](1);
        tokens[0] = token0;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = flashLoanAmount;

        bytes memory userData = abi.encode(token1, minProfit, balancerPoolId);

        try balancerVault.flashLoan(address(this), tokens, amounts, userData) {
            emit DebugLog("Flash loan successful");
        } catch Error(string memory reason) {
            emit DebugLog(string(abi.encodePacked("Flash loan failed: ", reason)));
            emit ArbitrageError(string(abi.encodePacked("Flash loan failed: ", reason)));
        }
    }

    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        emit DebugLog("Received flash loan");
        require(msg.sender == address(balancerVault), "Unauthorized");

        (address token1, uint256 minProfit, bytes32 balancerPoolId) = abi.decode(userData, (address, uint256, bytes32));

        uint256 flashLoanAmount = amounts[0];
        address token0 = tokens[0];

        try this.performArbitrage(token0, token1, flashLoanAmount, feeAmounts[0], minProfit, balancerPoolId) {
            emit DebugLog("Arbitrage successful");
        } catch Error(string memory reason) {
            emit DebugLog(string(abi.encodePacked("Arbitrage failed: ", reason)));
            emit ArbitrageError(string(abi.encodePacked("Arbitrage failed: ", reason)));
            // Ensure we repay the flash loan even if arbitrage fails
            IERC20(token0).safeTransfer(address(balancerVault), flashLoanAmount + feeAmounts[0]);
        }
    }

    function performArbitrage(
        address token0,
        address token1,
        uint256 flashLoanAmount,
        uint256 flashLoanFee,
        uint256 minProfit,
        bytes32 balancerPoolId
    ) external {
        emit DebugLog("Performing arbitrage");
        require(msg.sender == address(this), "Only internal call");

        // Step 1: Swap token0 for token1 on Uniswap
        uint256 token1Amount = swapOnUniswap(token0, token1, flashLoanAmount);
        emit DebugLogUint("Uniswap swap result", token1Amount);

        // Step 2: Swap token1 back to token0 on Balancer
        uint256 token0Received = swapOnBalancer(token1, token0, token1Amount, balancerPoolId);
        emit DebugLogUint("Balancer swap result", token0Received);

        // Step 3: Calculate profit and repay flash loan
        uint256 flashLoanRepayment = flashLoanAmount + flashLoanFee;
        emit DebugLogUint("Flash loan repayment", flashLoanRepayment);
        require(token0Received > flashLoanRepayment, "Arbitrage not profitable");

        uint256 profit = token0Received - flashLoanRepayment;
        emit DebugLogUint("Calculated profit", profit);
        require(profit >= minProfit, "Profit below minimum threshold");

        // Repay flash loan
        IERC20(token0).safeTransfer(address(balancerVault), flashLoanRepayment);

        // Transfer profit to contract owner
        IERC20(token0).safeTransfer(owner(), profit);

        emit ArbitrageExecuted(token0, token1, profit);
    }


    function swapOnUniswap(address tokenIn, address tokenOut, uint256 amountIn) internal returns (uint256) {
        IERC20(tokenIn).safeApprove(address(uniswapRouter), amountIn);
        
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amountIn,
            0, // We don't set a minimum as we'll check profitability later
            path,
            address(this),
            block.timestamp
        );

        return amounts[1]; // Return the amount of tokenOut received
    }

    function swapOnBalancer(address tokenIn, address tokenOut, uint256 amountIn, bytes32 poolId) internal returns (uint256) {
        IERC20(tokenIn).safeApprove(address(balancerVault), amountIn);

        SingleSwap memory swap = SingleSwap({
            poolId: poolId,
            kind: SwapKind.GIVEN_IN,
            assetIn: tokenIn,
            assetOut: tokenOut,
            amount: amountIn,
            userData: ""
        });

        FundManagement memory funds = FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        return balancerVault.swap(swap, funds, 0, block.timestamp);
    }

    // Function to rescue tokens stuck in the contract
    function rescueTokens(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner(), balance);
    }
}