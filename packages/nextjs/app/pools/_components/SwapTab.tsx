import { useEffect, useState } from "react";
import { TokenField } from "./TokenField";
import { SwapKind } from "@balancer/sdk";
import { formatUnits, parseAbi, parseUnits } from "viem";
import { useAccount, useContractRead, useContractWrite } from "wagmi";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";
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
  const { querySwap, swap } = useSwap();
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
    functionName: "balanceOf" as any,
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
      // Update the token out amount with the expected amount
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
      // Update the token in amount with the expected amount
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
        value={swapConfig.tokenIn.amount}
        onAmountChange={value => handleTokenAmountChange(value, "tokenIn")}
        onTokenSelect={symbol => handleTokenSelection(symbol, "tokenIn")}
        tokenDropdownOpen={isTokenInDropdownOpen}
        setTokenDropdownOpen={setTokenInDropdownOpen}
        poolTokens={pool.poolTokens}
        selectedTokenIndex={swapConfig.tokenIn.poolTokensIndex}
        allowance={formatUnits(allowance || 0n, pool.poolTokens[swapConfig.tokenIn.poolTokensIndex].decimals)}
        balance={formatUnits(balance || 0n, pool.poolTokens[swapConfig.tokenIn.poolTokensIndex].decimals)}
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
      <div className={`grid gap-5 ${queryResponse.expectedAmount === "0" ? "grid-cols-1" : "grid-cols-2"}`}>
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
        {queryResponse.expectedAmount === "0" ? null : !sufficientAllowance ? (
          <div>
            <button
              onClick={async () => {
                try {
                  await writeTx(approve, { blockConfirmations: 1 });
                  setSufficientAllowance(true);
                } catch (err) {
                  console.error("error", err);
                }
              }}
              className="border border-neutral hover:bg-neutral hover:text-neutral-content font-bold w-full py-4 rounded-lg"
            >
              Approve
            </button>
          </div>
        ) : (
          <div>
            <button
              onClick={handleSwap}
              className="border border-neutral hover:bg-neutral hover:text-neutral-content font-bold w-full py-4 rounded-lg"
            >
              Send Swap
            </button>
          </div>
        )}
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
          {swapTxUrl && (
            <div className="flex flex-wrap justify-between mt-3">
              <div>Actual Amount Out</div>
              <a
                rel="noopener"
                target="_blank"
                href={swapTxUrl}
                className="text-neutral underline flex items-center gap-1"
              >
                block explorer <ArrowTopRightOnSquareIcon className="w-4 h-4" />
              </a>
            </div>
          )}
        </>
      </div>
    </section>
  );
};
