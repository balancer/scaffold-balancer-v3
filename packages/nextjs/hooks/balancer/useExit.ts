import { useState } from "react";
import {
  InputAmount,
  OnChainProvider,
  PoolState,
  RemoveLiquidity,
  RemoveLiquidityInput,
  RemoveLiquidityKind,
  Slippage,
} from "@balancer/sdk";
import { usePublicClient, useWalletClient } from "wagmi";
import { Pool, PoolActionTxUrl, QueryExitResponse } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

type PoolExitFunctions = {
  queryExit: (rawAmount: bigint) => Promise<QueryExitResponse>;
  exitPool: () => Promise<PoolActionTxUrl>;
};

/**
 * Custom hook for exiting a pool where `queryExit()` sets state of
 * the call object that is used to construct the transaction that is later sent by `exitPool()`
 */
export const useExit = (pool: Pool): PoolExitFunctions => {
  const [call, setCall] = useState<any>();

  const { data: walletClient } = useWalletClient();
  const publicClient = usePublicClient();
  const writeTx = useTransactor();

  const queryExit = async (rawAmount: bigint) => {
    try {
      const chainId = await publicClient.getChainId();
      const rpcUrl = publicClient?.chain.rpcUrls.default.http[0] as string;
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

      // Construct call object for exit transaction and save to state
      const call = removeLiquidity.buildCall({
        ...queryOutput,
        slippage,
        chainId,
        wethIsEth: false,
      });

      setCall(call);

      return { expectedAmountsOut: queryOutput.amountsOut, minAmountsOut: call.minAmountsOut };
    } catch (error) {
      const message = (error as { shortMessage?: string }).shortMessage || "An unknown error occurred";
      return { error: { message } };
    }
  };

  const exitPool = async () => {
    try {
      if (!walletClient) {
        throw new Error("Client is undefined");
      }
      const txHashPromise = () =>
        walletClient.sendTransaction({
          account: walletClient.account,
          data: call.callData,
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
      return null;
    }
  };

  return { queryExit, exitPool };
};
