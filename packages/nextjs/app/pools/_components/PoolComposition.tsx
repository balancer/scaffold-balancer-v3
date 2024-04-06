import { formatUnits } from "viem";
import { type Pool } from "~~/hooks/balancer/types";

/**
 * Display a pool's token composition including the tokens' symbols, names, and balances
 */
export const PoolComposition = ({ pool }: { pool: Pool }) => {
  // if pool is not registered, it won't have any pool tokens to display
  if (!pool?.poolConfig?.isPoolRegistered) {
    return null;
  }
  return (
    <div className="w-full flex flex-col">
      <div className="bg-base-200 p-4 rounded-lg ">
        <h5 className="text-xl font-bold mb-3">Pool Composition</h5>

        <div className="border border-base-100 rounded-lg">
          <div className="flex justify-between items-center border-base-100 border-b p-3">
            <div>
              <div className="font-bold">BPT</div>
              <div className="text-sm">{pool.name}</div>
            </div>
            <div>{formatUnits(pool.totalSupply, pool.decimals)}</div>
          </div>
          <div className="p-3 flex flex-col gap-3">
            {pool.poolTokens.map((token: any) => (
              <div key={token.address} className="flex justify-between items-center">
                <div>
                  <div className="font-bold">{token.symbol}</div>
                  <div className="text-sm">{token.name}</div>
                </div>
                <div>
                  <div className="flex justify-end">{formatUnits(token.balance, token.decimals)}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
