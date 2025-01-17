const hre = require("hardhat");

async function main() {
  const arbitrageContractAddress = "0xe46c2970aC2D18785B491d61AD071Cb291432832"; // Replace with your deployed contract address
  const BalancerV3ArbitrageBot = await hre.ethers.getContractAt("BalancerV3ArbitrageBot", arbitrageContractAddress);

  // Replace with token addresses on Sepolia
//   const token0 = "0xB4FBF271143F4FBfD63F1B168D501AD7B5B2C7C3";  // WETH address on Sepolia
//   const token1 = "0x6B175474E89094C44Da98b954EedeAC495271d0F";  // DAI address on Sepolia
    const token0 = hre.ethers.utils.getAddress("0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14");  // WETH address on Sepolia
    const token1 = hre.ethers.utils.getAddress("0x6B175474E89094C44Da98b954EedeAC495271d0F");  // DAI address on Sepolia

  const flashLoanAmount = hre.ethers.utils.parseEther("1");  // Flash loan amount
  const minProfit = hre.ethers.utils.parseEther("0.01");      // Minimum profit

  const tx = await BalancerV3ArbitrageBot.executeArbitrage(token0, token1, flashLoanAmount, minProfit,{
    gasLimit:  3000000, // Set a reasonable gas limit based on contract complexity
    gasPrice: hre.ethers.utils.parseUnits("20", "gwei")  // Customize gas price
  });
  console.log("Transaction submitted. Waiting for confirmation...");
  console.log("Transaction hash:", tx.hash);

  const receipt =await tx.wait(5);
  console.log("Transaction confirmed:", receipt);

  console.log("Arbitrage executed!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});




// const hre = require("hardhat");

// async function main() {
//   const arbitrageContractAddress = "0xe46c2970aC2D18785B491d61AD071Cb291432832"; // Replace with the deployed contract address
//   const BalancerV3ArbitrageBot = await hre.ethers.getContractAt("BalancerV3ArbitrageBot", arbitrageContractAddress);
//   const token0 = "0xTokenAddress0"; // Testnet token address
//   const token1 = "0xTokenAddress1"; // Testnet token address
//   const flashLoanAmount = hre.ethers.utils.parseEther("10"); // Flash loan amount
//   const minProfit = hre.ethers.utils.parseEther("0.01"); // Minimum profit

//   const tx = await BalancerV3ArbitrageBot.executeArbitrage(token0, token1, flashLoanAmount, minProfit);
//   await tx.wait();

//   console.log("Arbitrage executed!");
// }

// main().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });

// const Web3 = require("web3");
// const BalancerV3ArbitrageBot = require("../build/contracts/BalancerV3ArbitrageBot.json");

// async function executeArbitrage() {
//   const web3 = new Web3("https://goerli.infura.io/v3/YOUR_INFURA_PROJECT_ID"); // Connect to Goerli testnet
//   const account = web3.eth.accounts.privateKeyToAccount("YOUR_PRIVATE_KEY"); // Replace with your private key
//   web3.eth.accounts.wallet.add(account);

//   const arbitrageContractAddress = "0xYourDeployedContractAddress"; // Replace with deployed contract address
//   const token0 = "0xTokenAddress0"; // Replace with testnet token0 address
//   const token1 = "0xTokenAddress1"; // Replace with testnet token1 address
//   const flashLoanAmount = web3.utils.toWei("10", "ether"); // Example flash loan amount on testnet
//   const minProfit = web3.utils.toWei("0.01", "ether"); // Minimum profit you want

//   await contract.methods
//     .executeArbitrage(token0, token1, flashLoanAmount, minProfit)
//     .send({ from: account.address, gas: 3000000 });

//   console.log("Arbitrage executed on Goerli!");
// }

// executeArbitrage();



// const Web3 = require("web3");
// const BalancerV3ArbitrageBot = require("../build/contracts/BalancerV3ArbitrageBot.json");

// async function executeArbitrage() {
//   const web3 = new Web3("https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID"); // Replace with your Infura project ID
//   const account = web3.eth.accounts.privateKeyToAccount("YOUR_PRIVATE_KEY"); // Replace with your private key
//   web3.eth.accounts.wallet.add(account);

//   const arbitrageContractAddress = "0xYourDeployedContractAddress"; // Replace with your deployed contract address
//   const contract = new web3.eth.Contract(BalancerV3ArbitrageBot.abi, arbitrageContractAddress);

//   const token0 = "0xTokenAddress0"; // Replace with token0 address
//   const token1 = "0xTokenAddress1"; // Replace with token1 address
//   const flashLoanAmount = web3.utils.toWei("100", "ether"); // Example flash loan amount
//   const minProfit = web3.utils.toWei("0.01", "ether"); // Minimum profit you want

//   await contract.methods
//     .executeArbitrage(token0, token1, flashLoanAmount, minProfit)
//     .send({ from: account.address, gas: 3000000 });

//   console.log("Arbitrage executed!");
// }

// executeArbitrage();
