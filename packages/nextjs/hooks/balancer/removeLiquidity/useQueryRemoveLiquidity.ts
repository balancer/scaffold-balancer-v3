import {
  InputAmount,
  OnChainProvider,
  PoolState,
  RemoveLiquidity,
  RemoveLiquidityInput,
  RemoveLiquidityKind,
} from "@balancer/sdk";
import { useQuery } from "@tanstack/react-query";
import { Pool, useTargetFork } from "~~/hooks/balancer";

export const useQueryRemoveLiquidity = (queryKey: string, pool: Pool, rawAmount: bigint) => {
  const { rpcUrl, chainId } = useTargetFork();

  const queryRemoveLiquidity = async () => {
    const onchainProvider = new OnChainProvider(rpcUrl, chainId);
    const poolId = pool.address as `0x${string}`;
    const poolState: PoolState = await onchainProvider.pools.fetchPoolState(poolId, "CustomPool");

    // Construct the RemoveLiquidityInput, in this case a RemoveLiquiditySingleTokenExactIn
    const bptIn: InputAmount = {
      rawAmount,
      decimals: pool.decimals,
      address: poolState.address,
    };

    // Construct the RemoveLiquidityInput, in this case an RemoveLiquidityProportional
    const removeLiquidityInput: RemoveLiquidityInput = {
      chainId,
      rpcUrl,
      bptIn,
      kind: RemoveLiquidityKind.Proportional,
    };

    // Query removeLiquidity to get the token out amounts
    const removeLiquidity = new RemoveLiquidity();
    const queryOutput = await removeLiquidity.query(removeLiquidityInput, poolState);

    return queryOutput;
  };

  return useQuery({
    queryKey: [queryKey, rawAmount.toString()],
    queryFn: queryRemoveLiquidity,
    enabled: false,
  });
};
