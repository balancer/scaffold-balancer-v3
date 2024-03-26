import { PoolAbi } from "./PoolAbi";
// import type { Pool } from "./types";
import { formatUnits } from "viem";
import { erc20ABI, usePublicClient, useQuery } from "wagmi";
import externalContracts from "~~/contracts/externalContracts";

/**
 * Read a pool contract's details
 * @dev the pool contract only contains basic information relating to the BPT token
 * all the data about the pool's assets is stored in the vault contract
 */
export const usePoolContract = (poolAddress: string) => {
  const client = usePublicClient();
  const chainId = client.chain.id;

  const { Vault } = externalContracts[chainId as keyof typeof externalContracts];

  return useQuery<any>(
    ["PoolData", poolAddress, Vault.address],
    async () => {
      // fetch data about BPT from pool contract
      const [name, symbol, totalSupply, decimals, vaultAddress] = await Promise.all([
        client.readContract({
          abi: PoolAbi,
          address: poolAddress,
          functionName: "name",
        }),
        client.readContract({
          abi: PoolAbi,
          address: poolAddress,
          functionName: "symbol",
        }),
        client.readContract({
          abi: PoolAbi,
          address: poolAddress,
          functionName: "totalSupply",
        }),
        client.readContract({
          abi: PoolAbi,
          address: poolAddress,
          functionName: "decimals",
        }),
        client.readContract({
          abi: PoolAbi,
          address: poolAddress,
          functionName: "getVault",
        }),
      ]);

      const isRegistered = await client
        .readContract({
          abi: Vault.abi,
          address: Vault.address,
          functionName: "isPoolRegistered",
          args: [poolAddress],
        })
        .catch(() => false);

      // Reverts if pool is not registered
      const isInitialized = await client
        .readContract({
          abi: Vault.abi,
          address: Vault.address,
          functionName: "isPoolInitialized",
          args: [poolAddress],
        })
        .catch(() => false);

      // fetch data about pool assets from vault contract
      const [poolTokenInfo, poolConfig] = await Promise.all([
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
      ]).catch(() => [[], [], []]); // returns empty arrays if the pool is not registered

      const poolTokenAddresses = poolTokenInfo[0];
      const poolTokenBalances = poolTokenInfo[2];

      const poolTokensWithBalances = Array.from({ length: poolTokenAddresses.length }, (_, i) => ({
        tokenAddress: poolTokenAddresses[i],
        tokenBalance: poolTokenBalances[i],
      }));

      const poolTokens = await Promise.all(
        poolTokensWithBalances.map(async ({ tokenAddress, tokenBalance }) => {
          const [symbol, decimals, name] = await Promise.all([
            client.readContract({
              abi: erc20ABI,
              address: tokenAddress,
              functionName: "symbol",
            }),
            client.readContract({
              abi: erc20ABI,
              address: tokenAddress,
              functionName: "decimals",
            }),
            client.readContract({
              abi: erc20ABI,
              address: tokenAddress,
              functionName: "name",
            }),
          ]);
          return {
            address: tokenAddress,
            name,
            symbol,
            decimals,
            balance: formatUnits(tokenBalance, decimals),
          };
        }),
      );

      return {
        address: poolAddress,
        symbol,
        name,
        totalSupply: formatUnits(totalSupply as bigint, decimals as number),
        decimals,
        vaultAddress,
        isInitialized,
        isRegistered,
        poolTokens,
        poolConfig,
      };
    },
    { enabled: poolAddress !== undefined },
  );
};
