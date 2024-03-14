import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
// import { Contract } from "ethers";

/**
 * Deploys a contract named "ConstantPricePool" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployConstantPricePool: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network goerli`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` which will fill DEPLOYER_PRIVATE_KEY
    with a random private key in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // Vault address is the same for all pools
  const VAULT_ADDRESS = "0x1FC7F1F84CFE61a04224AC8D3F87f56214FeC08c";

  // Deploy ConstantPricePool
  const constantPoolName = "Balancer Constant Price Pool";
  const constantPoolSymbol = "B-50DAI-50USDe";
  const constantPoolArgs = [VAULT_ADDRESS, constantPoolName, constantPoolSymbol];

  await deploy("ConstantPricePool", {
    from: deployer,
    args: constantPoolArgs, // contract constructor arguments
    log: true,
  });

  // Deploy DynamicPricePool
  const dynamicPoolName = "Balancer Dynamic Price Pool";
  const dynamicPoolSymbol = "weETH/ezETH/rswETH";
  const dynamicPoolArgs = [VAULT_ADDRESS, dynamicPoolName, dynamicPoolSymbol];

  await deploy("DynamicPricePool", {
    from: deployer,
    args: dynamicPoolArgs, // contract constructor arguments
    log: true,
  });

  // Get a deployed contract to interact with it after deploying.
  // const yourContract = await hre.ethers.getContract<Contract>("ConstantPricePool", deployer);
  // const poolTokens =  await ConstantPricePool.getPoolTokens());
};

export default deployConstantPricePool;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployConstantPricePool.tags = ["all"];
