import type { Pool } from "./types";
import { type Address } from "viem";
import { erc20ABI, usePublicClient, useQuery, useWalletClient } from "wagmi";
import abis from "~~/contracts/abis";
import externalContracts from "~~/contracts/externalContracts";

/**
 * Fetch all relevant details for a pool
 */
export const usePoolContract = (pool: Address) => {
  const client = usePublicClient();
  const { data: walletClient } = useWalletClient();
  const chainId = client.chain.id;
  const { Vault } = externalContracts[chainId as keyof typeof externalContracts];

  const connectedAddress = walletClient?.account?.address;

  const poolAbi = abis.balancer.Pool;

  return useQuery<Pool>(
    ["PoolContract", { pool, vaultAddress: Vault.address, connectedAddress }],
    async () => {
      const [name, symbol, totalSupply, decimals, vaultAddress, userBalance, isRegistered, poolTokenInfo, poolConfig] =
        await Promise.all([
          // fetch data about BPT from pool contract
          client.readContract({
            abi: poolAbi,
            address: pool,
            functionName: "name",
          }) as Promise<string>,
          client.readContract({
            abi: poolAbi,
            address: pool,
            functionName: "symbol",
          }) as Promise<string>,
          client.readContract({
            abi: poolAbi,
            address: pool,
            functionName: "totalSupply",
          }) as Promise<bigint>,
          client.readContract({
            abi: poolAbi,
            address: pool,
            functionName: "decimals",
          }) as Promise<number>,
          client.readContract({
            abi: poolAbi,
            address: pool,
            functionName: "getVault",
          }) as Promise<string>,
          client
            .readContract({
              abi: poolAbi,
              address: pool,
              functionName: "balanceOf",
              args: [connectedAddress],
            })
            .catch(() => 0n) as Promise<bigint>,
          // fetch data about pool assets from vault contract
          client.readContract({
            abi: Vault.abi,
            address: Vault.address,
            functionName: "isPoolRegistered",
            args: [pool],
          }),
          client
            .readContract({
              abi: Vault.abi,
              address: Vault.address,
              functionName: "getPoolTokenInfo", // https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#getpooltokeninfo
              args: [pool],
            })
            .catch(() => []),
          client
            .readContract({
              abi: Vault.abi,
              address: Vault.address,
              functionName: "getPoolConfig", // https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#getpoolconfig
              args: [pool],
            })
            .catch(() => undefined), // return undefined if the pool is not registered
        ]);

      // populate the pool tokens with balances, names, symbols, and decimals
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
            balance: tokenBalance,
          };
        }),
      );

      return {
        address: pool,
        symbol,
        name,
        isRegistered,
        totalSupply,
        decimals,
        vaultAddress,
        userBalance,
        poolTokens,
        poolConfig,
      };
    },
    { enabled: pool !== "" },
  );
};

export type RefetchPool = ReturnType<typeof usePoolContract>["refetch"];
