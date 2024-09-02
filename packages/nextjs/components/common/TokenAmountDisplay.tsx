import { type TokenAmountDetails } from "~~/hooks/balancer/types";
import { formatToHuman } from "~~/utils/";

export const TokenAmountDisplay = (data: TokenAmountDetails) => {
  const { symbol, name, decimals, rawAmount } = data;
  return (
    <div className={`flex justify-between w-full`}>
      <div>
        <div className="font-bold">{symbol}</div>
        <div className="text-sm">{name}</div>
      </div>
      <div className="text-end">
        <div className="font-bold">{formatToHuman(rawAmount, decimals)}</div>
        <div className="text-sm">{rawAmount.toString()}</div>
      </div>
    </div>
  );
};
