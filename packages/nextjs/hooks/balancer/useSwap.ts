import { useState } from "react";
import {
  ExactInQueryOutput,
  ExactOutQueryOutput,
  Slippage,
  Swap,
  SwapBuildOutputExactIn,
  SwapBuildOutputExactOut,
  SwapKind,
  TokenAmount,
} from "@balancer/sdk";
import { WriteContractResult } from "@wagmi/core";
import { parseAbi } from "viem";
import { useContractRead, useContractWrite, useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { Pool, QuerySwapResponse, SwapConfig, TransactionHash } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";

type PoolSwapFunctions = {
  querySwap: () => Promise<QuerySwapResponse>;
  swap: () => Promise<TransactionHash>;
  tokenInAllowance: bigint | undefined;
  tokenInBalance: bigint | undefined;
  refetchTokenInAllowance: () => void;
  refetchTokenInBalance: () => void;
  approveAsync: () => Promise<WriteContractResult>;
};

/**
 * Custom hook for swapping tokens in a pool where `querySwap()` sets state of
 * the call object that is used to construct the transaction that is then sent by `swap()`
 */
export const useSwap = (pool: Pool, swapConfig: SwapConfig): PoolSwapFunctions => {
  const [call, setCall] = useState<any>();
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
      const updatedAmount = (await swap.query(rpcUrl)) as ExactInQueryOutput | ExactOutQueryOutput;

      const call = swap.buildCall({
        slippage: Slippage.fromPercentage("0.1"),
        deadline: 999999999999999999n, // Deadline for the swap, in this case infinite
        queryOutput: updatedAmount,
        wethIsEth: false,
      }) as SwapBuildOutputExactIn | SwapBuildOutputExactOut;

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

  const { data: tokenInAllowance, refetch: refetchTokenInAllowance } = useContractRead({
    address: tokenIn.address,
    abi: parseAbi(["function allowance(address owner, address spender) returns (uint256)"]),
    functionName: "allowance" as any, // ???
    args: [
      (walletClient?.account.address as `0x${string}`) || "0x0000000000000000000000000000000000000000",
      pool.vaultAddress,
    ],
  });

  const { data: tokenInBalance, refetch: refetchTokenInBalance } = useContractRead({
    address: tokenIn.address,
    abi: parseAbi(["function balanceOf(address owner) returns (uint256)"]),
    functionName: "balanceOf" as any, // ???
    args: [(walletClient?.account.address as `0x${string}`) || "0x0000000000000000000000000000000000000000"],
  });

  const { writeAsync: approveAsync } = useContractWrite({
    address: tokenIn.address,
    abi: parseAbi(["function approve(address spender, uint256 amount) returns (bool)"]),
    functionName: "approve",
    args: [pool.vaultAddress, swapConfig.tokenIn.rawAmount],
  });

  return {
    querySwap,
    swap,
    tokenInBalance,
    tokenInAllowance,
    refetchTokenInAllowance,
    refetchTokenInBalance,
    approveAsync,
  };
};
