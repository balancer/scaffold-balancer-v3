import { useMemo, useState } from "react";
import { PoolActionButton, ResultsDisplay, TokenField } from ".";
import { PERMIT2, SwapKind, VAULT_V3, vaultV3Abi } from "@balancer/sdk";
import { useQueryClient } from "@tanstack/react-query";
import { parseUnits } from "viem";
import { useContractEvent } from "wagmi";
import { Alert } from "~~/components/common";
import {
  PoolActionsProps,
  PoolOperationReceipt,
  SwapConfig,
  useQuerySwap,
  useSwap,
  useTargetFork,
} from "~~/hooks/balancer/";
import {
  useAllowanceOnPermit2,
  useAllowanceOnToken,
  useApproveOnPermit2,
  useApproveOnToken,
} from "~~/hooks/balancer/token";

const initialSwapConfig = {
  tokenIn: {
    poolTokensIndex: 0,
    amount: "",
    rawAmount: 0n,
  },
  tokenOut: {
    poolTokensIndex: 1,
    amount: "",
    rawAmount: 0n,
  },
  swapKind: SwapKind.GivenOut,
};

/**
 * 1. Choose tokenIn and tokenOut
 * 2. Query swapping some amount of tokens in the pool
 * 3. Approve the vault for the tokenIn used in the swap transaction (if necessary)
 * 4. Send transaction to swap the tokens
 */
export const SwapForm: React.FC<PoolActionsProps> = ({ pool, refetchPool, tokenBalances, refetchTokenBalances }) => {
  const [swapConfig, setSwapConfig] = useState<SwapConfig>(initialSwapConfig);
  const [swapReceipt, setSwapReceipt] = useState<PoolOperationReceipt>(null);

  const { chainId } = useTargetFork();
  const queryClient = useQueryClient();

  const tokenIn = pool.poolTokens[swapConfig.tokenIn.poolTokensIndex];
  const tokenOut = pool.poolTokens[swapConfig.tokenOut.poolTokensIndex];

  const swapInput = {
    chainId,
    swapKind: swapConfig.swapKind,
    paths: [
      {
        pools: [pool.address as `0x${string}`],
        tokens: [
          { address: tokenIn.address as `0x${string}`, decimals: tokenIn.decimals }, // tokenIn
          { address: tokenOut.address as `0x${string}`, decimals: tokenOut.decimals }, // tokenOut
        ],
        protocolVersion: 3 as const,
        inputAmountRaw: swapConfig.tokenIn.rawAmount,
        outputAmountRaw: swapConfig.tokenOut.rawAmount,
      },
    ],
  };

  const {
    data: queryResponse,
    isFetching: isQueryFetching,
    error: queryError,
    refetch: refetchQuerySwap,
  } = useQuerySwap(swapInput, setSwapConfig);
  const { data: allowanceOnPermit2, refetch: refetchAllowanceOnPermit2 } = useAllowanceOnPermit2(tokenIn.address);
  const { data: allowanceOnToken, refetch: refetchAllowanceOnToken } = useAllowanceOnToken(
    tokenIn.address,
    PERMIT2[chainId],
  );
  const {
    mutateAsync: approveRouter,
    isLoading: isApproveRouterPending,
    error: approveRouterError,
  } = useApproveOnToken(tokenIn.address, PERMIT2[chainId]);
  const {
    mutateAsync: approvePermit2,
    isLoading: isApprovePermit2Pending,
    error: approvePermit2Error,
  } = useApproveOnPermit2(tokenIn.address);
  const { mutate: swap, isLoading: isSwapPending, error: swapError } = useSwap(swapInput);

  const handleQuerySwap = async () => {
    queryClient.removeQueries(["querySwap"]);
    setSwapReceipt(null);
    refetchQuerySwap();
  };

  const handleApprove = async () => {
    if (allowanceOnPermit2 && allowanceOnPermit2[0] < swapConfig.tokenIn.rawAmount) {
      if (allowanceOnToken !== undefined && allowanceOnToken < swapConfig.tokenIn.rawAmount) {
        await approveRouter();
        refetchAllowanceOnToken();
      }
      await approvePermit2();
      refetchAllowanceOnPermit2();
    }
  };

  const handleSwap = async () => {
    swap(queryResponse, {
      onSuccess: () => {
        refetchPool();
        refetchTokenBalances();
      },
    });
  };

  const handleTokenAmountChange = (amount: string, swapConfigKey: "tokenIn" | "tokenOut") => {
    // Clear previous results when the amount changes
    queryClient.removeQueries(["querySwap"]);
    setSwapReceipt(null);
    // Update the focused input amount with new value and reset the other input amount
    setSwapConfig(prevConfig => ({
      tokenIn: {
        ...prevConfig.tokenIn,
        amount: swapConfigKey === "tokenIn" ? amount : "",
        rawAmount: swapConfigKey === "tokenIn" ? parseUnits(amount, tokenIn.decimals) : 0n,
      },
      tokenOut: {
        ...prevConfig.tokenOut,
        amount: swapConfigKey === "tokenOut" ? amount : "",
        rawAmount: swapConfigKey === "tokenOut" ? parseUnits(amount, tokenOut.decimals) : 0n,
      },
      swapKind: swapConfigKey === "tokenIn" ? SwapKind.GivenIn : SwapKind.GivenOut,
    }));
  };

  const sufficientAllowance = useMemo(() => {
    return allowanceOnPermit2 && allowanceOnPermit2[0] >= swapConfig.tokenIn.rawAmount;
  }, [allowanceOnPermit2, swapConfig.tokenIn.rawAmount]);

  useContractEvent({
    address: VAULT_V3[chainId],
    abi: vaultV3Abi,
    eventName: "Swap",
    listener(log: any[]) {
      const data = [
        {
          decimals: tokenOut.decimals,
          rawAmount: log[0].args.amountOut,
          symbol: tokenOut.symbol,
          name: tokenOut.name,
        },
        {
          decimals: tokenIn.decimals,
          rawAmount: log[0].args.amountIn,
          symbol: tokenIn.symbol,
          name: tokenIn.name,
        },
      ];

      setSwapReceipt({ data, transactionHash: log[0].transactionHash });
    },
  });

  const isFormEmpty = swapConfig.tokenIn.amount === "" && swapConfig.tokenOut.amount === "";
  const error = queryError || swapError || approveRouterError || approvePermit2Error;

  return (
    <section className="flex flex-col gap-5">
      <TokenField
        label="Token In"
        token={tokenIn}
        pool={pool}
        userBalance={tokenBalances[tokenIn.address]}
        value={swapConfig.tokenIn.amount}
        onAmountChange={value => handleTokenAmountChange(value, "tokenIn")}
        setSwapConfig={setSwapConfig}
        selectableTokens={pool.poolTokens.filter(token => token.symbol !== tokenIn.symbol)}
        isHighlighted={queryResponse?.swapKind === SwapKind.GivenIn}
      />
      <TokenField
        label="Token Out"
        token={tokenOut}
        pool={pool}
        userBalance={tokenBalances[tokenOut.address]}
        value={swapConfig.tokenOut.amount}
        onAmountChange={value => handleTokenAmountChange(value, "tokenOut")}
        setSwapConfig={setSwapConfig}
        selectableTokens={pool.poolTokens.filter(token => token.symbol !== tokenOut.symbol)}
        isHighlighted={queryResponse?.swapKind === SwapKind.GivenOut}
      />

      {!queryResponse || isFormEmpty || swapReceipt ? (
        <PoolActionButton
          label="Query"
          onClick={handleQuerySwap}
          isDisabled={isQueryFetching}
          isFormEmpty={isFormEmpty}
        />
      ) : !sufficientAllowance ? (
        <PoolActionButton
          label="Approve"
          isDisabled={isApprovePermit2Pending || isApproveRouterPending}
          onClick={handleApprove}
        />
      ) : (
        <PoolActionButton label="Swap" isDisabled={isSwapPending} onClick={handleSwap} />
      )}

      {(error as Error) && <Alert type="error">{(error as Error).message} / </Alert>}

      {queryResponse && (
        <ResultsDisplay
          label={`Expected Amount ${queryResponse?.swapKind === SwapKind.GivenIn ? "Out" : "In"}`}
          data={[
            {
              symbol: queryResponse?.swapKind === SwapKind.GivenIn ? tokenOut.symbol : tokenIn.symbol,
              name: queryResponse?.swapKind === SwapKind.GivenIn ? tokenOut.name : tokenIn.name,
              decimals: queryResponse?.swapKind === SwapKind.GivenIn ? tokenOut.decimals : tokenIn.decimals,
              rawAmount:
                queryResponse?.swapKind === SwapKind.GivenIn
                  ? queryResponse.expectedAmountOut.amount
                  : queryResponse.expectedAmountIn.amount,
            },
          ]}
        />
      )}

      {swapReceipt && (
        <ResultsDisplay
          label={`Actual Amount ${swapConfig.swapKind === SwapKind.GivenIn ? "Out" : "In"}`}
          transactionHash={swapReceipt.transactionHash}
          data={swapConfig.swapKind === SwapKind.GivenIn ? [swapReceipt.data[0]] : [swapReceipt.data[1]]}
        />
      )}
    </section>
  );
};
