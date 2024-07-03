import { useState } from "react";
import { Slippage, Swap, SwapBuildOutputExactIn, SwapBuildOutputExactOut, SwapKind, TokenAmount } from "@balancer/sdk";
import { useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { Pool, SwapConfig, UseSwap } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";

/**
 * Custom hook for swapping tokens in a pool where `querySwap()` sets state of
 * the call object that is used to construct the transaction that is then sent by `swap()`
 */
export const useSwap = (pool: Pool, swapConfig: SwapConfig): UseSwap => {
  const [call, setCall] = useState<SwapBuildOutputExactIn | SwapBuildOutputExactOut>();
  const { data: walletClient } = useWalletClient();
  const { rpcUrl, chainId } = useTargetFork();
  const writeTx = useTransactor();

  const tokenIn = pool.poolTokens[swapConfig.tokenIn.poolTokensIndex];
  const tokenOut = pool.poolTokens[swapConfig.tokenOut.poolTokensIndex];

  const querySwap = async () => {
    try {
      const swapInput = {
        chainId: chainId,
        swapKind: swapConfig.swapKind,
        paths: [
          {
            pools: [pool.address as `0x${string}`],
            tokens: [
              {
                address: tokenIn.address as `0x${string}`,
                decimals: tokenIn.decimals,
              }, // tokenIn
              {
                address: tokenOut.address as `0x${string}`,
                decimals: tokenOut.decimals,
              }, // tokenOut
            ],
            vaultVersion: 3 as const,
            inputAmountRaw: swapConfig.tokenIn.rawAmount,
            outputAmountRaw: swapConfig.tokenOut.rawAmount,
          },
        ],
      };

      const swap = new Swap(swapInput);
      const updatedAmount = await swap.query(rpcUrl);

      const call = swap.buildCall({
        slippage: Slippage.fromPercentage("0.1"),
        deadline: 999999999999999999n, // Deadline for the swap, in this case infinite
        queryOutput: updatedAmount,
        wethIsEth: false,
      });

      setCall(call);

      let expectedAmount: TokenAmount;
      let minOrMaxAmount: TokenAmount;
      const swapKind = updatedAmount.swapKind;

      if (swapKind === SwapKind.GivenIn && "minAmountOut" in call) {
        expectedAmount = updatedAmount.expectedAmountOut;
        minOrMaxAmount = call.minAmountOut;
      } else if (updatedAmount.swapKind === SwapKind.GivenOut && "maxAmountIn" in call) {
        expectedAmount = updatedAmount.expectedAmountIn;
        minOrMaxAmount = call.maxAmountIn;
      } else {
        throw new Error("Invalid swapKind or call object");
      }

      return {
        swapKind,
        expectedAmount,
        minOrMaxAmount,
      };
    } catch (error) {
      console.error("error", error);
      const message = (error as { shortMessage?: string }).shortMessage || "An unknown error occurred";
      return { error: { message } };
    }
  };

  /**
   * Execute the swap tx and return the block explorer URL
   */
  const swap = async () => {
    try {
      if (!walletClient) {
        throw new Error("Must connect a wallet to send a transaction");
      }
      if (!call) {
        throw new Error("tx call object is undefined");
      }
      const txHashPromise = () =>
        walletClient.sendTransaction({
          account: walletClient.account,
          data: call.callData,
          to: call.to,
          value: call.value,
        });
      const txHash = await writeTx(txHashPromise, { blockConfirmations: 1 });
      if (!txHash) {
        throw new Error("Transaction failed");
      }

      return txHash;
    } catch (e) {
      console.error("error", e);
      return null;
    }
  };

  return {
    querySwap,
    swap,
  };
};
