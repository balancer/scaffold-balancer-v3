import { Dispatch, SetStateAction } from "react";
import { Swap, SwapInput, SwapKind } from "@balancer/sdk";
import { useQuery } from "@tanstack/react-query";
import { SwapConfig, useTargetFork } from "~~/hooks/balancer";
import { formatToHuman } from "~~/utils";

export const useQuerySwap = (swapInput: SwapInput, setSwapConfig: Dispatch<SetStateAction<SwapConfig>>) => {
  const { rpcUrl } = useTargetFork();

  const querySwap = async () => {
    const swap = new Swap(swapInput);
    const queryOutput = await swap.query(rpcUrl);

    // Update the swap inputs UI with the expected amount
    if (queryOutput.swapKind === SwapKind.GivenIn) {
      const rawAmountExpected = queryOutput.expectedAmountOut.amount;
      const decimals = queryOutput.expectedAmountOut.token.decimals;
      setSwapConfig(prevConfig => ({
        ...prevConfig,
        tokenOut: {
          ...prevConfig.tokenOut,
          amount: formatToHuman(rawAmountExpected, decimals),
          rawAmount: rawAmountExpected,
        },
      }));
    } else {
      const rawAmountExpected = queryOutput.expectedAmountIn.amount;
      const decimals = queryOutput.expectedAmountIn.token.decimals;
      setSwapConfig(prevConfig => ({
        ...prevConfig,
        tokenIn: {
          ...prevConfig.tokenIn,
          amount: formatToHuman(rawAmountExpected, decimals),
          rawAmount: rawAmountExpected,
        },
      }));
    }

    return queryOutput;
  };

  return useQuery({
    queryKey: ["querySwap"],
    queryFn: querySwap,
    enabled: false,
  });
};
