import { useState } from "react";
import {
  BalancerApi, // ChainId,
  InputAmount,
  PoolState,
  RemoveLiquidity,
  RemoveLiquidityInput,
  RemoveLiquidityKind,
  Slippage,
} from "@balancer/sdk";
import { parseAbi } from "viem";
import { useContractRead, usePublicClient, useWalletClient } from "wagmi";
import { type Pool } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

/**
 * Custom hook for exiting a pool where queryExit sets state of
 * the call object that is used to construct the transaction
 */
export const useExit = (pool: Pool) => {
  const [call, setCall] = useState<any>();

  const { data: walletClient } = useWalletClient();
  const publicClient = usePublicClient();
  const writeTx = useTransactor();

  const queryExit = async (rawAmount: bigint) => {
    const chainId = await publicClient.getChainId();
    const rpcUrl = publicClient?.chain.rpcUrls.default.http[0] as string;
    const slippage = Slippage.fromPercentage("1"); // 1%

    // Fetch relevant pool data for removeLiquidity.query
    const balancerApi = new BalancerApi("https://backend-v3-canary.beets-ftm-node.com/graphql", chainId);
    const poolState: PoolState = await balancerApi.pools.fetchPoolState(pool.address.toLowerCase());

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

    // Construct call object for exit transaction and save to state
    const call = removeLiquidity.buildCall({
      ...queryOutput,
      slippage,
      chainId,
      wethIsEth: false,
    });
    setCall(call);

    return { expectedAmountsOut: queryOutput.amountsOut, minAmountsOut: call.minAmountsOut };
  };

  const exitPool = async () => {
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
    } catch (error) {
      console.error("error", error);
    }
  };

  const { data: userPoolBalance } = useContractRead({
    address: pool.address,
    abi: parseAbi(["function balanceOf(address owner) returns (uint256)"]),
    functionName: "balanceOf" as any, // must type any because of parseAbi ???
    args: [walletClient?.account?.address as string],
  });

  return { userPoolBalance, queryExit, exitPool };
};
