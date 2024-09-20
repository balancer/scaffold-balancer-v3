import type { Pool } from "./types";
import { VAULT_V3, vaultExtensionAbi_V3 } from "@balancer/sdk";
import { type Address } from "viem";
import { erc20ABI, usePublicClient, useQuery, useWalletClient } from "wagmi";
import abis from "~~/contracts/abis";
import { useTargetFork } from "~~/hooks/balancer";

export const useReadPool = (pool: Address | null) => {
  const client = usePublicClient();
  const { data: walletClient } = useWalletClient();
  const { chainId } = useTargetFork();
  const vault = VAULT_V3[chainId];

  const connectedAddress = walletClient?.account?.address;
  const poolAbi = abis.balancer.Pool;

  return useQuery<Pool>(
    ["PoolContract", { pool, vault, connectedAddress }],
    async () => {
      if (!pool) throw new Error("Pool address is required");

      const [
        name,
        symbol,
        totalSupply,
        decimals,
        vaultAddress,
        minInvariantRatio,
        maxInvariantRatio,
        minSwapFeePercentage,
        maxSwapFeePercentage,
        userBalance,
        isRegistered,
        poolTokenInfo,
        poolConfig,
        hooksConfig,
      ] = await Promise.all([
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
        client.readContract({
          abi: poolAbi,
          address: pool,
          functionName: "getMinimumInvariantRatio",
        }) as Promise<bigint>,
        client.readContract({
          abi: poolAbi,
          address: pool,
          functionName: "getMaximumInvariantRatio",
        }) as Promise<bigint>,
        client.readContract({
          abi: poolAbi,
          address: pool,
          functionName: "getMinimumSwapFeePercentage",
        }) as Promise<bigint>,
        client.readContract({
          abi: poolAbi,
          address: pool,
          functionName: "getMaximumSwapFeePercentage",
        }) as Promise<bigint>,
        client
          .readContract({
            abi: poolAbi,
            address: pool,
            functionName: "balanceOf",
            args: [connectedAddress],
          })
          .catch(() => 0n) as Promise<bigint>,
        // fetch more data about pool from vault contract
        client.readContract({
          abi: vaultExtensionAbi_V3,
          address: vault,
          functionName: "isPoolRegistered",
          args: [pool],
        }),
        client
          .readContract({
            abi: vaultExtensionAbi_V3,
            address: vault,
            functionName: "getPoolTokenInfo",
            args: [pool],
          })
          .catch(() => []),
        client
          .readContract({
            abi: vaultExtensionAbi_V3,
            address: vault,
            functionName: "getPoolConfig",
            args: [pool],
          })
          .catch(() => undefined), // return undefined if pool has not been registered
        client
          .readContract({
            abi: vaultExtensionAbi_V3,
            address: vault,
            functionName: "getHooksConfig",
            args: [pool],
          })
          .catch(() => undefined), // return undefined if pool has not been registered
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
        minInvariantRatio,
        maxInvariantRatio,
        minSwapFeePercentage,
        maxSwapFeePercentage,
        userBalance,
        poolTokens,
        poolConfig,
        hooksConfig,
      };
    },
    { enabled: !!pool },
  );
};

export type RefetchPool = ReturnType<typeof useReadPool>["refetch"];
