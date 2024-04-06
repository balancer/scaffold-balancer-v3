import { useState } from "react";
import {
  AddLiquidity,
  AddLiquidityInput,
  AddLiquidityKind,
  BalancerApi, //   ChainId,
  InputAmount,
  Slippage,
} from "@balancer/sdk";
import { usePublicClient, useWalletClient } from "wagmi";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

type QueryJoinResponse = Promise<any>;

type JoinPoolTxResponse = Promise<string | undefined>;

type JoinPoolFunctions = {
  queryJoin: (pool: string, amountsIn: InputAmount[]) => QueryJoinResponse;
  joinPool: () => JoinPoolTxResponse;
};

/**
 * Custom hook for adding liquidity to pools
 *
 * queryJoin: Queries the expected and minimum BPT out amount for a given pool and token amounts.
 * joinPool: Sends the join transaction using the call data generated by `queryJoin`
 */
export const useJoin = (): JoinPoolFunctions => {
  const [call, setCall] = useState<any>();

  const { data: walletClient } = useWalletClient();
  const publicClient = usePublicClient();
  const writeTx = useTransactor();

  /**
   * @param pool the address of pool
   * @param amountsIn the amounts of tokens
   * @returns An object containing the expected and minimum BPT out amount.
   */
  const queryJoin = async (pool: string, amountsIn: InputAmount[]): QueryJoinResponse => {
    try {
      // User defined (along with the queryJoin parameters)
      const chainId = await publicClient.getChainId();
      const rpcUrl = publicClient?.chain.rpcUrls.default.http[0] as string;
      const slippage = Slippage.fromPercentage("1"); // 1%

      // API used to fetch relevant pool data for addLiquidity.query
      const balancerApi = new BalancerApi("https://backend-v3-canary.beets-ftm-node.com/graphql", chainId);
      const poolState = await balancerApi.pools.fetchPoolState(pool.toLowerCase());

      // Construct the addLiquidity input object
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
      if (!walletClient) {
        throw new Error("Client is undefined");
      }

      const txHashPromise = () =>
        walletClient.sendTransaction({
          account: walletClient.account,
          data: call.call,
          to: call.to,
          value: call.value,
        });

      const hash = await writeTx(txHashPromise, { blockConfirmations: 1 });

      if (!hash) {
        throw new Error("Transaction failed");
      }

      const chainId = await walletClient.getChainId();
      const blockExplorerTxURL = getBlockExplorerTxLink(chainId, hash);
      return blockExplorerTxURL;
    } catch (e) {
      console.error("error", e);
    }
  };

  return { queryJoin, joinPool };
};
