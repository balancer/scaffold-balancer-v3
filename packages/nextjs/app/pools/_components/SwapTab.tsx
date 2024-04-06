import { Dispatch, SetStateAction, useState } from "react";
import { parseUnits } from "viem";
import { ChevronDownIcon } from "@heroicons/react/24/outline";
import { useSwap } from "~~/hooks/balancer/";
import { type Pool, PoolTokens } from "~~/hooks/balancer/types";

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

  const isDisabled = swapConfig.tokenIn.amount === "" && swapConfig.tokenOut.amount === "";

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
      />
      <div>
        <button
          onClick={handleQuerySwap}
          disabled={isDisabled}
          className={`w-full text-white font-bold py-4 rounded-lg ${
            isDisabled
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
            <div>Expected Out</div>
            <div></div>
          </div>
          <div className="flex flex-wrap justify-between">
            <div>Minimum Out</div>
            <div></div>
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

interface TokenFieldProps {
  label: string;
  value: string;
  onAmountChange: (value: string) => void;
  onTokenSelect: (symbol: string) => void;
  tokenDropdownOpen: boolean;
  setTokenDropdownOpen: Dispatch<SetStateAction<boolean>>;
  poolTokens: PoolTokens[];
  selectedTokenIndex: number;
}

const TokenField: React.FC<TokenFieldProps> = ({
  label,
  value,
  onAmountChange,
  onTokenSelect,
  tokenDropdownOpen,
  setTokenDropdownOpen,
  poolTokens,
  selectedTokenIndex,
}) => (
  <div className="mb-5">
    <div className="ml-2 mb-0.5">
      <label>{label}</label>
    </div>
    <div className="relative">
      <input
        type="number"
        value={value}
        onChange={e => onAmountChange(e.target.value)}
        placeholder="0.0"
        className="text-right text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10"
      />
      <div className="absolute top-0 left-0 flex gap-3 p-3">
        <div>
          <div
            onClick={() => setTokenDropdownOpen(!tokenDropdownOpen)}
            tabIndex={0}
            role="button"
            className="bg-base-100 rounded-lg w-28 flex items-center justify-center gap-2 font-bold h-[58px] p-2"
          >
            {poolTokens[selectedTokenIndex].symbol} <ChevronDownIcon className="w-4 h-4" />
          </div>
          {tokenDropdownOpen && (
            <ul tabIndex={0} className="mt-2 dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52">
              {poolTokens
                .filter((_, index) => index !== selectedTokenIndex)
                .map(token => (
                  <li key={token.symbol} onClick={() => onTokenSelect(token.symbol)}>
                    <a>{token.symbol}</a>
                  </li>
                ))}
            </ul>
          )}
        </div>
        <div className="flex flex-col gap-1 justify-center text-sm">
          <div>Allowance:</div>
          <div>Balance:</div>
        </div>
      </div>
    </div>
  </div>
);
