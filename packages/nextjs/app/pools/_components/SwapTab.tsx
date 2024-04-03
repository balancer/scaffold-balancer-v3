import { useState } from "react";
import { parseUnits } from "viem";
import { ChevronDownIcon } from "@heroicons/react/24/outline";
import { useSwap } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";

/**
 * Allow user to perform swap transactions within a pool
 */
export const SwapTab = ({ pool }: { pool: Pool }) => {
  const { querySwap } = useSwap();
  const [swapConfig, setSwapConfig] = useState({
    tokenIn: {
      poolTokensIndex: 0,
      amount: "",
    },
    tokenOut: {
      poolTokensIndex: 1,
      amount: "",
    },
  });

  const [isTokenInDropdownOpen, setTokenInDropdownOpen] = useState(false);
  const [isTokenOutDropdownOpen, setTokenOutDropdownOpen] = useState(false);

  const handleTokenAmountChange = (amount: string, swapConfigKey: "tokenIn" | "tokenOut") => {
    setSwapConfig(prevConfig => ({
      ...prevConfig,
      [swapConfigKey]: {
        ...prevConfig[swapConfigKey],
        amount,
      },
    }));
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

    await querySwap(pool.address as `Ox${string}`, tokenIn, tokenOut);
  };

  return (
    <section>
      <div className="mb-5">
        <div>
          <label>Token In</label>
        </div>
        <div className="relative">
          <input
            type="number"
            value={swapConfig.tokenIn.amount}
            onChange={e => handleTokenAmountChange(e.target.value, "tokenIn")}
            placeholder="0.0"
            className="text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10"
          />
          <div className="dropdown dropdown-end absolute top-3 right-4 ">
            <div
              onClick={() => setTokenInDropdownOpen(!isTokenInDropdownOpen)}
              tabIndex={0}
              role="button"
              className="btn m-1 btn-accent rounded-lg w-24"
            >
              {pool.poolTokens[swapConfig.tokenIn.poolTokensIndex].symbol} <ChevronDownIcon className="w-4 h-4" />
            </div>
            <ul
              tabIndex={0}
              className={`dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52 ${
                !isTokenInDropdownOpen ? "hidden" : ""
              }`}
            >
              {pool.poolTokens
                .filter((_, index) => index !== swapConfig.tokenIn.poolTokensIndex)
                .map(token => (
                  <li key={token.symbol} onClick={() => handleTokenSelection(token.symbol, "tokenIn")}>
                    <a>{token.symbol}</a>
                  </li>
                ))}
            </ul>
          </div>
        </div>
      </div>
      <div className="mb-5">
        <div>
          <label>Token Out</label>
        </div>
        <div className="relative">
          <input
            type="number"
            value={swapConfig.tokenOut.amount}
            onChange={e => handleTokenAmountChange(e.target.value, "tokenOut")}
            placeholder="0.0"
            className="text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10"
          />
          <div className="dropdown dropdown-end absolute top-3 right-4 ">
            <div
              onClick={() => setTokenOutDropdownOpen(!isTokenOutDropdownOpen)}
              tabIndex={0}
              role="button"
              className="btn m-1 btn-accent rounded-lg w-24"
            >
              {pool.poolTokens[swapConfig.tokenOut.poolTokensIndex].symbol} <ChevronDownIcon className="w-4 h-4" />
            </div>
            <ul
              tabIndex={0}
              className={`dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52 ${
                !isTokenOutDropdownOpen ? "hidden" : ""
              }`}
            >
              {pool.poolTokens
                .filter((_, index) => index !== swapConfig.tokenOut.poolTokensIndex)
                .map(token => (
                  <li key={token.symbol} onClick={() => handleTokenSelection(token.symbol, "tokenOut")}>
                    <a>{token.symbol}</a>
                  </li>
                ))}
            </ul>
          </div>
        </div>
      </div>
      <div>
        <button onClick={handleQuerySwap} className="btn btn-accent mt-3 w-full rounded-lg">
          Query Swap
        </button>
      </div>
    </section>
  );
};
