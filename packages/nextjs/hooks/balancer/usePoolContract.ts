import { PoolAbi } from "./PoolAbi";
// import type { Pool } from "./types";
import { type Address, formatUnits } from "viem";
import { erc20ABI, usePublicClient, useQuery } from "wagmi";
import externalContracts from "~~/contracts/externalContracts";

/**
 * Fetch all relevant details for a pool
 */
export const usePoolContract = (poolAddress: Address | undefined) => {
  const client = usePublicClient();
  const chainId = client.chain.id;

  const { Vault } = externalContracts[chainId as keyof typeof externalContracts];

  return useQuery<any>(
    ["PoolContract", { poolAddress, vaultAddress: Vault.address }],
    async () => {
      // fetch data about BPT from pool contract
      const [name, symbol, totalSupply, decimals, vaultAddress] = await Promise.all([
        client.readContract({
          abi: PoolAbi,
          address: poolAddress as Address,
          functionName: "name",
        }),
        client.readContract({
          abi: PoolAbi,
          address: poolAddress as Address,
          functionName: "symbol",
        }),
        client.readContract({
          abi: PoolAbi,
          address: poolAddress as Address,
          functionName: "totalSupply",
        }),
        client.readContract({
          abi: PoolAbi,
          address: poolAddress as Address,
          functionName: "decimals",
        }),
        client.readContract({
          abi: PoolAbi,
          address: poolAddress as Address,
          functionName: "getVault",
        }),
      ]);

      const isRegistered = await client.readContract({
        abi: Vault.abi,
        address: Vault.address,
        functionName: "isPoolRegistered",
        args: [poolAddress as Address],
      });

      const poolTokenInfo = await client
        .readContract({
          abi: Vault.abi,
          address: Vault.address,
          functionName: "getPoolTokenInfo", // https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#getpooltokeninfo
          args: [poolAddress as Address],
        })
        .catch(() => []); // return empty array if the pool is not registered

      const poolConfig = await client
        .readContract({
          abi: Vault.abi,
          address: Vault.address,
          functionName: "getPoolConfig", // https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#getpoolconfig
          args: [poolAddress as Address],
        })
        .catch(() => []); // return empty array if the pool is not registered

      // populate the poolTokens with balances, names, symbols, and decimals
      const [poolTokenAddresses, , poolTokenBalances] = poolTokenInfo;
      const poolTokensWithBalances = Array.from({ length: poolTokenAddresses?.length ?? 0 }, (_, i) => ({
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
        isRegistered,
        totalSupply: formatUnits(totalSupply as bigint, decimals as number),
        decimals,
        vaultAddress,
        poolTokens,
        poolConfig,
      };
    },
    { enabled: poolAddress !== undefined },
  );
};
