import { useState } from "react";
import {
  BALANCER_ROUTER,
  PERMIT2,
  Slippage,
  Swap,
  SwapBuildOutputExactIn,
  SwapBuildOutputExactOut,
  SwapKind,
  TokenAmount,
  erc20Abi,
  permit2Abi,
} from "@balancer/sdk";
import { WriteContractResult } from "@wagmi/core";
import { zeroAddress } from "viem";
import { useContractRead, useContractWrite, useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { Pool, QuerySwapResponse, SwapConfig, TransactionHash } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { MaxUint48, MaxUint160, MaxUint256 } from "~~/utils/constants";

type PoolSwapFunctions = {
  querySwap: () => Promise<QuerySwapResponse>;
  swap: () => Promise<TransactionHash>;
  tokenInAllowance: bigint;
  tokenInBalance: bigint;
  refetchTokenInAllowance: () => void;
  refetchTokenInBalance: () => void;
  approveSpenderOnToken: () => Promise<WriteContractResult>;
  approveSpenderOnPermit2: () => Promise<WriteContractResult>;
};

/**
 * Custom hook for swapping tokens in a pool where `querySwap()` sets state of
 * the call object that is used to construct the transaction that is then sent by `swap()`
 */
export const useSwap = (pool: Pool, swapConfig: SwapConfig): PoolSwapFunctions => {
  const [call, setCall] = useState<SwapBuildOutputExactIn | SwapBuildOutputExactOut>();
  const { data: walletClient } = useWalletClient();
  const connectedAddress = walletClient?.account.address;
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

  const { data: tokenInAllowance, refetch: refetchTokenInAllowance } = useContractRead({
    address: PERMIT2[chainId],
    abi: permit2Abi,
    functionName: "allowance",
    args: [connectedAddress || zeroAddress, tokenIn.address, BALANCER_ROUTER[chainId]],
  });

  const { data: tokenInBalance, refetch: refetchTokenInBalance } = useContractRead({
    address: tokenIn.address,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: [connectedAddress || zeroAddress],
  });

  // Max approve canonical Permit2 address to spend account's tokens
  const { writeAsync: approveSpenderOnToken } = useContractWrite({
    address: tokenIn.address,
    abi: erc20Abi,
    functionName: "approve",
    args: [PERMIT2[chainId], MaxUint256], // point this approval at permit2 contract
  });

  // Approve Router to spend account's tokens using Permit2
  const { writeAsync: approveSpenderOnPermit2 } = useContractWrite({
    address: PERMIT2[chainId],
    abi: permit2Abi,
    functionName: "approve",
    args: [tokenIn.address, BALANCER_ROUTER[chainId], MaxUint160, MaxUint48],
  });

  return {
    querySwap,
    swap,
    tokenInBalance: tokenInBalance ? tokenInBalance : 0n,
    tokenInAllowance: tokenInAllowance ? tokenInAllowance[0] : 0n,
    refetchTokenInAllowance,
    refetchTokenInBalance,
    approveSpenderOnToken,
    approveSpenderOnPermit2,
  };
};
