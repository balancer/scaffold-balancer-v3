import hre from "hardhat";
import { networkConfig } from "../helper.config";
import { Contract } from "ethers";

/**
 * Initialize a pool that has already been registered on sepolia
 *
 * balancer docs
 * https://docs-v3.balancer.fi/concepts/router/overview.html#initialize
 *
 * initialize() function
 * https://github.com/balancer/balancer-v3-monorepo/blob/2ad8501c85e8afb2f25d970344af700a571b1d0b/pkg/vault/contracts/VaultExtension.sol#L130-L149
 *
 */

const routerAbi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "pool",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "contract IERC20[]",
        name: "tokens",
        type: "address[]",
      },
      {
        internalType: "uint256[]",
        name: "exactAmountsIn",
        type: "uint256[]",
      },
      {
        internalType: "uint256",
        name: "minBptAmountOut",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "userData",
        type: "bytes",
      },
    ],
    name: "initialize",
    outputs: [
      {
        internalType: "uint256",
        name: "bptAmountOut",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
];

async function main() {
  const privateKey = process.env.DEPLOYER_PRIVATE_KEY;
  if (!privateKey) {
    console.log("🚫️ Please set a PRIVATE_KEY var at packages/hardhat/.env");
    return;
  }
  if (hre.network.name !== "sepolia") {
    throw new Error("This script is only configured for sepolia network");
  }
  const chainId = Number(await hre.ethers.provider.getNetwork().then(network => network.chainId));

  // grab the Router contract
  const { balancer, customPool } = networkConfig[chainId];
  const [signer] = await hre.ethers.getSigners();
  const router = await hre.ethers.getContractAt(routerAbi, balancer.routerAddr, signer);

  /***************************
   *  args for initialize    *
   ***************************/
  // 1. Address of pool to initialize
  const { target: poolAddress } = await hre.ethers.getContract<Contract>(customPool.name, signer);
  // 2. Tokens used to seed the pool (must match the registered tokens)
  const tokens = customPool.tokenConfig.map((token: any) => token.token);
  // 3. Exact amounts of tokens to be added, sorted in token registration order
  const exactAmountsIn = [100, 100];
  // 4. Minimum amount of pool tokens to be received
  const minBptAmountOut = 0;
  // 5. If true, incoming ETH will be wrapped to WETH; otherwise the Vault will pull WETH tokens
  const wethIsEth = false;
  // 6. Additional (optional) data required for adding initial liquidity
  const userData = "0x";

  console.log("Sending tx to initialize pool...");
  const txResponse = await router.initialize(poolAddress, tokens, exactAmountsIn, minBptAmountOut, wethIsEth, userData);
  console.log(txResponse);
  console.log("Waiting for tx to be mined...");
  const txReceipt = await txResponse.wait();
  console.log("Pool registered!!!");
  console.log(txReceipt);
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
