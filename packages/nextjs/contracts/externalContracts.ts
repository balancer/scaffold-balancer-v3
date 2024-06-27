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
const externalContracts = {} as const;

export default externalContracts satisfies GenericContractsDeclaration;
