require('dotenv').config();
const { ethers } = require("ethers");
const abi = require('../artifacts/contracts/FlashLoanArbitrage.sol/FlashLoanArbitrage.json').abi;

// Set up the provider (e.g., Infura or Alchemy)
const provider = new ethers.providers.JsonRpcProvider(process.env.INFURA_API);

// Set up the wallet
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// Contract instance
const flashLoanArbitrageAddress = "0x..."; // Deployed contract address
const flashLoanArbitrage = new ethers.Contract(flashLoanArbitrageAddress, abi, wallet);

// USDC token address and decimals
const USDC = "0x..."; // USDC token contract address
const USDC_DECIMALS = 6;

// Utility function to fetch prices from Uniswap and Sushiswap
async function getPriceUniswap(pairAddress) {
    try {
        // Call Uniswap contract to get the latest price for the pair
        const price = await uniswapContract.getReserves(); // Example function, implement as needed
        return price; // Process and return the formatted price
    } catch (error) {
        console.error("Error fetching Uniswap price:", error);
        return null; // Handle error and return null if something goes wrong
    }
}

async function getPriceSushiswap(pairAddress) {
    try {
        // Call Sushiswap contract to get the latest price for the pair
        const price = await sushiswapContract.getReserves(); // Example function, implement as needed
        return price; // Process and return the formatted price
    } catch (error) {
        console.error("Error fetching Sushiswap price:", error);
        return null; // Handle error and return null if something goes wrong
    }
}

// Improved function to handle slippage tolerance
function calculateMinimumAmountOut(amountIn, slippagePercent) {
    const slippageTolerance = ethers.BigNumber.from(slippagePercent).div(100); // e.g., 1% slippage
    return amountIn.sub(amountIn.mul(slippageTolerance));
}

// Main logic to run the bot with error handling
async function runBot() {
    const usdc = await ethers.getContractAt("IERC20", USDC);

    // Get prices from both exchanges
    const priceUniswap = await getPriceUniswap(/*Uniswap pair address*/);
    const priceSushiswap = await getPriceSushiswap(/*Sushiswap pair address*/);

    // Error handling if price data is not available
    if (!priceUniswap || !priceSushiswap) {
        console.error("Failed to fetch prices from exchanges, aborting arbitrage.");
        return;
    }

    // Calculate arbitrage profit opportunity
    if (priceUniswap < priceSushiswap) {
        console.log("Arbitrage opportunity detected!");

        // Apply slippage control
        const slippagePercent = 1; // 1% slippage
        const minimumAmountOut = calculateMinimumAmountOut(priceUniswap, slippagePercent);

        const tokens = [usdc];
        const amounts = [ethers.utils.parseUnits('1000', USDC_DECIMALS)]; // 1000 USDC

        // Error handling for arbitrage execution
        try {
            // Execute arbitrage
            await flashLoanArbitrage.executeArbitrage(tokens, amounts);
        } catch (err) {
            console.error("Arbitrage transaction failed:", err);
        }
    } else {
        console.log("No arbitrage opportunity found.");
    }
}

runBot().catch(console.error);

// require('dotenv').config();
// const { ethers } = require("ethers");
// const abi = require('../artifacts/contracts/FlashLoanArbitrage.sol/FlashLoanArbitrage.json').abi;

// // Set up the provider (e.g., Infura or Alchemy)
// const provider = new ethers.providers.JsonRpcProvider(process.env.INFURA_API);

// // Set up the wallet
// const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// // Contract instance
// const flashLoanArbitrageAddress = "0x..."; // Deployed contract address
// const flashLoanArbitrage = new ethers.Contract(flashLoanArbitrageAddress, abi, wallet);

// // USDC token address
// const USDC = "0x..."; // USDC token contract address

// // Main logic to run the bot
// async function runBot() {
//     const usdc = await ethers.getContractAt("IERC20", USDC);

//     // Check price difference between Uniswap and Sushiswap
//     const priceUniswap = await getPriceUniswap(); // Write your logic to get prices
//     const priceSushiswap = await getPriceSushiswap();

//     if (priceUniswap < priceSushiswap) {
//         console.log("Arbitrage opportunity detected!");

//         const tokens = [usdc];
//         const amounts = [ethers.utils.parseUnits('1000', 6)]; // 1000 USDC

//         // Execute arbitrage
//         await flashLoanArbitrage.executeArbitrage(tokens, amounts);
//     } else {
//         console.log("No arbitrage opportunity found.");
//     }
// }

// runBot().catch(console.error);
