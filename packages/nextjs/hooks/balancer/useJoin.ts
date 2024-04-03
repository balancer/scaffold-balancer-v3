// import { useState } from "react";
import {
  AddLiquidity,
  AddLiquidityInput,
  AddLiquidityKind,
  BalancerApi, //   ChainId,
  InputAmount,
  Slippage,
} from "@balancer/sdk";
import { useWalletClient } from "wagmi";

// interface QueryJoinStatus {
//   isQuerying: boolean;
//   error: Error | null;
//   success: boolean;
// }

type UseJoinReturn = [(pool: string, amountsIn: InputAmount[]) => QueryJoinReturn];

type QueryJoinReturn = Promise<
  | {
      expectedBptOut: string;
      minBptOut: string;
      call: any;
    }
  | undefined
>;

/**
 * @returns {Function} queryJoin
 * @returns {QueryJoinStatus} queryJoinStatus
 * https://docs-v3.balancer.fi/concepts/developer-guides/add-liquidity-to-pool.html#javascript-with-sdk
 */
export const useJoin = (): UseJoinReturn => {
  const { data: client } = useWalletClient();

  /**
   * @param pool the address of pool
   * @param amountsIn the amounts of tokens
   * @returns expectedBptOut
   * @returns minBptOut
   * @returns call
   */
  const queryJoin = async (pool: string, amountsIn: InputAmount[]): QueryJoinReturn => {
    try {
      // User defined
      const chainId = client?.chain.id as number;
      const rpcUrl = client?.chain.rpcUrls.alchemy.http[0] as string;
      const slippage = Slippage.fromPercentage("1"); // 1%

      // API can be used to fetch relevant pool data
      const balancerApi = new BalancerApi("https://backend-v3-canary.beets-ftm-node.com/graphql", chainId);

      const poolState = await balancerApi.pools.fetchPoolState(pool);

      // Construct the AddLiquidityInput, in this case an AddLiquidityUnbalanced
      const addLiquidityInput: AddLiquidityInput = {
        amountsIn,
        chainId,
        rpcUrl,
        kind: AddLiquidityKind.Unbalanced,
      };

      // Query addLiquidity to get the amount of BPT out
      const addLiquidity = new AddLiquidity();
      const queryOutput = await addLiquidity.query(addLiquidityInput, poolState);

      const expectedBptOut = queryOutput.bptOut.amount.toString();
      console.log(`Expected BPT Out: ${expectedBptOut}`);

      // Applies slippage to the BPT out amount and constructs the call
      const call = addLiquidity.buildCall({
        ...queryOutput,
        slippage,
        chainId,
        wethIsEth: false,
      });

      const minBptOut = call.minBptOut.amount.toString();
      console.log(`Min BPT Out: ${minBptOut}`);

      return { expectedBptOut, minBptOut, call };
    } catch (error) {
      console.error("error", error);
    }
  };

  /**
   * @param call the call object from Balancer SDK
   */
  // const joinPool = async call => {
  //   const hash = await client?.sendTransaction({
  //     account: client.account,
  //     data: call.call,
  //     to: call.to,
  //     value: call.value,
  //   });
  // };

  return [queryJoin];
};
