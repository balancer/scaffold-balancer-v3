import fs from "fs";
import { task } from "hardhat/config";
import type { TaskArguments } from "hardhat/types";
import path from "path";

task("task:computeACLAddress").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const deployer = (await ethers.getSigners())[9].address;
  const aclAddress = ethers.getCreateAddress({
    from: deployer,
    nonce: 0, // using nonce of 0 for the ACL contract
  });
  const envFilePath = path.join(__dirname, "../node_modules/fhevm/lib/.env.acl");
  const content = `ACL_CONTRACT_ADDRESS=${aclAddress}\n`;
  try {
    fs.writeFileSync(envFilePath, content, { flag: "w" });
    console.log(`ACL address ${aclAddress} written successfully!`);
  } catch (err) {
    console.error("Failed to write ACL address:", err);
  }

  const solidityTemplate = `// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

address constant aclAdd = ${aclAddress};\n`;

  try {
    fs.writeFileSync("node_modules/fhevm/lib/ACLAddress.sol", solidityTemplate, { encoding: "utf8", flag: "w" });
    console.log("node_modules/fhevm/lib/ACLAddress.sol file generated successfully!");
  } catch (error) {
    console.error("Failed to write node_modules/fhevm/lib/ACLAddress.sol", error);
  }
});

task("task:computeTFHEExecutorAddress").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const deployer = (await ethers.getSigners())[9].address;
  const execAddress = ethers.getCreateAddress({
    from: deployer,
    nonce: 1, // using nonce of 1 for the TFHEExecutor contract
  });
  const envFilePath = path.join(__dirname, "../node_modules/fhevm/lib/.env.exec");
  const content = `TFHE_EXECUTOR_CONTRACT_ADDRESS=${execAddress}\n`;
  try {
    fs.writeFileSync(envFilePath, content, { flag: "w" });
    console.log(`TFHE Executor address ${execAddress} written successfully!`);
  } catch (err) {
    console.error("Failed to write TFHE Executor address:", err);
  }

  const solidityTemplateCoprocessor = `// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

address constant fhevmCoprocessorAdd = ${execAddress};\n`;

  try {
    fs.writeFileSync("node_modules/fhevm/lib/FHEVMCoprocessorAddress.sol", solidityTemplateCoprocessor, {
      encoding: "utf8",
      flag: "w",
    });
    console.log("node_modules/fhevm/lib/FHEVMCoprocessorAddress.sol file generated successfully!");
  } catch (error) {
    console.error("Failed to write node_modules/fhevm/lib/FHEVMCoprocessorAddress.sol", error);
  }
});

task("task:computeKMSVerifierAddress").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const deployer = (await ethers.getSigners())[9].address;
  const kmsVerifierAddress = ethers.getCreateAddress({
    from: deployer,
    nonce: 2, // using nonce of 2 for the Kms Verifier contract
  });
  const envFilePath = path.join(__dirname, "../node_modules/fhevm/lib/.env.kmsverifier");
  const content = `KMS_VERIFIER_CONTRACT_ADDRESS=${kmsVerifierAddress}\n`;
  try {
    fs.writeFileSync(envFilePath, content, { flag: "w" });
    console.log(`KMS Verifier address ${kmsVerifierAddress} written successfully!`);
  } catch (err) {
    console.error("Failed to write KMS Verifier address:", err);
  }

  const solidityTemplate = `// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

address constant KMS_VERIFIER_CONTRACT_ADDRESS = ${kmsVerifierAddress};\n`;

  try {
    fs.writeFileSync("node_modules/fhevm/lib/KMSVerifierAddress.sol", solidityTemplate, {
      encoding: "utf8",
      flag: "w",
    });
    console.log("node_modules/fhevm/lib/KMSVerifierAddress.sol file generated successfully!");
  } catch (error) {
    console.error("Failed to write node_modules/fhevm/lib/KMSVerifierAddress.sol", error);
  }
});
