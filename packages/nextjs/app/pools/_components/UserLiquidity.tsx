import { useEffect } from "react";
import { useAccount } from "wagmi";
import { useQueryRemoveLiquidity } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";
import { formatToHuman } from "~~/utils/";

/**
 * If there is a connected user, display their liquidity within the pool
 */
export const UserLiquidity = ({ pool }: { pool: Pool }) => {
  const { isConnected } = useAccount();
  const { data: queryResponse, refetch: refetchQueryRemove } = useQueryRemoveLiquidity(
    "queryRemoveMax",
    pool,
    pool.userBalance,
  );

  // Hacky solution to display user's proportional token balances within the pool
  useEffect(() => {
    refetchQueryRemove();
  }, [pool.userBalance, refetchQueryRemove]);

  // only render the component if the pool is initialized and the user is connected
  if (!isConnected || !pool?.poolConfig?.isPoolInitialized) {
    return null;
  }

  return (
    <div className="w-full flex flex-col shadow-lg">
      <div className="bg-base-200 p-5 rounded-lg">
        <h5 className="text-xl font-bold mb-3">My Liquidity</h5>

        <div className="bg-neutral rounded-lg">
          <div className="flex justify-between border-base-300 border-b p-4 items-center">
            <div>
              <div className="font-bold">{pool.symbol}</div>
              <div className="text-sm">{pool.name}</div>
            </div>
            <div className="text-end">
              <div className="font-bold">{formatToHuman(pool.userBalance ?? 0n, pool.decimals)}</div>
              <div className="text-sm">{pool.userBalance?.toString()}</div>
            </div>
          </div>
          <div className="p-4 flex flex-col gap-4">
            {pool.poolTokens.map((token, index) => (
              <div key={token.address} className="flex justify-between items-center">
                <div>
                  <div className="font-bold">{token.symbol}</div>
                  <div className="text-sm">{token.name}</div>
                </div>

                <div className="text-end">
                  <div className="font-bold text-end">
                    {queryResponse ? formatToHuman(queryResponse.amountsOut[index].amount, token.decimals) : "0.0000"}
                  </div>
                  <div className="text-sm">
                    {queryResponse ? queryResponse.amountsOut[index].amount.toString() : "0"}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
