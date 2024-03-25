import {
  // erc20ABI,
  usePublicClient,
  useQuery,
} from "wagmi";
import externalContracts from "~~/contracts/externalContracts";

/**
 * Read data about pool assets from Balancer's Vault contract
 * https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#pool-information
 *
 * @dev reads will revert if the pool is not registered
 */
export const useVaultContract = (poolAddress: string) => {
  const client = usePublicClient();
  const chainId = client.chain.id;

  const { Vault } = externalContracts[chainId as keyof typeof externalContracts];

  return useQuery<any>(
    ["VaultContract", poolAddress],
    async () => {
      const [getPoolTokens, poolTokenInfo, poolConfig] = await Promise.all([
        client.readContract({
          abi: Vault.abi,
          address: Vault.address,
          functionName: "getPoolTokens",
          args: [poolAddress],
        }),
        client.readContract({
          abi: Vault.abi,
          address: Vault.address,
          functionName: "getPoolTokenInfo",
          args: [poolAddress],
        }),
        client.readContract({
          abi: Vault.abi,
          address: Vault.address,
          functionName: "getPoolConfig",
          args: [poolAddress],
        }),
      ]);

      // Reverts if pool is not registered
      const isInitialized = await client
        .readContract({
          abi: Vault.abi,
          address: Vault.address,
          functionName: "isPoolInitialized",
          args: [poolAddress],
        })
        .catch(() => false);

      return {
        isInitialized,
        getPoolTokens,
        poolTokenInfo,
        poolConfig,
      };
    },
    { enabled: poolAddress !== undefined },
  );
};
