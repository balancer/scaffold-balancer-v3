import { useState } from "react";
import {
  // ChainId,
  ExactInQueryOutput,
  Slippage,
  Swap,
  SwapBuildOutputExactIn,
  SwapKind,
} from "@balancer/sdk";
import { Address } from "viem";
import { useWalletClient } from "wagmi";

type QuerySwapResponse = Promise<any>;

type SwapTxResponse = Promise<string | undefined>;

type SwapFunctions = {
  querySwap: (pool: Address, tokenIn: any, tokenOut: any) => QuerySwapResponse;
  swap: () => SwapTxResponse;
};

/**
 * Custom hook for swapping tokens in a pool
 *
 * querySwap: returns updated output amount
 * swap: sends the swap transaction using the call data generated by `querySwap`
 */
export const useSwap = (): SwapFunctions => {
  const [call, setCall] = useState<any>();

  const { data: client } = useWalletClient();

  /**
   * @param pool the address of pool
   * @param tokenIn the token to sell
   * @param tokenOut the token to buy
   */
  const querySwap = async (pool: Address, tokenIn: any, tokenOut: any): QuerySwapResponse => {
    // User defined
    const chainId = client?.chain.id as number;
    const rpcUrl = client?.chain.rpcUrls.default.http[0] as string;

    const swapInput = {
      chainId: chainId,
      swapKind: SwapKind.GivenIn,
      paths: [
        {
          pools: [pool as `0x${string}`],
          tokens: [
            { address: tokenIn.address, decimals: tokenIn.decimals },
            { address: tokenOut.address, decimals: tokenOut.decimals },
          ],
          vaultVersion: 3 as const,
          inputAmountRaw: tokenIn.amountRaw,
          outputAmountRaw: tokenOut.amountRaw,
        },
      ],
    };

    const swap = new Swap(swapInput);

    // Get up to date swap result by querying onchain
    const updatedOutputAmount = (await swap.query(rpcUrl)) as ExactInQueryOutput;
    console.log(`Updated amount: ${updatedOutputAmount.expectedAmountOut}`);

    // Build call data using user defined slippage
    const callData = swap.buildCall({
      slippage: Slippage.fromPercentage("0.1"), // 0.1%,
      deadline: 999999999999999999n, // Deadline for the swap, in this case infinite
      queryOutput: updatedOutputAmount,
      wethIsEth: false,
    }) as SwapBuildOutputExactIn;

    setCall(callData);

    console.log(
      `Min Amount Out: ${callData.minAmountOut.amount}\n\nTx Data:\nTo: ${callData.to}\nCallData: ${callData.callData}\nValue: ${callData.value}`,
    );

    return { updatedOutputAmount };
  };

  /**
   * @param call the call object from Balancer SDK used to construct the transaction
   */
  const swap = async (): SwapTxResponse => {
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

  return { querySwap, swap };
};
