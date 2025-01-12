import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
import * as fs from "fs-extra";
import "hardhat-deploy";
import "hardhat-ignore-warnings";
import type { HardhatUserConfig } from "hardhat/config";
import { extendProvider } from "hardhat/config";
import { task } from "hardhat/config";
import type { NetworkUserConfig } from "hardhat/types";
import { resolve } from "path";
import * as path from "path";

import CustomProvider from "./CustomProvider";
// Adjust the import path as needed
import "./tasks/accounts";
import "./tasks/getEthereumAddress";
import "./tasks/taskDeploy";
import "./tasks/taskGatewayRelayer";
import "./tasks/taskTFHE";

extendProvider(async (provider) => {
  const newProvider = new CustomProvider(provider);
  return newProvider;
});

task("compile:specific", "Compiles only the specified contract")
  .addParam("contract", "The contract's path")
  .setAction(async ({ contract }, hre) => {
    // Adjust the configuration to include only the specified contract
    hre.config.paths.sources = contract;

    await hre.run("compile");
  });

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
dotenv.config({ path: resolve(__dirname, dotenvConfigPath) });

// Ensure that we have all the environment variables we need.
const mnemonic: string | undefined = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}

const chainIds = {
  Inco: 9000,
  local: 9000,
  localNetwork1: 9000,
  multipleValidatorTestnet: 8009,
};

function getChainConfig(chain: keyof typeof chainIds): NetworkUserConfig {
  let jsonRpcUrl: string;
  switch (chain) {
    case "local":
      jsonRpcUrl = "http://localhost:8545";
      break;
    case "localNetwork1":
      jsonRpcUrl = "http://127.0.0.1:9650/ext/bc/fhevm/rpc";
      break;
    case "multipleValidatorTestnet":
      jsonRpcUrl = "https://rpc.fhe-ethermint.zama.ai";
      break;
    case "Inco":
      jsonRpcUrl = "https://validator.rivest.inco.org";
      break;
  }
  return {
    accounts: {
      count: 10,
      mnemonic,
      path: "m/44'/60'/0'/0",
    },
    chainId: chainIds[chain],
    url: jsonRpcUrl,
  };
}

task("coverage").setAction(async (taskArgs, hre, runSuper) => {
  hre.config.networks.hardhat.allowUnlimitedContractSize = true;
  hre.config.networks.hardhat.blockGasLimit = 1099511627775;
  await runSuper(taskArgs);
});

task("test", async (taskArgs, hre, runSuper) => {
  // Run modified test task
  if (hre.network.name === "hardhat") {
    // in fhevm mode all this block is done when launching the node via `pnmp fhevm:start`
    await hre.run("compile:specific", { contract: "contracts" });
    const sourceDir = path.resolve(__dirname, "node_modules/fhevm/");
    const destinationDir = path.resolve(__dirname, "fhevmTemp/");
    fs.copySync(sourceDir, destinationDir, { dereference: true });
    await hre.run("compile:specific", { contract: "fhevmTemp/lib" });
    await hre.run("compile:specific", { contract: "fhevmTemp/gateway" });
    const abiDir = path.resolve(__dirname, "abi");
    fs.ensureDirSync(abiDir);
    const sourceFile = path.resolve(__dirname, "artifacts/fhevmTemp/lib/TFHEExecutor.sol/TFHEExecutor.json");
    const destinationFile = path.resolve(abiDir, "TFHEExecutor.json");
    fs.copyFileSync(sourceFile, destinationFile);

    const targetAddress = "0x000000000000000000000000000000000000005d";
    const MockedPrecompile = await hre.artifacts.readArtifact("MockedPrecompile");
    const bytecode = MockedPrecompile.deployedBytecode;
    await hre.network.provider.send("hardhat_setCode", [targetAddress, bytecode]);
    console.log(`Code of Mocked Pre-compile set at address: ${targetAddress}`);

    const privKeyDeployer = process.env.PRIVATE_KEY_GATEWAY_DEPLOYER;
    await hre.run("task:computePredeployAddress", { privateKey: privKeyDeployer });
    await hre.run("task:computeACLAddress");
    await hre.run("task:computeTFHEExecutorAddress");
    await hre.run("task:computeKMSVerifierAddress");
    await hre.run("task:deployACL");
    await hre.run("task:deployTFHEExecutor");
    await hre.run("task:deployKMSVerifier");
    await hre.run("task:launchFhevm", { skipGetCoin: false });
  }
  await runSuper();
});

const config: HardhatUserConfig = {
  defaultNetwork: "local",
  namedAccounts: {
    deployer: 0,
  },
  mocha: {
    timeout: 500000,
  },
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: "./contracts",
  },
  networks: {
    hardhat: {
      accounts: {
        count: 10,
        mnemonic,
        path: "m/44'/60'/0'/0",
      },
    },
    Inco: getChainConfig("Inco"),
    localDev: getChainConfig("local"),
    local: getChainConfig("local"),
    localNetwork1: getChainConfig("localNetwork1"),
    multipleValidatorTestnet: getChainConfig("multipleValidatorTestnet"),
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.24",
    settings: {
      metadata: {
        // Not including the metadata hash
        // https://github.com/paulrberg/hardhat-template/issues/31
        bytecodeHash: "none",
      },
      viaIR: true,
      // Disable the optimizer when debugging
      // https://hardhat.org/hardhat-network/#solidity-optimizer-support
      optimizer: {
        enabled: true,
        runs: 200,
        details: {
          yul: true
        }
      },
      evmVersion: "cancun",
      
    },
  },
  warnings: {
    "*": {
      "transient-storage": false,
    },
  },
  typechain: {
    outDir: "types",
    target: "ethers-v6",
  },
};

export default config;