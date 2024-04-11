import { useEffect, useState } from "react";
import { PoolActionsProps } from "./PoolActions";
import { SwapKind } from "@balancer/sdk";
import { formatUnits, parseUnits } from "viem";
import { PoolFeedback, TokenField } from "~~/app/pools/_components";
import { StyledQueryButton, StyledTxButton } from "~~/components/common";
import { useSwap } from "~~/hooks/balancer/";
import { useTransactor } from "~~/hooks/scaffold-eth";

export type SwapConfig = {
  tokenIn: {
    poolTokensIndex: number;
    amount: string;
  };
  tokenOut: {
    poolTokensIndex: number;
    amount: string;
  };
  swapKind: SwapKind;
};

type SwapQueryResponse = {
  expectedAmount: any;
  minOrMaxAmount: any;
  swapKind: SwapKind | undefined;
};

const initialQueryResponse = {
  expectedAmount: undefined,
  minOrMaxAmount: undefined,
  swapKind: undefined,
};

const initialSwapConfig = {
  tokenIn: {
    poolTokensIndex: 0,
    amount: "",
  },
  tokenOut: {
    poolTokensIndex: 1,
    amount: "",
  },
  swapKind: SwapKind.GivenOut,
};

/**
 * 1. Choose tokenIn and tokenOut
 * 2. Query the results of swap transaction
 * 3. User approves the vault for the tokenIn used in the swap transaction (if necessary)
 * 4. User sends transaction to swap the tokens
 *
 * @notice using poolTokensIndex to reference the token in the pool
 */
export const SwapTab: React.FC<PoolActionsProps> = ({ pool, refetchPool }) => {
  const [queryResponse, setQueryResponse] = useState<SwapQueryResponse>(initialQueryResponse);
  const [isTokenInDropdownOpen, setTokenInDropdownOpen] = useState(false);
  const [isTokenOutDropdownOpen, setTokenOutDropdownOpen] = useState(false);
  const [sufficientAllowance, setSufficientAllowance] = useState(false);
  const [swapTxUrl, setSwapTxUrl] = useState<string | undefined>();
  const [swapConfig, setSwapConfig] = useState<SwapConfig>(initialSwapConfig);
  const [isApproving, setIsApproving] = useState(false);
  const [isSwapping, setIsSwapping] = useState(false);

  const { querySwap, swap, tokenInAllowance, refetchTokenInAllowance, tokenInBalance, approveAsync } = useSwap(
    pool,
    swapConfig,
  );
  const writeTx = useTransactor();

  const tokenIn = pool.poolTokens[swapConfig.tokenIn.poolTokensIndex];
  const tokenOut = pool.poolTokens[swapConfig.tokenOut.poolTokensIndex];

  // Verify user has sufficient allowance to perform the swap
  useEffect(() => {
    const tokenInRawAmount = parseUnits(swapConfig.tokenIn.amount, tokenIn.decimals);
    if (tokenInAllowance && tokenInAllowance >= tokenInRawAmount) {
      setSufficientAllowance(true);
    } else {
      setSufficientAllowance(false);
    }
  }, [
    tokenInAllowance,
    swapConfig.tokenIn.amount,
    pool.poolTokens,
    swapConfig.tokenIn.poolTokensIndex,
    tokenIn.decimals,
  ]);

  const handleTokenAmountChange = (amount: string, swapConfigKey: "tokenIn" | "tokenOut") => {
    // Reset query response whenever input amount changes
    setQueryResponse(initialQueryResponse);
    // Update the focused input amount with new value and reset the other input amount
    setSwapConfig(prevConfig => ({
      tokenIn: {
        ...prevConfig.tokenIn,
        amount: swapConfigKey === "tokenIn" ? amount : "",
      },
      tokenOut: {
        ...prevConfig.tokenOut,
        amount: swapConfigKey === "tokenOut" ? amount : "",
      },
      swapKind: swapConfigKey === "tokenIn" ? SwapKind.GivenIn : SwapKind.GivenOut,
    }));
  };

  const handleTokenSelection = (selectedSymbol: string, swapConfigKey: "tokenIn" | "tokenOut") => {
    const selectedIndex = pool.poolTokens.findIndex(token => token.symbol === selectedSymbol);
    const otherIndex = pool.poolTokens.length === 2 ? (selectedIndex === 0 ? 1 : 0) : -1;

    setSwapConfig(prevConfig => ({
      ...prevConfig,
      [swapConfigKey]: {
        // Update the selected token with the new index and reset the amount
        poolTokensIndex: selectedIndex,
        amount: "",
      },
      // If there are only two tokens in pool, automatically set the other token
      ...(pool.poolTokens.length === 2 && {
        [swapConfigKey === "tokenIn" ? "tokenOut" : "tokenIn"]: {
          poolTokensIndex: otherIndex,
          amount: "",
        },
      }),
    }));

    setTokenInDropdownOpen(false);
    setTokenOutDropdownOpen(false);
    setQueryResponse(initialQueryResponse);
  };

  // Query the swap and update the expected and min/max amounts in/out
  const handleQuerySwap = async () => {
    const { updatedAmount, call } = await querySwap();

    if (updatedAmount.swapKind === SwapKind.GivenIn) {
      const rawExpectedAmountOut = updatedAmount.expectedAmountOut.amount;
      setQueryResponse({
        expectedAmount: updatedAmount.expectedAmountOut,
        minOrMaxAmount: call.minAmountOut,
        swapKind: SwapKind.GivenIn,
      });
      // Update the tokenOut amount with the expected amount
      setSwapConfig(prevConfig => ({
        ...prevConfig,
        tokenOut: {
          ...prevConfig.tokenOut,
          amount: Number(formatUnits(rawExpectedAmountOut, tokenOut.decimals)).toFixed(4),
        },
      }));
    } else {
      const rawExpectedAmountIn = updatedAmount.expectedAmountIn.amount;
      setQueryResponse({
        expectedAmount: updatedAmount.expectedAmountIn,
        minOrMaxAmount: call.maxAmountIn,
        swapKind: SwapKind.GivenOut,
      });
      // Update the tokenIn amount with the expected amount
      setSwapConfig(prevConfig => ({
        ...prevConfig,
        tokenIn: {
          ...prevConfig.tokenIn,
          amount: Number(formatUnits(rawExpectedAmountIn, tokenIn.decimals)).toFixed(4),
        },
      }));
    }
  };

  const handleApprove = async () => {
    try {
      setIsApproving(true);
      await writeTx(approveAsync, {
        blockConfirmations: 1,
        onBlockConfirmation: () => {
          refetchTokenInAllowance();
          setIsApproving(false);
        },
      });
    } catch (err) {
      console.error("error", err);
      setIsApproving(false);
    }
  };

  const handleSwap = async () => {
    try {
      setIsSwapping(true);
      const txHash = await swap();
      setSwapTxUrl(txHash);
      setSwapConfig(initialSwapConfig);
      refetchPool();
    } catch (e) {
      console.error("error", e);
    } finally {
      setIsSwapping(false);
    }
  };

  return (
    <section>
      <TokenField
        label="Token In"
        tokenSymbol={tokenIn.symbol}
        value={swapConfig.tokenIn.amount}
        onAmountChange={value => handleTokenAmountChange(value, "tokenIn")}
        onTokenSelect={symbol => handleTokenSelection(symbol, "tokenIn")}
        tokenDropdownOpen={isTokenInDropdownOpen}
        setTokenDropdownOpen={setTokenInDropdownOpen}
        selectableTokens={pool.poolTokens.filter(token => token.symbol !== tokenIn.symbol)}
        allowance={Number(formatUnits(tokenInAllowance ?? 0n, tokenIn.decimals)).toFixed(4)}
        balance={Number(formatUnits(tokenInBalance ?? 0n, tokenIn.decimals)).toFixed(4)}
        isHighlighted={queryResponse.swapKind === SwapKind.GivenIn}
      />
      <TokenField
        label="Token Out"
        tokenSymbol={tokenOut.symbol}
        value={swapConfig.tokenOut.amount}
        onAmountChange={value => handleTokenAmountChange(value, "tokenOut")}
        onTokenSelect={symbol => handleTokenSelection(symbol, "tokenOut")}
        tokenDropdownOpen={isTokenOutDropdownOpen}
        setTokenDropdownOpen={setTokenOutDropdownOpen}
        selectableTokens={pool.poolTokens.filter(token => token.symbol !== tokenOut.symbol)}
        isHighlighted={queryResponse.swapKind === SwapKind.GivenOut}
      />
      <div className={`z-100 grid gap-5 ${!queryResponse.expectedAmount || swapTxUrl ? "grid-cols-1" : "grid-cols-2"}`}>
        <div>
          <StyledQueryButton
            onClick={handleQuerySwap}
            isDisabled={swapConfig.tokenIn.amount === "" && swapConfig.tokenOut.amount === ""}
          >
            Query Swap
          </StyledQueryButton>
        </div>
        {!queryResponse.expectedAmount || swapTxUrl ? null : !sufficientAllowance ? (
          <div>
            <StyledTxButton isDisabled={isApproving} onClick={handleApprove}>
              Approve
            </StyledTxButton>
          </div>
        ) : (
          <div>
            <StyledTxButton isDisabled={isSwapping} onClick={handleSwap}>
              Send Swap
            </StyledTxButton>
          </div>
        )}
      </div>
      <PoolFeedback
        title={`Amount ${queryResponse.swapKind === SwapKind.GivenIn ? "Out" : "In"}`}
        transactionUrl={swapTxUrl}
      >
        <div className="flex flex-wrap justify-between mb-3">
          <div className="font-bold">Expected</div>
          <div className="text-end">
            <div className="font-bold">
              {queryResponse.expectedAmount
                ? Number(
                    formatUnits(queryResponse.expectedAmount.amount, queryResponse.expectedAmount.token.decimals),
                  ).toFixed(4)
                : "0.0000"}
            </div>
            <div className="text-sm">
              {queryResponse.expectedAmount ? queryResponse.expectedAmount.amount.toString() : "0"}
            </div>
          </div>
        </div>
        <div className="flex flex-wrap justify-between">
          <div className="font-bold">{queryResponse.swapKind === SwapKind.GivenIn ? "Minumum" : "Maximum"}</div>
          <div className="text-end">
            <div className="font-bold">
              {queryResponse.minOrMaxAmount
                ? Number(
                    formatUnits(queryResponse.minOrMaxAmount.amount, queryResponse.minOrMaxAmount.token.decimals),
                  ).toFixed(4)
                : "0.0000"}
            </div>
            <div className="text-sm">
              {queryResponse.minOrMaxAmount ? queryResponse.minOrMaxAmount.amount.toString() : "0"}
            </div>
          </div>
        </div>
      </PoolFeedback>
    </section>
  );
};
