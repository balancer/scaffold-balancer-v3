import { Dispatch, SetStateAction } from "react";
import { ChevronDownIcon, ExclamationTriangleIcon } from "@heroicons/react/24/outline";
import { WalletIcon } from "@heroicons/react/24/outline";
import { type PoolTokens } from "~~/hooks/balancer/types";
import { formatToHuman } from "~~/utils";

interface TokenFieldProps {
  label?: string;
  token: { address: string; symbol: string; decimals: number };
  value: string;
  onAmountChange: (value: string) => void;
  onTokenSelect?: (symbol: string) => void;
  tokenDropdownOpen?: boolean;
  setTokenDropdownOpen?: Dispatch<SetStateAction<boolean>>;
  selectableTokens?: PoolTokens[];
  userBalance?: bigint;
  isHighlighted?: boolean;
  setMaxAmount?: () => void;
}

export const TokenField: React.FC<TokenFieldProps> = ({
  label,
  token,
  value,
  onAmountChange,
  onTokenSelect,
  tokenDropdownOpen,
  setTokenDropdownOpen,
  selectableTokens,
  userBalance,
  isHighlighted,
  setMaxAmount,
}) => {
  const isSwap = !!(setTokenDropdownOpen && onTokenSelect && selectableTokens);

  const humanUserBalance = formatToHuman(userBalance ?? 0n, token.decimals);

  return (
    <div className="mb-5">
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
              onClick={() => setTokenDropdownOpen && setTokenDropdownOpen(!tokenDropdownOpen)}
              tabIndex={0}
              role="button"
              disabled={!isSwap}
              className={`${
                isSwap && "hover:bg-base-100 "
              } text-lg bg-neutral rounded-lg px-5 flex items-center justify-center gap-2 font-bold h-[55px] mb-0.5`}
            >
              {token.symbol} {isSwap && <ChevronDownIcon className="w-5 h-5" />}
            </button>
            {tokenDropdownOpen ? (
              <ul tabIndex={0} className="mt-2 dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52">
                {selectableTokens &&
                  onTokenSelect &&
                  selectableTokens.map(token => (
                    <li
                      key={token.symbol}
                      onClick={() => onTokenSelect(token.symbol)}
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
