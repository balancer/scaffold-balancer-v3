import { PoolAbi } from "./PoolAbi";
import type { Pool } from "./types";
// import { formatUnits } from "viem";
import {
  // erc20ABI,
  usePublicClient,
  useQuery,
} from "wagmi";

/**
 * Read a pool contract's details
 */
export const usePoolContract = (poolAddress: string) => {
  const client = usePublicClient();

  return useQuery<Pool>(
    ["PoolContract", poolAddress],
    async () => {
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

      return {
        name,
        address: poolAddress,
        symbol,
        totalSupply,
        decimals,
        vaultAddress,
      } as Pool;
    },
    { enabled: poolAddress !== undefined },
  );
};
