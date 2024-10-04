const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BalancerV3ArbitrageBot", function() {
  let arbitrageBot;
  let owner;
  let balancerVault;
  let uniswapRouter;
  let token0;
  let token1;

  beforeEach(async function() {
    [owner] = await ethers.getSigners();

    const MockBalancerVault = await ethers.getContractFactory("MockBalancerVault");
    balancerVault = await MockBalancerVault.deploy();

    const MockUniswapRouter = await ethers.getContractFactory("MockUniswapRouter");
    uniswapRouter = await MockUniswapRouter.deploy();

    const BalancerV3ArbitrageBot = await ethers.getContractFactory("BalancerV3ArbitrageBot");
    arbitrageBot = await BalancerV3ArbitrageBot.deploy(balancerVault.address, uniswapRouter.address);

    const MockToken = await ethers.getContractFactory("MockToken");
    token0 = await MockToken.deploy("Token0", "TKN0");
    token1 = await MockToken.deploy("Token1", "TKN1");

    // Mint tokens to the arbitrage bot
    await token0.transfer(arbitrageBot.address, ethers.utils.parseEther("1000"));
    await token1.transfer(arbitrageBot.address, ethers.utils.parseEther("1000"));

    // Approve tokens for Balancer and Uniswap
    await token0.connect(owner).approve(balancerVault.address, ethers.constants.MaxUint256);
    await token1.connect(owner).approve(balancerVault.address, ethers.constants.MaxUint256);
    await token0.connect(owner).approve(uniswapRouter.address, ethers.constants.MaxUint256);
    await token1.connect(owner).approve(uniswapRouter.address, ethers.constants.MaxUint256);

    // Approve tokens for the arbitrage bot
    await token0.connect(owner).approve(arbitrageBot.address, ethers.constants.MaxUint256);
    await token1.connect(owner).approve(arbitrageBot.address, ethers.constants.MaxUint256);
  });

  it("should execute arbitrage successfully", async function() {
    console.log("Setting up mock responses for successful arbitrage");
    await uniswapRouter.setMockAmountOut(ethers.utils.parseEther("110"));
    await balancerVault.setMockAmountOut(ethers.utils.parseEther("120"));

    console.log("Executing arbitrage");
    const tx = await arbitrageBot.executeArbitrage(
      token0.address,
      token1.address,
      ethers.utils.parseEther("100"),
      ethers.utils.parseEther("1"),
      ethers.utils.formatBytes32String("MOCK_POOL_ID")
    );

    console.log("Waiting for transaction");
    const receipt = await tx.wait();
    
    console.log("Transaction mined. Events:");
    for (const event of receipt.events) {
      if (event.event === "DebugLog") {
        console.log(`Debug: ${event.args[0]}`);
      } else if (event.event === "DebugLogUint") {
        console.log(`Debug: ${event.args[0]} - ${event.args[1]}`);
      } else if (event.event) {
        console.log(`Event: ${event.event}`);
      }
    }

    expect(receipt.events.some(e => e.event === "ArbitrageExecuted")).to.be.true;
  });

  it("should fail when arbitrage is not profitable", async function() {
    console.log("Setting up mock responses for unprofitable arbitrage");
    await uniswapRouter.setMockAmountOut(ethers.utils.parseEther("100"));
    await balancerVault.setMockAmountOut(ethers.utils.parseEther("99"));

    console.log("Executing arbitrage");
    const tx = arbitrageBot.executeArbitrage(
      token0.address,
      token1.address,
      ethers.utils.parseEther("100"),
      ethers.utils.parseEther("1"),
      ethers.utils.formatBytes32String("MOCK_POOL_ID")
    );

    await expect(tx).to.be.revertedWith("Arbitrage not profitable");

    try {
      await tx;
    } catch (error) {
      console.log("Error:", error.message);
    }
  });
});