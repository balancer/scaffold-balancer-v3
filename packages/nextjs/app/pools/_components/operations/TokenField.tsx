import { Dispatch, SetStateAction, useState } from "react";
import { ChevronDownIcon, ExclamationTriangleIcon } from "@heroicons/react/24/outline";
import { WalletIcon } from "@heroicons/react/24/outline";
import { Pool, type PoolTokens, SwapConfig } from "~~/hooks/balancer/types";
import { formatToHuman } from "~~/utils";

interface TokenFieldProps {
  label?: string;
  token: { address: string; symbol: string; decimals: number };
  value: string;
  onAmountChange: (value: string) => void;
  selectableTokens?: PoolTokens[];
  userBalance?: bigint;
  isHighlighted?: boolean;
  setMaxAmount?: () => void;
  setSwapConfig?: Dispatch<SetStateAction<SwapConfig>>;
  pool?: Pool;
}

export const TokenField: React.FC<TokenFieldProps> = ({
  label,
  token,
  value,
  onAmountChange,
  setSwapConfig,
  selectableTokens,
  userBalance,
  isHighlighted,
  setMaxAmount,
  pool,
}) => {
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  const isSwap = !!(setSwapConfig && selectableTokens);

  const swapConfigKey = label === "Token In" ? "tokenIn" : "tokenOut";

  const humanUserBalance = formatToHuman(userBalance ?? 0n, token.decimals);

  // Handle swap tokens selection feature
  const handleTokenSelect = (selectedSymbol: string) => {
    if (pool === undefined) return;
    if (setSwapConfig === undefined) return;
    const selectedIndex = pool.poolTokens.findIndex(token => token.symbol === selectedSymbol);
    const otherIndex = pool.poolTokens.length === 2 ? (selectedIndex === 0 ? 1 : 0) : -1;

    setSwapConfig(prev => ({
      ...prev,
      [swapConfigKey]: {
        ...prev.tokenIn,
        poolTokensIndex: selectedIndex,
        amount: "",
        rawAmount: 0n,
      },
      [swapConfigKey === "tokenIn" ? "tokenOut" : "tokenIn"]: {
        poolTokensIndex: otherIndex,
        amount: "",
        rawAmount: 0n,
      },
    }));
    setIsDropdownOpen(false);
  };

  return (
    <div>
      {label && (
        <div className="ml-2 mb-0.5 font-bold">
          <label>{label}</label>
        </div>
      )}
      <div className="relative">
        <input
          type="number"
          value={value}
          onChange={e => onAmountChange(e.target.value)}
          placeholder="0.0"
          className={`text-right text-3xl w-full input shadow-inner rounded-lg bg-base-300 h-24 ${
            isHighlighted ? "ring-1 ring-purple-500" : ""
          }`}
        />
        <div className="absolute top-0 left-0 flex gap-3 p-3">
          <div className="relative">
            <button
              onClick={() => selectableTokens && setIsDropdownOpen(!isDropdownOpen)}
              tabIndex={0}
              role="button"
              disabled={!isSwap}
              className={`${
                isSwap && "hover:bg-base-100 "
              } text-lg bg-neutral rounded-lg px-5 flex items-center justify-center gap-2 font-bold h-[55px] mb-0.5`}
            >
              {token.symbol} {isSwap && <ChevronDownIcon className="w-5 h-5" />}
            </button>
            {isDropdownOpen ? (
              <ul tabIndex={0} className="mt-2 dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52">
                {selectableTokens &&
                  selectableTokens.map(token => (
                    <li
                      key={token.symbol}
                      onClick={() => handleTokenSelect(token.symbol)}
                      className="hover:bg-neutral-400 hover:bg-opacity-40 rounded-xl text-lg"
                    >
                      <a className="font-bold">{token.symbol}</a>
                    </li>
                  ))}
              </ul>
            ) : (
              userBalance !== undefined && (
                <div className="flex gap-3">
                  <div
                    onClick={setMaxAmount}
                    className="flex items-center gap-1 hover:text-accent hover:cursor-pointer"
                  >
                    <WalletIcon className="h-4 w-4 mt-0.5" /> {humanUserBalance}
                  </div>
                  {userBalance === 0n && (
                    <div className="flex items-center gap-1 text-red-400">
                      <ExclamationTriangleIcon className="w-4 h-4 mt-0.5" />
                      no balance
                    </div>
                  )}
                </div>
              )
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
