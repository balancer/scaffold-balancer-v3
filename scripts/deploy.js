async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BalancerV3ArbitrageBot = await ethers.getContractFactory("BalancerV3ArbitrageBot");
  
    // Replace these with the correct Sepolia testnet addresses
    const balancerVaultAddress = "0xba12222222228d8ba445958a75a0704d566bf2c8";  // Sepolia Balancer Vault address
    // const uniswapRouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";  // goerla Uniswap Router address
    const uniswapRouterAddress = "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008";  // Sepolia Uniswap Router address
    
    const arbitrageBot = await BalancerV3ArbitrageBot.deploy(balancerVaultAddress, uniswapRouterAddress);
  
    console.log("BalancerV3ArbitrageBot deployed to:", arbitrageBot.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  
// async function main() {
//     const [deployer] = await ethers.getSigners();
//     console.log("Deploying contracts with the account:", deployer.address);
  
//     const BalancerV3ArbitrageBot = await ethers.getContractFactory("BalancerV3ArbitrageBot");
//     const balancerVaultAddress = "0x..."; // Goerli Balancer Vault address
//     const uniswapRouterAddress = "0x..."; // Goerli Uniswap Router address
//     const arbitrageBot = await BalancerV3ArbitrageBot.deploy(balancerVaultAddress, uniswapRouterAddress);
  
//     console.log("BalancerV3ArbitrageBot deployed to:", arbitrageBot.address);
//   }
  
//   main()
//     .then(() => process.exit(0))
//     .catch((error) => {
//       console.error(error);
//       process.exit(1);
//     });
  
// async function main() {
//     const [deployer] = await ethers.getSigners();
  
//     console.log("Deploying contracts with the account:", deployer.address);
  
//     const FlashLoanArbitrage = await ethers.getContractFactory("FlashLoanArbitrage");
//     const balancerVault = "0x..."; // Balancer Vault Address
//     const uniswapRouter = "0x..."; // Uniswap Router Address
//     const sushiswapRouter = "0x..."; // Sushiswap Router Address
    
//     const flashLoanArbitrage = await FlashLoanArbitrage.deploy(balancerVault, uniswapRouter, sushiswapRouter);
  
//     console.log("FlashLoanArbitrage deployed to:", flashLoanArbitrage.address);
//   }
  
//   main()
//     .then(() => process.exit(0))
//     .catch((error) => {
//       console.error(error);
//       process.exit(1);
//     });
  