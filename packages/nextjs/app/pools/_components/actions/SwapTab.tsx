import { useEffect, useState } from "react";
import { PoolActionsProps } from "../PoolActions";
import { ActionSuccessAlert, PoolActionButton, QueryErrorAlert, QueryResultsWrapper, TokenField } from "./";
import { SwapKind, TokenAmount } from "@balancer/sdk";
import { formatUnits, parseUnits } from "viem";
import { useSwap } from "~~/hooks/balancer/";
import { useTransactor } from "~~/hooks/scaffold-eth";

export type SwapConfig = {
  tokenIn: {
    poolTokensIndex: number;
    amount: string;
    rawAmount: bigint;
  };
  tokenOut: {
    poolTokensIndex: number;
    amount: string;
    rawAmount: bigint;
  };
  swapKind: SwapKind;
};

type SwapQueryResponse = {
  expectedAmount: TokenAmount | undefined;
  minOrMaxAmount: TokenAmount | undefined;
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
  const [isQuerying, setIsQuerying] = useState(false);
  const [queryErrorMsg, setQueryErrorMsg] = useState<string | null>();

  const { querySwap, swap, tokenInAllowance, refetchTokenInAllowance, tokenInBalance, approveAsync } = useSwap(
    pool,
    swapConfig,
  );
  const writeTx = useTransactor();

  const tokenIn = pool.poolTokens[swapConfig.tokenIn.poolTokensIndex];
  const tokenOut = pool.poolTokens[swapConfig.tokenOut.poolTokensIndex];

  // Verify user has sufficient allowance to perform the swap
  useEffect(() => {
    if (tokenInAllowance && tokenInAllowance >= swapConfig.tokenIn.rawAmount) {
      setSufficientAllowance(true);
    } else {
      setSufficientAllowance(false);
    }
  }, [tokenInAllowance, swapConfig.tokenIn.rawAmount, pool.poolTokens, swapConfig.tokenIn.poolTokensIndex]);

  const handleTokenAmountChange = (amount: string, swapConfigKey: "tokenIn" | "tokenOut") => {
    // Clean up UI to prepare for new query
    setQueryResponse(initialQueryResponse);
    setSwapTxUrl(undefined);
    setQueryErrorMsg(null);
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

  const handleTokenSelection = (selectedSymbol: string, swapConfigKey: "tokenIn" | "tokenOut") => {
    // Clean up UI to prepare for new query
    setQueryResponse(initialQueryResponse);
    setSwapTxUrl(undefined);
    setQueryErrorMsg(null);

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

  const handleQuerySwap = async () => {
    setIsQuerying(true);
    const response = await querySwap();
    if (response.error) {
      setQueryErrorMsg(response.error.message);
    } else {
      const { swapKind, expectedAmount, minOrMaxAmount } = response;

      setQueryResponse({
        expectedAmount,
        minOrMaxAmount,
        swapKind,
      });

      // update the unfilled token input field appropriately
      const rawExpectedAmount = expectedAmount?.amount ?? 0n;
      if (swapKind === SwapKind.GivenIn) {
        setSwapConfig(prevConfig => ({
          ...prevConfig,
          tokenOut: {
            ...prevConfig.tokenOut,
            amount: Number(formatUnits(rawExpectedAmount, tokenOut.decimals)).toFixed(4),
            rawAmount: rawExpectedAmount,
          },
        }));
      } else {
        setSwapConfig(prevConfig => ({
          ...prevConfig,
          tokenIn: {
            ...prevConfig.tokenIn,
            amount: Number(formatUnits(rawExpectedAmount, tokenIn.decimals)).toFixed(4),
            rawAmount: rawExpectedAmount,
          },
        }));
      }
    }
    setIsQuerying(false);
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
      refetchPool();
      refetchTokenInAllowance();
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

      {swapTxUrl ? (
        <ActionSuccessAlert transactionUrl={swapTxUrl} />
      ) : !queryResponse.expectedAmount ? (
        <PoolActionButton
          onClick={handleQuerySwap}
          isDisabled={isQuerying}
          isFormEmpty={swapConfig.tokenIn.amount === "" && swapConfig.tokenOut.amount === ""}
        >
          Query
        </PoolActionButton>
      ) : !sufficientAllowance ? (
        <PoolActionButton isDisabled={isApproving} onClick={handleApprove}>
          Approve
        </PoolActionButton>
      ) : (
        <PoolActionButton isDisabled={isSwapping} onClick={handleSwap}>
          Swap
        </PoolActionButton>
      )}

      {queryResponse.expectedAmount && queryResponse.minOrMaxAmount && (
        <QueryResultsWrapper title={`Amount ${queryResponse.swapKind === SwapKind.GivenIn ? "Out" : "In"}`}>
          <div className="flex flex-wrap justify-between mb-3">
            <div className="font-bold">Expected</div>
            <div className="text-end">
              <div className="font-bold">
                {Number(
                  formatUnits(queryResponse.expectedAmount.amount, queryResponse.expectedAmount.token.decimals),
                ).toFixed(4)}
              </div>
              <div className="text-sm">{queryResponse.expectedAmount.amount.toString()}</div>
            </div>
          </div>
          <div className="flex flex-wrap justify-between">
            <div className="font-bold">{queryResponse.swapKind === SwapKind.GivenIn ? "Minumum" : "Maximum"}</div>
            <div className="text-end">
              <div className="font-bold">
                {Number(
                  formatUnits(queryResponse.minOrMaxAmount.amount, queryResponse.minOrMaxAmount.token.decimals),
                ).toFixed(4)}
              </div>
              <div className="text-sm">{queryResponse.minOrMaxAmount.amount.toString()}</div>
            </div>
          </div>
        </QueryResultsWrapper>
      )}

      {queryErrorMsg && <QueryErrorAlert message={queryErrorMsg} />}
    </section>
  );
};
