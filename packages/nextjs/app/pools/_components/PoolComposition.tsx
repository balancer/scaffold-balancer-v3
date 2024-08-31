import { TokenAmountDisplay } from "~~/components/common";
import { type Pool } from "~~/hooks/balancer/types";

/**
 * Display a pool's token composition including the tokens' symbols, names, and balances
 */
export const PoolComposition = ({ pool }: { pool: Pool }) => {
  // if pool is not registered, it won't have any pool tokens to display
  if (!pool.poolConfig?.isPoolRegistered) {
    return null;
  }
  return (
    <div className="w-full flex flex-col">
      <div className="bg-base-200 p-5 rounded-lg shadow-lg">
        <h5 className="text-xl font-bold mb-3">Pool Composition</h5>

        <div className="bg-neutral rounded-lg">
          <div className="p-4 flex flex-col gap-4">
            {pool.poolTokens.map((token, idx) => (
              <TokenAmountDisplay
                key={idx}
                symbol={token.symbol}
                name={token.name}
                decimals={token.decimals}
                rawAmount={token.balance}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
