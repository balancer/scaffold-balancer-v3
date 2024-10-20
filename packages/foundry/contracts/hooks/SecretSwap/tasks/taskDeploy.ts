import dotenv from "dotenv";
import fs from "fs";
import { task } from "hardhat/config";
import type { TaskArguments } from "hardhat/types";

task("task:deployGateway")
  .addParam("privateKey", "The deployer private key")
  .addParam("ownerAddress", "The owner address")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const deployer = new ethers.Wallet(taskArguments.privateKey).connect(ethers.provider);
    const envConfig2 = dotenv.parse(fs.readFileSync("node_modules/fhevm/lib/.env.kmsverifier"));
    const gatewayFactory = await ethers.getContractFactory("fhevm/gateway/GatewayContract.sol:GatewayContract");
    const Gateway = await gatewayFactory
      .connect(deployer)
      .deploy(taskArguments.ownerAddress, envConfig2.KMS_VERIFIER_CONTRACT_ADDRESS);
    await Gateway.waitForDeployment();
    const GatewayContractAddress = await Gateway.getAddress();
    const envConfig = dotenv.parse(fs.readFileSync("node_modules/fhevm/gateway/.env.gateway"));
    if (GatewayContractAddress !== envConfig.GATEWAY_CONTRACT_PREDEPLOY_ADDRESS) {
      throw new Error(
        `The nonce of the deployer account is not null. Please use another deployer private key or relaunch a clean instance of the fhEVM`,
      );
    }
    console.log("GatewayContract was deployed at address: ", GatewayContractAddress);
  });

task("task:deployACL").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const deployer = (await ethers.getSigners())[9];
  const factory = await ethers.getContractFactory("fhevm/lib/ACL.sol:ACL");
  const envConfigExec = dotenv.parse(fs.readFileSync("node_modules/fhevm/lib/.env.exec"));
  const acl = await factory.connect(deployer).deploy(envConfigExec.TFHE_EXECUTOR_CONTRACT_ADDRESS);
  await acl.waitForDeployment();
  const address = await acl.getAddress();
  const envConfigAcl = dotenv.parse(fs.readFileSync("node_modules/fhevm/lib/.env.acl"));
  if (address !== envConfigAcl.ACL_CONTRACT_ADDRESS) {
    throw new Error(`The nonce of the deployer account is not corret. Please relaunch a clean instance of the fhEVM`);
  }
  console.log("ACL was deployed at address:", address);
});

task("task:deployTFHEExecutor").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const deployer = (await ethers.getSigners())[9];
  const factory = await ethers.getContractFactory("TFHEExecutor");
  const exec = await factory.connect(deployer).deploy();
  await exec.waitForDeployment();
  const address = await exec.getAddress();
  const envConfig = dotenv.parse(fs.readFileSync("node_modules/fhevm/lib/.env.exec"));
  if (address !== envConfig.TFHE_EXECUTOR_CONTRACT_ADDRESS) {
    throw new Error(`The nonce of the deployer account is not corret. Please relaunch a clean instance of the fhEVM`);
  }
  console.log("TFHEExecutor was deployed at address:", address);
});

task("task:deployKMSVerifier").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const deployer = (await ethers.getSigners())[9];
  const factory = await ethers.getContractFactory("fhevm/lib/KMSVerifier.sol:KMSVerifier");
  const exec = await factory.connect(deployer).deploy();
  await exec.waitForDeployment();
  const address = await exec.getAddress();
  const envConfig = dotenv.parse(fs.readFileSync("node_modules/fhevm/lib/.env.kmsverifier"));
  if (address !== envConfig.KMS_VERIFIER_CONTRACT_ADDRESS) {
    throw new Error(`The nonce of the deployer account is not corret. Please relaunch a clean instance of the fhEVM`);
  }
  console.log("KMSVerifier was deployed at address:", address);
});
