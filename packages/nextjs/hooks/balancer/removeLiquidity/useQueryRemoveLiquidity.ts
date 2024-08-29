import {
  InputAmount,
  OnChainProvider,
  PoolState,
  RemoveLiquidity,
  RemoveLiquidityBuildCallOutput,
  RemoveLiquidityInput,
  RemoveLiquidityKind,
  Slippage,
} from "@balancer/sdk";
import { useQuery } from "@tanstack/react-query";
import { Pool, useTargetFork } from "~~/hooks/balancer";

export const useQueryRemoveLiquidity = (
  queryKey: string,
  pool: Pool,
  rawAmount: bigint,
  setCall?: React.Dispatch<React.SetStateAction<RemoveLiquidityBuildCallOutput | undefined>>,
) => {
  const { rpcUrl, chainId } = useTargetFork();

  const queryRemoveLiquidity = async () => {
    const slippage = Slippage.fromPercentage("1"); // 1%
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

    // Construct call object for transaction
    const call = removeLiquidity.buildCall({
      ...queryOutput,
      slippage,
      chainId,
      wethIsEth: false,
    });
    console.log("call", call);
    if (setCall) setCall(call); // save to state for use in removeLiquidity()

    return queryOutput;
  };

  return useQuery({
    queryKey: [queryKey, rawAmount.toString()],
    queryFn: queryRemoveLiquidity,
    enabled: false,
  });
};
