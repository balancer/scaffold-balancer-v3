import {
  // erc20ABI,
  usePublicClient,
  useQuery,
} from "wagmi";
import externalContracts from "~~/contracts/externalContracts";

/**
 * Read data about pool assets from Balancer's VaultExtension contract
 * https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#pool-information
 *
 * @dev all of the reads will revert if the pool is not registered AND initialized
 */
export const useVaultContract = (poolAddress: string) => {
  const client = usePublicClient();
  const chainId = client.chain.id;

  const { VaultExtension } = externalContracts[chainId as keyof typeof externalContracts];

  return useQuery<any>(
    ["VaultContract", poolAddress],
    async () => {
      //   const [poolTokenInfo] = await Promise.all([
      //     client.readContract({
      //       abi: VaultExtension.abi,
      //       address: VaultExtension.address,
      //       functionName: "getPoolTokenInfo",
      //       args: [poolAddress],
      //     }),
      //   ]);

      // Reverts if pool is not registered
      const isInitialized = await client
        .readContract({
          abi: VaultExtension.abi,
          address: VaultExtension.address,
          functionName: "isPoolInitialized",
          args: [poolAddress],
        })
        .catch(() => false);

      return {
        isInitialized,
        // poolTokenInfo,
      };
    },
    { enabled: poolAddress !== undefined },
  );
};
