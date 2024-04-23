import { useMemo, useState } from "react";
import { ActionSuccessAlert, PoolActionButton, QueryErrorAlert, QueryResultsWrapper, TokenField } from ".";
import { PoolActionsProps } from "../PoolActions";
import { SwapKind } from "@balancer/sdk";
import { parseUnits } from "viem";
import { useSwap } from "~~/hooks/balancer/";
import { PoolActionTxUrl, QueryPoolActionError, QuerySwapResponse, SwapConfig } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { formatToHuman } from "~~/utils/formatToHuman";

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
 * @notice using poolTokensIndex to reference the token in the pool
 */
export const SwapForm: React.FC<PoolActionsProps> = ({ pool, refetchPool }) => {
  const [queryResponse, setQueryResponse] = useState<QuerySwapResponse | null>(null);
  const [queryError, setQueryError] = useState<QueryPoolActionError>(null);
  const [swapConfig, setSwapConfig] = useState<SwapConfig>(initialSwapConfig);
  const [isTokenOutDropdownOpen, setTokenOutDropdownOpen] = useState(false);
  const [isTokenInDropdownOpen, setTokenInDropdownOpen] = useState(false);
  const [swapTxUrl, setSwapTxUrl] = useState<PoolActionTxUrl>(null);
  const [isApproving, setIsApproving] = useState(false);
  const [isSwapping, setIsSwapping] = useState(false);
  const [isQuerying, setIsQuerying] = useState(false);

  const { querySwap, swap, tokenInAllowance, refetchTokenInAllowance, tokenInBalance, approveAsync } = useSwap(
    pool,
    swapConfig,
  );
  const writeTx = useTransactor();

  const tokenIn = pool.poolTokens[swapConfig.tokenIn.poolTokensIndex];
  const tokenOut = pool.poolTokens[swapConfig.tokenOut.poolTokensIndex];

  const sufficientAllowance = useMemo(() => {
    return tokenInAllowance && tokenInAllowance >= swapConfig.tokenIn.rawAmount;
  }, [tokenInAllowance, swapConfig.tokenIn.rawAmount]);

  const handleTokenAmountChange = (amount: string, swapConfigKey: "tokenIn" | "tokenOut") => {
    // Clean up UI to prepare for new query
    setQueryResponse(null);
    setSwapTxUrl(null);
    setQueryError(null);
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
    setQueryResponse(null);
    setSwapTxUrl(null);
    setQueryError(null);

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
    setQueryResponse(null);
  };

  const handleQuerySwap = async () => {
    setIsQuerying(true);
    const response = await querySwap();
    if (response.error) {
      setQueryError(response.error);
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
            amount: formatToHuman(rawExpectedAmount, tokenOut.decimals),
            rawAmount: rawExpectedAmount,
          },
        }));
      } else {
        setSwapConfig(prevConfig => ({
          ...prevConfig,
          tokenIn: {
            ...prevConfig.tokenIn,
            amount: formatToHuman(rawExpectedAmount, tokenIn.decimals),
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

  const { expectedAmount, minOrMaxAmount } = queryResponse ?? {};

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
        allowance={formatToHuman(tokenInAllowance ?? 0n, tokenIn.decimals)}
        balance={formatToHuman(tokenInBalance ?? 0n, tokenIn.decimals)}
        isHighlighted={queryResponse?.swapKind === SwapKind.GivenIn}
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
        isHighlighted={queryResponse?.swapKind === SwapKind.GivenOut}
      />

      {swapTxUrl ? (
        <ActionSuccessAlert transactionUrl={swapTxUrl} />
      ) : !expectedAmount ? (
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

      {expectedAmount && minOrMaxAmount && (
        <QueryResultsWrapper title={`Amount ${queryResponse?.swapKind === SwapKind.GivenIn ? "Out" : "In"}`}>
          <div className="flex flex-wrap justify-between mb-3">
            <div className="font-bold">Expected</div>
            <div className="text-end">
              <div className="font-bold">{formatToHuman(expectedAmount.amount, expectedAmount.token.decimals)}</div>
              <div className="text-sm">{expectedAmount.amount.toString()}</div>
            </div>
          </div>
          <div className="flex flex-wrap justify-between">
            <div className="font-bold">{queryResponse?.swapKind === SwapKind.GivenIn ? "Minumum" : "Maximum"}</div>
            <div className="text-end">
              <div className="font-bold">{formatToHuman(minOrMaxAmount.amount, minOrMaxAmount.token.decimals)}</div>
              <div className="text-sm">{minOrMaxAmount.amount.toString()}</div>
            </div>
          </div>
        </QueryResultsWrapper>
      )}

      {queryError && <QueryErrorAlert message={queryError.message} />}
    </section>
  );
};
