import {
  BALANCER_BATCH_ROUTER,
  BALANCER_ROUTER,
  PERMIT2,
  VAULT_V3,
  balancerBatchRouterAbi,
  balancerRouterAbi,
  permit2Abi,
  vaultExtensionAbi_V3,
} from "@balancer/sdk";
import { sepolia } from "viem/chains";
import scaffoldConfig from "~~/scaffold.config";
import { GenericContractsDeclaration } from "~~/utils/scaffold-eth/contract";

/**
 * @example
 * const externalContracts = {
 *   1: {
 *     DAI: {
 *       address: "0x...",
 *       abi: [...],
 *     },
 *   },
 * } as const;
 */

/**
 * @dev the `31337` local chain is configured to fork sepolia testnet so the balancer contract addresses correspond to sepolia
 * @notice using the `VaultExtension` abi for the Vault contract
 */
const externalContracts = {
  31337: {
    Vault: {
      address: VAULT_V3[scaffoldConfig.targetFork.id],
      abi: vaultExtensionAbi_V3,
    },
    Router: {
      address: BALANCER_ROUTER[scaffoldConfig.targetFork.id],
      abi: balancerRouterAbi,
    },
    BatchRouter: {
      address: BALANCER_BATCH_ROUTER[scaffoldConfig.targetFork.id],
      abi: balancerBatchRouterAbi,
    },
    Permit2: {
      address: PERMIT2[scaffoldConfig.targetFork.id],
      abi: permit2Abi,
    },
  },
  11155111: {
    Vault: {
      address: VAULT_V3[sepolia.id],
      abi: vaultExtensionAbi_V3,
    },
    Router: {
      address: BALANCER_ROUTER[sepolia.id],
      abi: balancerRouterAbi,
    },
    BatchRouter: {
      address: BALANCER_BATCH_ROUTER[sepolia.id],
      abi: balancerBatchRouterAbi,
    },
    Permit2: {
      address: PERMIT2[sepolia.id],
      abi: permit2Abi,
    },
  },
} as const;

export default externalContracts satisfies GenericContractsDeclaration;
