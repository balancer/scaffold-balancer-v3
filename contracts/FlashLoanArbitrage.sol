// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interface for Balancer V3 Vault
interface IBalancerVault {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

// Simplified interface for Uniswap V2 Router
interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract BalancerV3ArbitrageBot is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IBalancerVault public balancerVault;
    IUniswapV2Router public uniswapRouter;

    event ArbitrageExecuted(address indexed token0, address indexed token1, uint256 profit);

    constructor(address _balancerVault, address _uniswapRouter) {
        balancerVault = IBalancerVault(_balancerVault);
        uniswapRouter = IUniswapV2Router(_uniswapRouter);
    }

    function executeArbitrage(
        address token0,
        address token1,
        uint256 flashLoanAmount,
        uint256 minProfit
    ) external onlyOwner nonReentrant {
        address[] memory tokens = new address[](1);
        tokens[0] = token0;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = flashLoanAmount;

        bytes memory userData = abi.encode(token1, minProfit);

        balancerVault.flashLoan(address(this), tokens, amounts, userData);
    }

    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        require(msg.sender == address(balancerVault), "Unauthorized");

        (address token1, uint256 minProfit) = abi.decode(userData, (address, uint256));

        // Step 1: Receive flash loan
        uint256 flashLoanAmount = amounts[0];
        address token0 = tokens[0];

        // Step 2: Swap token0 for token1 on Uniswap
        IERC20(token0).safeApprove(address(uniswapRouter), flashLoanAmount);
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        uint256[] memory swapAmounts = uniswapRouter.swapExactTokensForTokens(
            flashLoanAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        // Step 3: Swap token1 back to token0 on Balancer (simplified, assume direct swap)
        uint256 token1Amount = swapAmounts[1];
        IERC20(token1).safeApprove(address(balancerVault), token1Amount);
        // Note: This is a simplified representation. You'd need to implement the actual Balancer swap logic here.
        uint256 token0Received = token1Amount * 101 / 100; // Simplified: assume 1% profit

        // Step 4: Repay flash loan and calculate profit
        uint256 flashLoanRepayment = flashLoanAmount + feeAmounts[0];
        require(token0Received > flashLoanRepayment, "Arbitrage not profitable");

        uint256 profit = token0Received - flashLoanRepayment;
        require(profit >= minProfit, "Profit below minimum threshold");

        // Repay flash loan
        IERC20(token0).safeTransfer(address(balancerVault), flashLoanRepayment);

        // Transfer profit to contract owner
        IERC20(token0).safeTransfer(owner(), profit);

        emit ArbitrageExecuted(token0, token1, profit);
    }

    // Function to rescue tokens stuck in the contract
    function rescueTokens(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner(), balance);
    }
}
// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
// import "@balancer-labs/v2-flash-loans/contracts/IVault.sol";

// contract FlashLoanArbitrage {
//     address private owner;
//     IVault private balancerVault;
//     IUniswapV2Router02 private uniswapRouter;
//     IUniswapV2Router02 private sushiswapRouter;

//     constructor(address _balancerVault, address _uniswapRouter, address _sushiswapRouter) {
//         owner = msg.sender;
//         balancerVault = IVault(_balancerVault);
//         uniswapRouter = IUniswapV2Router02(_uniswapRouter);
//         sushiswapRouter = IUniswapV2Router02(_sushiswapRouter);
//     }

//     modifier onlyOwner() {
//         require(msg.sender == owner, "Not the owner");
//         _;
//     }

//     // Flash Loan Callback (Balancer will call this function after loan is granted)
//     function receiveFlashLoan(
//         IERC20[] memory tokens,
//         uint256[] memory amounts,
//         uint256 fee,
//         bytes memory userData
//     ) external {
//         // Assume we're only borrowing one asset (USDC)
//         uint256 amountBorrowed = amounts[0];

//         // Trade on Uniswap (buy ETH with USDC)
//         address;
//         path[0] = address(tokens[0]); // USDC
//         path[1] = uniswapRouter.WETH(); // ETH
        
//         tokens[0].approve(address(uniswapRouter), amountBorrowed);
//         uint256[] memory amountsOut = uniswapRouter.swapExactTokensForTokens(
//             amountBorrowed,
//             0, // minimum ETH out
//             path,
//             address(this),
//             block.timestamp + 300
//         );

//         uint256 ethBought = amountsOut[1];

//         // Trade on Sushiswap (sell ETH for USDC)
//         path[0] = sushiswapRouter.WETH(); // ETH
//         path[1] = address(tokens[0]); // USDC

//         IERC20(path[0]).approve(address(sushiswapRouter), ethBought);
//         uint256[] memory amountsBack = sushiswapRouter.swapExactTokensForTokens(
//             ethBought,
//             0, // minimum USDC out
//             path,
//             address(this),
//             block.timestamp + 300
//         );

//         uint256 usdcGained = amountsBack[1];

//         // Repay the flash loan
//         uint256 amountOwed = amountBorrowed + fee;
//         require(usdcGained > amountOwed, "No profit, reverting");

//         tokens[0].transfer(address(balancerVault), amountOwed);

//         // Keep the profit
//         uint256 profit = usdcGained - amountOwed;
//         tokens[0].transfer(owner, profit);
//     }

//     // Initiate Flash Loan
//     function executeArbitrage(IERC20[] memory tokens, uint256[] memory amounts) external onlyOwner {
//         balancerVault.flashLoan(address(this), tokens, amounts, "");
//     }
// }
