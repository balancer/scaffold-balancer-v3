import { Dispatch, SetStateAction } from "react";
import { ChevronDownIcon } from "@heroicons/react/24/outline";
import { type PoolTokens } from "~~/hooks/balancer/types";

interface TokenFieldProps {
  label: string;
  value: string;
  onAmountChange: (value: string) => void;
  onTokenSelect: (symbol: string) => void;
  tokenDropdownOpen: boolean;
  setTokenDropdownOpen: Dispatch<SetStateAction<boolean>>;
  poolTokens: PoolTokens[];
  selectedTokenIndex: number;
  lastChanged?: "tokenIn" | "tokenOut" | "";
  showAllowance?: boolean; // New optional prop for showing allowance
  showBalance?: boolean; // New optional prop for showing balance
  isHighlighted?: boolean; // Optional boolean for highlight control
}

/**
 * Input field for token amounts
 * (optional dropdown for swap token selection)
 * (optional allowance and balance displays)
 */
export const TokenField: React.FC<TokenFieldProps> = ({
  label,
  value,
  onAmountChange,
  onTokenSelect,
  tokenDropdownOpen,
  setTokenDropdownOpen,
  poolTokens,
  selectedTokenIndex,
  isHighlighted,
  showAllowance = false, // Default to not showing if prop is not provided
  showBalance = false, // Default to not showing if prop is not provided
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
        className={`text-right text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10 ${
          isHighlighted ? "ring-2 ring-pink-500" : ""
        }`}
      />
      <div className="absolute top-0 left-0 flex gap-3 p-3">
        <div>
          <div
            onClick={() => setTokenDropdownOpen(!tokenDropdownOpen)}
            tabIndex={0}
            role="button"
            className="hover:bg-neutral hover:text-neutral-content border border-neutral rounded-lg w-28 flex items-center justify-center gap-2 font-bold h-[58px] p-2"
          >
            {poolTokens[selectedTokenIndex].symbol} <ChevronDownIcon className="w-4 h-4" />
          </div>
          {tokenDropdownOpen && (
            <ul
              tabIndex={0}
              className="mt-2 dropdown-content menu p-2 shadow bg-neutral text-neutral-content rounded-box w-52"
            >
              {poolTokens
                .filter((_, index) => index !== selectedTokenIndex)
                .map(token => (
                  <li
                    key={token.symbol}
                    onClick={() => onTokenSelect(token.symbol)}
                    className="hover:bg-neutral-400 hover:bg-opacity-40 rounded-xl"
                  >
                    <a className="font-bold">{token.symbol}</a>
                  </li>
                ))}
            </ul>
          )}
        </div>
        <div className="flex flex-col gap-1 justify-center text-sm">
          {showAllowance && <div>Allowance:</div>}
          {showBalance && <div>Balance:</div>}
        </div>
      </div>
    </div>
  </div>
);
