import { useEffect, useState } from "react";
import { SwapKind } from "@balancer/sdk";
import { formatUnits, parseAbi, parseUnits } from "viem";
import { useAccount, useContractRead, useContractWrite } from "wagmi";
import { PoolFeedback, TokenField } from "~~/app/pools/_components";
import { GradientButton, OutlinedButton } from "~~/components/common";
import { useSwap } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";

type SwapConfig = {
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
type QueryResponse = {
  expectedAmount: string;
  minOrMaxAmount: string;
  swapKind: SwapKind | undefined;
};

const initialQueryResponse = {
  expectedAmount: "0",
  minOrMaxAmount: "0",
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
 * Allow user to perform swap transactions within a pool
 */
export const SwapTab = ({ pool }: { pool: Pool }) => {
  const [queryResponse, setQueryResponse] = useState<QueryResponse>(initialQueryResponse);
  const [isTokenInDropdownOpen, setTokenInDropdownOpen] = useState(false);
  const [isTokenOutDropdownOpen, setTokenOutDropdownOpen] = useState(false);
  const [swapConfig, setSwapConfig] = useState<SwapConfig>(initialSwapConfig);
  const [sufficientAllowance, setSufficientAllowance] = useState(false);
  const [swapTxUrl, setSwapTxUrl] = useState<string | undefined>();

  const { address: connectedAddress } = useAccount();
  const { querySwap, swap } = useSwap(pool.address as `0x${string}`);
  const writeTx = useTransactor();

  const { data: allowance } = useContractRead({
    address: pool.poolTokens[swapConfig.tokenIn.poolTokensIndex].address,
    abi: parseAbi(["function allowance(address owner, address spender) returns (uint256)"]),
    functionName: "allowance" as any, // ???
    args: [connectedAddress as string, pool.vaultAddress],
  });

  const { data: balance } = useContractRead({
    address: pool.poolTokens[swapConfig.tokenIn.poolTokensIndex].address,
    abi: parseAbi(["function balanceOf(address owner) returns (uint256)"]),
    functionName: "balanceOf" as any, // ???
    args: [connectedAddress as string],
  });

  const { writeAsync: approve } = useContractWrite({
    address: pool.poolTokens[swapConfig.tokenIn.poolTokensIndex].address,
    abi: parseAbi(["function approve(address spender, uint256 amount) returns (bool)"]),
    functionName: "approve",
    args: [
      pool.vaultAddress,
      parseUnits(swapConfig.tokenIn.amount, pool.poolTokens[swapConfig.tokenIn.poolTokensIndex].decimals),
    ],
  });

  // Verify user has sufficient allowance to perform the swap
  useEffect(() => {
    const tokenInDecimals = pool.poolTokens[swapConfig.tokenIn.poolTokensIndex].decimals;
    const tokenInRawAmount = parseUnits(swapConfig.tokenIn.amount, tokenInDecimals);
    if (allowance && allowance >= tokenInRawAmount) {
      setSufficientAllowance(true);
    } else {
      setSufficientAllowance(false);
    }
  }, [allowance, swapConfig.tokenIn.amount, pool.poolTokens, swapConfig.tokenIn.poolTokensIndex]);

  // Update the focused input amount with new value and reset the other input amount
  const handleTokenAmountChange = (amount: string, swapConfigKey: "tokenIn" | "tokenOut") => {
    setSwapConfig(prevConfig => {
      const swapKind = swapConfigKey === "tokenIn" ? SwapKind.GivenIn : SwapKind.GivenOut;

      setQueryResponse(initialQueryResponse); // Reset query response when input amount changes

      return {
        tokenIn: {
          ...prevConfig.tokenIn,
          amount: swapConfigKey === "tokenIn" ? amount : "",
        },
        tokenOut: {
          ...prevConfig.tokenOut,
          amount: swapConfigKey === "tokenOut" ? amount : "",
        },
        swapKind,
      };
    });
  };

  const handleTokenSelection = (selectedSymbol: string, swapConfigKey: "tokenIn" | "tokenOut") => {
    // Find the original index of the token in pool using its symbol
    const selectedIndex = pool.poolTokens.findIndex(token => token.symbol === selectedSymbol);
    // Determine the index for the other token in the pool if there are only two tokens
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
  };

  // Query the swap and update the expected and min/max amounts in/out
  const handleQuerySwap = async () => {
    const { poolTokens } = pool;
    const indexOfTokenIn = swapConfig.tokenIn.poolTokensIndex;
    const indexOfTokenOut = swapConfig.tokenOut.poolTokensIndex;

    const tokenIn = {
      address: poolTokens[indexOfTokenIn].address as `0x${string}`,
      decimals: poolTokens[indexOfTokenIn].decimals,
      amountRaw: parseUnits(swapConfig.tokenIn.amount, poolTokens[indexOfTokenIn].decimals),
    };

    const tokenOut = {
      address: poolTokens[indexOfTokenOut].address as `0x${string}`,
      decimals: poolTokens[indexOfTokenOut].decimals,
      amountRaw: parseUnits(swapConfig.tokenOut.amount, poolTokens[indexOfTokenOut].decimals),
    };

    const { updatedAmount, call } = await querySwap({
      tokenIn,
      tokenOut,
      swapKind: swapConfig.swapKind,
    });

    if (updatedAmount.swapKind === SwapKind.GivenIn) {
      const expectedAmountOut = updatedAmount.expectedAmountOut.amount.toString();
      const tokenOutDecimals = poolTokens[indexOfTokenOut].decimals;
      setQueryResponse({
        expectedAmount: expectedAmountOut,
        minOrMaxAmount: call.minAmountOut.amount.toString(),
        swapKind: SwapKind.GivenIn,
      });
      // Update the tokenOut amount with the expected amount
      setSwapConfig(prevConfig => ({
        ...prevConfig,
        tokenOut: {
          ...prevConfig.tokenOut,
          amount: Number(formatUnits(expectedAmountOut, tokenOutDecimals)).toFixed(4),
        },
      }));
    } else {
      const expectedAmountIn = updatedAmount.expectedAmountIn.amount.toString();
      const tokenInDecimals = poolTokens[indexOfTokenIn].decimals;
      setQueryResponse({
        expectedAmount: expectedAmountIn,
        minOrMaxAmount: call.maxAmountIn.amount.toString(),
        swapKind: SwapKind.GivenOut,
      });
      // Update the tokenIn amount with the expected amount
      setSwapConfig(prevConfig => ({
        ...prevConfig,
        tokenIn: {
          ...prevConfig.tokenIn,
          amount: Number(formatUnits(expectedAmountIn, tokenInDecimals)).toFixed(4),
        },
      }));
    }
  };

  const handleApprove = async () => {
    try {
      await writeTx(approve, { blockConfirmations: 1 });
      setSufficientAllowance(true);
    } catch (err) {
      console.error("error", err);
    }
  };

  const handleSwap = async () => {
    try {
      const txHash = await swap();
      setSwapTxUrl(txHash);
      setSwapConfig(initialSwapConfig);
    } catch (e) {
      console.error("error", e);
    }
  };

  return (
    <section>
      <TokenField
        label="Token In"
        tokenSymbol={pool.poolTokens[swapConfig.tokenIn.poolTokensIndex].symbol}
        value={swapConfig.tokenIn.amount}
        onAmountChange={value => handleTokenAmountChange(value, "tokenIn")}
        onTokenSelect={symbol => handleTokenSelection(symbol, "tokenIn")}
        tokenDropdownOpen={isTokenInDropdownOpen}
        setTokenDropdownOpen={setTokenInDropdownOpen}
        selectableTokens={pool.poolTokens.filter(
          token => token.symbol !== pool.poolTokens[swapConfig.tokenIn.poolTokensIndex].symbol,
        )}
        allowance={Number(
          formatUnits(allowance || 0n, pool.poolTokens[swapConfig.tokenIn.poolTokensIndex].decimals),
        ).toFixed(4)}
        balance={Number(
          formatUnits(balance || 0n, pool.poolTokens[swapConfig.tokenIn.poolTokensIndex].decimals),
        ).toFixed(4)}
        isHighlighted={queryResponse.swapKind === SwapKind.GivenIn}
      />
      <TokenField
        label="Token Out"
        tokenSymbol={pool.poolTokens[swapConfig.tokenOut.poolTokensIndex].symbol}
        value={swapConfig.tokenOut.amount}
        onAmountChange={value => handleTokenAmountChange(value, "tokenOut")}
        onTokenSelect={symbol => handleTokenSelection(symbol, "tokenOut")}
        tokenDropdownOpen={isTokenOutDropdownOpen}
        setTokenDropdownOpen={setTokenOutDropdownOpen}
        selectableTokens={pool.poolTokens.filter(
          token => token.symbol !== pool.poolTokens[swapConfig.tokenOut.poolTokensIndex].symbol,
        )}
        isHighlighted={queryResponse.swapKind === SwapKind.GivenOut}
      />
      {/* Query, Approve, and Swap Buttons */}
      <div className={`grid gap-5 ${queryResponse.expectedAmount === "0" ? "grid-cols-1" : "grid-cols-2"}`}>
        <div>
          <GradientButton
            onClick={handleQuerySwap}
            isDisabled={swapConfig.tokenIn.amount === "" && swapConfig.tokenOut.amount === ""}
          >
            Query Swap
          </GradientButton>
        </div>
        {queryResponse.expectedAmount === "0" ? null : !sufficientAllowance ? (
          <div>
            <OutlinedButton onClick={handleApprove}>Approve</OutlinedButton>
          </div>
        ) : (
          <div>
            <OutlinedButton onClick={handleSwap}>Send Swap</OutlinedButton>
          </div>
        )}
      </div>
      <PoolFeedback
        title={`Amount ${queryResponse.swapKind === SwapKind.GivenIn ? "Out" : "In"}`}
        transactionUrl={swapTxUrl}
      >
        <div className="flex flex-wrap justify-between mb-3">
          <div>Expected </div>
          <div>{queryResponse.expectedAmount}</div>
        </div>
        <div className="flex flex-wrap justify-between">
          <div>{queryResponse.swapKind === SwapKind.GivenIn ? "Minumum" : "Maximum"}</div>
          <div>{queryResponse.minOrMaxAmount}</div>
        </div>
      </PoolFeedback>
    </section>
  );
};
