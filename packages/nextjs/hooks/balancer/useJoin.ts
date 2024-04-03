import { useState } from "react";
import {
  AddLiquidity,
  AddLiquidityInput,
  AddLiquidityKind,
  BalancerApi, //   ChainId,
  InputAmount,
  Slippage,
} from "@balancer/sdk";
import { useWalletClient } from "wagmi";

type QueryJoinResponse = Promise<any>;

type JoinPoolTxResponse = Promise<string | undefined>;

type JoinPoolFunctions = {
  queryJoin: (pool: string, amountsIn: InputAmount[]) => QueryJoinResponse;
  joinPool: () => JoinPoolTxResponse;
};

/**
 * Custom hook for joining pools
 *
 * queryJoin: Queries the expected and minimum BPT out amount for a given pool and token amounts.
 * joinPool: Sends the join transaction using the call data generated by `queryJoin`
 */
export const useJoin = (): JoinPoolFunctions => {
  const [call, setCall] = useState<any>();

  const { data: client } = useWalletClient();

  /**
   * @param pool the address of pool
   * @param amountsIn the amounts of tokens
   * @returns An object containing the expected and minimum BPT out amount.
   */
  const queryJoin = async (pool: string, amountsIn: InputAmount[]): QueryJoinResponse => {
    try {
      console.log("pool", pool);
      console.log("client", client);
      // User defined
      const chainId = client?.chain.id as number;
      const rpcUrl = client?.chain.rpcUrls.alchemy.http[0] as string;
      const slippage = Slippage.fromPercentage("1"); // 1%

      // API can be used to fetch relevant pool data
      const balancerApi = new BalancerApi("https://backend-v3-canary.beets-ftm-node.com/graphql", chainId);
      console.log("balancerApi", balancerApi);

      const poolState = await balancerApi.pools.fetchPoolState(pool);
      console.log("poolState", poolState);

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

      setCall(call);

      const minBptOut = call.minBptOut.amount.toString();
      console.log(`Min BPT Out: ${minBptOut}`);

      return { expectedBptOut, minBptOut };
    } catch (error) {
      console.error("error", error);
    }
  };

  /**
   * @param call the call object from Balancer SDK used to construct the transaction
   * @returns the join pool transaction hash
   */
  const joinPool = async (): JoinPoolTxResponse => {
    try {
      const hash = await client?.sendTransaction({
        account: client.account,
        data: call.call,
        to: call.to,
        value: call.value,
      });

      return hash;
    } catch (e) {
      console.error("error", e);
    }
  };

  return { queryJoin, joinPool };
};
