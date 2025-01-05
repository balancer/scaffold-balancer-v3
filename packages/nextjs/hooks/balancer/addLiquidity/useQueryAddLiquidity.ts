import {
  AddLiquidity,
  AddLiquidityInput,
  AddLiquidityKind,
  InputAmount,
  OnChainProvider,
  PoolState,
} from "@balancer/sdk";
import { useQuery } from "@tanstack/react-query";
import { useTargetFork } from "~~/hooks/balancer";
import { Pool } from "~~/hooks/balancer/types";

export const useQueryAddLiquidity = (
  pool: Pool,
  amountsIn: InputAmount[],
  referenceAmount?: InputAmount,
  userData?: `0x${string}`,
) => {
  const { rpcUrl, chainId } = useTargetFork();

  const queryAddLiquidity = async () => {
    console.log("Fetching query...");
    const onchainProvider = new OnChainProvider(rpcUrl, chainId);
    const poolId = pool.address as `0x${string}`;
    const poolState: PoolState = await onchainProvider.pools.fetchPoolState(poolId, "CustomPool");

    // Construct the addLiquidity input object based on if pool allows unbalanced liquidity operations
    const addLiquidityInput: AddLiquidityInput =
      pool.poolConfig?.liquidityManagement.disableUnbalancedLiquidity && referenceAmount
        ? {
            kind: AddLiquidityKind.Proportional,
            referenceAmount,
            chainId,
            rpcUrl,
            userData,
          }
        : {
            kind: AddLiquidityKind.Unbalanced,
            amountsIn,
            chainId,
            rpcUrl,
            userData,
          };

    // Query addLiquidity to get the amount of BPT out
    const addLiquidity = new AddLiquidity();
    const queryOutput = await addLiquidity.query(addLiquidityInput, poolState);

    return queryOutput;
  };

  return useQuery({
    queryKey: ["queryAddLiquidity"],
    queryFn: queryAddLiquidity,
    enabled: false,
  });
};
