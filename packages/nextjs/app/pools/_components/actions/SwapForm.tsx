import { useMemo, useState } from "react";
import { PoolActionButton, QueryErrorAlert, QueryResponseAlert, TokenField, TransactionReceiptAlert } from ".";
import { PoolActionsProps } from "../PoolActions";
import { SwapKind } from "@balancer/sdk";
import { parseUnits } from "viem";
import { useContractEvent } from "wagmi";
import abis from "~~/contracts/abis";
import { useSwap } from "~~/hooks/balancer/";
import {
  PoolActionReceipt,
  QueryPoolActionError,
  QuerySwapResponse,
  SwapConfig,
  TokenInfo,
} from "~~/hooks/balancer/types";
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
 * 2. Query swapping some amount of tokens in the pool
 * 3. Approve the vault for the tokenIn used in the swap transaction (if necessary)
 * 4. Send transaction to swap the tokens
 */
export const SwapForm: React.FC<PoolActionsProps> = ({ pool, refetchPool }) => {
  const [queryResponse, setQueryResponse] = useState<QuerySwapResponse | null>(null);
  const [queryError, setQueryError] = useState<QueryPoolActionError>(null);
  const [swapConfig, setSwapConfig] = useState<SwapConfig>(initialSwapConfig);
  const [isTokenOutDropdownOpen, setTokenOutDropdownOpen] = useState(false);
  const [isTokenInDropdownOpen, setTokenInDropdownOpen] = useState(false);
  const [swapReceipt, setSwapReceipt] = useState<PoolActionReceipt>(null);
  const [isApproving, setIsApproving] = useState(false);
  const [isSwapping, setIsSwapping] = useState(false);
  const [isQuerying, setIsQuerying] = useState(false);

  const {
    querySwap,
    swap,
    tokenInAllowance,
    refetchTokenInAllowance,
    tokenInBalance,
    refetchTokenInBalance,
    approveSpenderOnToken,
    approveSpenderOnPermit2,
  } = useSwap(pool, swapConfig);
  const writeTx = useTransactor();

  const tokenIn = pool.poolTokens[swapConfig.tokenIn.poolTokensIndex];
  const tokenOut = pool.poolTokens[swapConfig.tokenOut.poolTokensIndex];

  const sufficientAllowance = useMemo(() => {
    return tokenInAllowance && tokenInAllowance >= swapConfig.tokenIn.rawAmount;
  }, [tokenInAllowance, swapConfig.tokenIn.rawAmount]);

  const handleTokenAmountChange = (amount: string, swapConfigKey: "tokenIn" | "tokenOut") => {
    // Clean up UI to prepare for new query
    setQueryResponse(null);
    setSwapReceipt(null);
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
    setQueryResponse(null);
    setSwapReceipt(null);
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
      await writeTx(approveSpenderOnToken, {
        blockConfirmations: 1,
        onBlockConfirmation: () => {
          refetchTokenInAllowance();
          setIsApproving(false);
        },
      });
      await writeTx(approveSpenderOnPermit2, {
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
      if (tokenInBalance === null || tokenInBalance === undefined || tokenInBalance < swapConfig.tokenIn.rawAmount) {
        throw new Error("Insufficient user balance");
      }
      setIsSwapping(true);
      await swap();
      refetchPool();
      refetchTokenInAllowance();
      refetchTokenInBalance();
    } catch (e) {
      if (e instanceof Error) {
        console.error("error", e);
        setQueryError({ message: e.message });
      } else {
        console.error("An unexpected error occurred", e);
        setQueryError({ message: "An unexpected error occurred" });
      }
    } finally {
      setIsSwapping(false);
    }
  };

  useContractEvent({
    address: pool.vaultAddress,
    abi: abis.balancer.Vault,
    eventName: "Swap",
    listener(log: any[]) {
      const data: TokenInfo[] = [
        {
          decimals: tokenIn.decimals,
          rawAmount: log[0].args.amountIn,
          symbol: `${tokenIn.symbol} In`,
          name: tokenIn.name,
        },
        {
          decimals: tokenOut.decimals,
          rawAmount: log[0].args.amountOut,
          symbol: `${tokenOut.symbol} Out`,
          name: tokenOut.name,
        },
      ];

      setSwapReceipt({ data, transactionHash: log[0].transactionHash });
    },
  });

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
        allowance={formatToHuman(tokenInAllowance, tokenIn.decimals)}
        balance={formatToHuman(tokenInBalance, tokenIn.decimals)}
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

      {!expectedAmount || (expectedAmount && swapReceipt) ? (
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

      {queryError && <QueryErrorAlert message={queryError.message} />}

      {swapReceipt && (
        <TransactionReceiptAlert
          title={`Transaction Receipt`}
          transactionHash={swapReceipt.transactionHash}
          data={swapReceipt.data}
        />
      )}

      {expectedAmount && minOrMaxAmount && (
        <QueryResponseAlert
          title={`Query Amount ${queryResponse?.swapKind === SwapKind.GivenIn ? "Out" : "In"}`}
          data={[
            {
              type: queryResponse?.swapKind === SwapKind.GivenIn ? "Expected" : "Minimum",
              rawAmount: expectedAmount.amount,
              decimals: expectedAmount.token.decimals,
            },
            {
              type: queryResponse?.swapKind === SwapKind.GivenIn ? "Minimum" : "Maximum",
              rawAmount: minOrMaxAmount.amount,
              decimals: minOrMaxAmount.token.decimals,
            },
          ]}
        />
      )}
    </section>
  );
};
