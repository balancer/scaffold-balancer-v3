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
import { useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { Pool, QueryRemoveLiquidityResponse, TransactionHash } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

type RemoveLiquidityFunctions = {
  queryRemoveLiquidity: (rawAmount: bigint) => Promise<QueryRemoveLiquidityResponse>;
  removeLiquidity: () => Promise<TransactionHash>;
};

/**
 * Custom hook for removing liquidity from a pool where `queryRemoveLiquidity()` sets state of
 * the call object that is used to construct the transaction that is later sent by `removeLiquidity()`
 */
export const useRemoveLiquidity = (pool: Pool): RemoveLiquidityFunctions => {
  const [call, setCall] = useState<any>();
  const { data: walletClient } = useWalletClient();
  const { rpcUrl, chainId } = useTargetFork();
  const writeTx = useTransactor();

  const queryRemoveLiquidity = async (rawAmount: bigint) => {
    try {
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
      setCall(call); // save to state for use in removeLiquidity()

      return { expectedAmountsOut: queryOutput.amountsOut, minAmountsOut: call.minAmountsOut };
    } catch (error) {
      const message = (error as { shortMessage?: string }).shortMessage || "An unknown error occurred";
      return { error: { message } };
    }
  };

  const removeLiquidity = async () => {
    try {
      if (!walletClient) {
        throw new Error("Must connect a wallet to send a transaction");
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

  return { queryRemoveLiquidity, removeLiquidity };
};
