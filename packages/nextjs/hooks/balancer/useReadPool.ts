import { useEffect, useState } from "react";
import type { Pool } from "./types";
import { VAULT_V3, vaultExtensionAbi_V3 } from "@balancer/sdk";
import { type Address } from "viem";
import { erc20ABI, usePublicClient, useQuery, useWalletClient } from "wagmi";
import abis from "~~/contracts/abis";
import { useTargetFork } from "~~/hooks/balancer";

export const useReadPool = (address: Address | null) => {
  const [cache, setCache] = useState<Record<string, Pool>>({});

  const client = usePublicClient();
  const { data: walletClient } = useWalletClient();
  const { chainId } = useTargetFork();
  const vault = VAULT_V3[chainId];

  const connectedAddress = walletClient?.account?.address;
  const poolAbi = abis.balancer.Pool;

  const { data, isLoading, isError, isSuccess, refetch } = useQuery<Pool>(
    ["PoolContract", { address, vault, connectedAddress }],
    async () => {
      if (!address) throw new Error("Pool address is required");

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
          address: address,
          functionName: "name",
        }) as Promise<string>,
        client.readContract({
          abi: poolAbi,
          address: address,
          functionName: "symbol",
        }) as Promise<string>,
        client.readContract({
          abi: poolAbi,
          address: address,
          functionName: "totalSupply",
        }) as Promise<bigint>,
        client.readContract({
          abi: poolAbi,
          address: address,
          functionName: "decimals",
        }) as Promise<number>,
        client.readContract({
          abi: poolAbi,
          address: address,
          functionName: "getVault",
        }) as Promise<string>,
        client.readContract({
          abi: poolAbi,
          address: address,
          functionName: "getMinimumInvariantRatio",
        }) as Promise<bigint>,
        client.readContract({
          abi: poolAbi,
          address: address,
          functionName: "getMaximumInvariantRatio",
        }) as Promise<bigint>,
        client.readContract({
          abi: poolAbi,
          address: address,
          functionName: "getMinimumSwapFeePercentage",
        }) as Promise<bigint>,
        client.readContract({
          abi: poolAbi,
          address: address,
          functionName: "getMaximumSwapFeePercentage",
        }) as Promise<bigint>,
        client
          .readContract({
            abi: poolAbi,
            address: address,
            functionName: "balanceOf",
            args: [connectedAddress],
          })
          .catch(() => 0n) as Promise<bigint>,
        // fetch more data about pool from vault contract
        client.readContract({
          abi: vaultExtensionAbi_V3,
          address: vault,
          functionName: "isPoolRegistered",
          args: [address],
        }),
        client
          .readContract({
            abi: vaultExtensionAbi_V3,
            address: vault,
            functionName: "getPoolTokenInfo",
            args: [address],
          })
          .catch(() => []),
        client
          .readContract({
            abi: vaultExtensionAbi_V3,
            address: vault,
            functionName: "getPoolConfig",
            args: [address],
          })
          .catch(() => undefined), // return undefined if pool has not been registered
        client
          .readContract({
            abi: vaultExtensionAbi_V3,
            address: vault,
            functionName: "getHooksConfig",
            args: [address],
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
        address: address,
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
    { enabled: !!address },
  );

  useEffect(() => {
    if (isSuccess && data && address) {
      setCache(prev => ({ ...prev, [address]: data }));
    }
  }, [isSuccess, data, address]);

  return {
    data: address ? cache[address] || data : null,
    isLoading,
    isError,
    isSuccess,
    refetch,
  };
};

export type RefetchPool = ReturnType<typeof useReadPool>["refetch"];
