import { useState } from "react";
import { TokenField } from "./TokenField";
import { SwapKind } from "@balancer/sdk";
import { formatUnits, parseUnits } from "viem";
import { useSwap } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";

type SwapInputs = {
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

/**
 * Allow user to perform swap transactions within a pool
 */
export const SwapTab = ({ pool }: { pool: Pool }) => {
  const [queryResponse, setQueryResponse] = useState<QueryResponse>({
    expectedAmount: "0",
    minOrMaxAmount: "0",
    swapKind: undefined,
  });
  const [isTokenInDropdownOpen, setTokenInDropdownOpen] = useState(false);
  const [isTokenOutDropdownOpen, setTokenOutDropdownOpen] = useState(false);
  const [swapConfig, setSwapConfig] = useState<SwapInputs>({
    tokenIn: {
      poolTokensIndex: 0,
      amount: "",
    },
    tokenOut: {
      poolTokensIndex: 1,
      amount: "",
    },
    swapKind: SwapKind.GivenOut,
  });

  const { querySwap } = useSwap();

  // Update the focused input amount with new value and reset the other input amount
  const handleTokenAmountChange = (amount: string, swapConfigKey: "tokenIn" | "tokenOut") => {
    setSwapConfig(prevConfig => {
      const swapKind = swapConfigKey === "tokenIn" ? SwapKind.GivenIn : SwapKind.GivenOut;

      setQueryResponse({
        expectedAmount: "0",
        minOrMaxAmount: "0",
        swapKind: undefined,
      });

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
      pool: pool.address as `0x${string}`,
      tokenIn,
      tokenOut,
      swapKind: swapConfig.swapKind,
    });

    if (updatedAmount.swapKind === SwapKind.GivenIn) {
      setQueryResponse({
        expectedAmount: updatedAmount.expectedAmountOut.amount.toString(),
        minOrMaxAmount: call.minAmountOut.amount.toString(),
        swapKind: SwapKind.GivenIn,
      });

      setSwapConfig(prevConfig => ({
        ...prevConfig,
        tokenOut: {
          ...prevConfig.tokenOut,
          amount: Number(
            formatUnits(updatedAmount.expectedAmountOut.amount.toString(), poolTokens[indexOfTokenOut].decimals),
          ).toFixed(4),
        },
      }));
    } else {
      setQueryResponse({
        expectedAmount: updatedAmount.expectedAmountIn.amount.toString(),
        minOrMaxAmount: call.maxAmountIn.amount.toString(),
        swapKind: SwapKind.GivenOut,
      });

      setSwapConfig(prevConfig => ({
        ...prevConfig,
        tokenIn: {
          ...prevConfig.tokenIn,
          amount: Number(
            formatUnits(updatedAmount.expectedAmountIn.amount.toString(), poolTokens[indexOfTokenIn].decimals),
          ).toFixed(4),
        },
      }));
    }
  };

  const isQueryDisabled = swapConfig.tokenIn.amount === "" && swapConfig.tokenOut.amount === "";

  return (
    <section>
      <TokenField
        label="Token In"
        value={swapConfig.tokenIn.amount}
        onAmountChange={value => handleTokenAmountChange(value, "tokenIn")}
        onTokenSelect={symbol => handleTokenSelection(symbol, "tokenIn")}
        tokenDropdownOpen={isTokenInDropdownOpen}
        setTokenDropdownOpen={setTokenInDropdownOpen}
        poolTokens={pool.poolTokens}
        selectedTokenIndex={swapConfig.tokenIn.poolTokensIndex}
        showAllowance={true}
        showBalance={true}
        isHighlighted={queryResponse.swapKind === SwapKind.GivenIn}
      />
      <TokenField
        label="Token Out"
        value={swapConfig.tokenOut.amount}
        onAmountChange={value => handleTokenAmountChange(value, "tokenOut")}
        onTokenSelect={symbol => handleTokenSelection(symbol, "tokenOut")}
        tokenDropdownOpen={isTokenOutDropdownOpen}
        setTokenDropdownOpen={setTokenOutDropdownOpen}
        poolTokens={pool.poolTokens}
        selectedTokenIndex={swapConfig.tokenOut.poolTokensIndex}
        isHighlighted={queryResponse.swapKind === SwapKind.GivenOut}
      />
      <div>
        <button
          onClick={handleQuerySwap}
          disabled={isQueryDisabled}
          className={`w-full text-white font-bold py-4 rounded-lg ${
            isQueryDisabled
              ? "bg-[#334155] opacity-70 cursor-not-allowed"
              : "bg-gradient-to-tr from-indigo-700 from-15% to-fuchsia-600"
          }`}
        >
          Query Swap
        </button>
      </div>
      <div className="bg-base-100 rounded-lg p-5 mt-5">
        <>
          <div className="flex flex-wrap justify-between mb-3">
            <div>Expected Amount {queryResponse.swapKind === SwapKind.GivenIn ? "Out" : "In"}</div>
            <div>{queryResponse.expectedAmount}</div>
          </div>
          <div className="flex flex-wrap justify-between">
            <div>{queryResponse.swapKind === SwapKind.GivenIn ? "Minumum Amount Out" : "Maximum Amount In"}</div>
            <div>{queryResponse.minOrMaxAmount}</div>
          </div>
          {/* {joinTxUrl && (
            <div className="flex flex-wrap justify-between mt-3">
              <div>Actual BPT Out</div>
              <a
                rel="noopener"
                target="_blank"
                href={joinTxUrl}
                className="text-neutral underline flex items-center gap-1"
              >
                block explorer <ArrowTopRightOnSquareIcon className="w-4 h-4" />
              </a>
            </div>
          )} */}
        </>
      </div>
    </section>
  );
};
