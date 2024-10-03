async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const FlashLoanArbitrage = await ethers.getContractFactory("FlashLoanArbitrage");
    const balancerVault = "0x..."; // Balancer Vault Address
    const uniswapRouter = "0x..."; // Uniswap Router Address
    const sushiswapRouter = "0x..."; // Sushiswap Router Address
    
    const flashLoanArbitrage = await FlashLoanArbitrage.deploy(balancerVault, uniswapRouter, sushiswapRouter);
  
    console.log("FlashLoanArbitrage deployed to:", flashLoanArbitrage.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  