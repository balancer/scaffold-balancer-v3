import { Dispatch, SetStateAction } from "react";
import { ChevronDownIcon } from "@heroicons/react/24/outline";
import { type PoolTokens } from "~~/hooks/balancer/types";

interface TokenFieldProps {
  label?: string;
  value: string;
  tokenSymbol: string;
  onAmountChange: (value: string) => void;
  onTokenSelect?: (symbol: string) => void;
  tokenDropdownOpen?: boolean;
  setTokenDropdownOpen?: Dispatch<SetStateAction<boolean>>;
  selectableTokens?: PoolTokens[];
  lastChanged?: "tokenIn" | "tokenOut" | "";
  allowance?: string;
  balance?: string;
  isHighlighted?: boolean;
}

/**
 * Input field for token amounts
 * (optional dropdown for swap token selection)
 * (optional allowance and balance displays)
 */
export const TokenField: React.FC<TokenFieldProps> = ({
  label,
  value,
  tokenSymbol,
  onAmountChange,
  isHighlighted,
  allowance,
  balance,
  onTokenSelect,
  tokenDropdownOpen,
  setTokenDropdownOpen,
  selectableTokens,
}) => {
  const isTokenSwapField = !!(tokenDropdownOpen && setTokenDropdownOpen && onTokenSelect && selectableTokens);
  return (
    <div className="mb-5">
      {label && (
        <div className="ml-2 mb-0.5">
          <label>{label}</label>
        </div>
      )}
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
          {isTokenSwapField ? (
            <div>
              <div
                onClick={() => setTokenDropdownOpen(!tokenDropdownOpen)}
                tabIndex={0}
                role="button"
                className="hover:bg-neutral hover:text-neutral-content border border-neutral rounded-lg w-28 flex items-center justify-center gap-2 font-bold h-[58px] p-2"
              >
                {tokenSymbol} <ChevronDownIcon className="w-4 h-4" />
              </div>
              {tokenDropdownOpen && (
                <ul
                  tabIndex={0}
                  className="mt-2 dropdown-content menu p-2 shadow bg-neutral text-neutral-content rounded-box w-52"
                >
                  {selectableTokens.map(token => (
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
          ) : (
            <div>
              <div className="min-w-[100px] border border-neutral rounded-lg flex items-center justify-center gap-2 font-bold h-[58px] px-5">
                {tokenSymbol}
              </div>
            </div>
          )}
          <div className="flex flex-col gap-1 justify-center text-sm">
            <table className="">
              <tbody className="text-neutral-400">
                {allowance && (
                  <tr>
                    <td className="align-top">Allowed :</td>
                    <td className="pl-1">{allowance}</td>
                  </tr>
                )}
                {balance && (
                  <tr>
                    <td className="align-top">Balance :</td>
                    <td className="pl-1">{balance}</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};
