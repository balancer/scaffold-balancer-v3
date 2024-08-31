import { useEffect } from "react";
import { useAccount } from "wagmi";
import { TokenAmountDisplay } from "~~/components/common/";
import { type Pool, useQueryRemoveLiquidity } from "~~/hooks/balancer/";

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
          <div className="border-base-300 border-b p-4">
            <TokenAmountDisplay
              symbol={pool.symbol}
              name={pool.name}
              decimals={pool.decimals}
              rawAmount={pool.userBalance}
            />
          </div>
          <div className="p-4 flex flex-col gap-4">
            {pool.poolTokens.map((token, index) => (
              <TokenAmountDisplay
                key={index}
                symbol={token.symbol}
                name={token.name}
                decimals={token.decimals}
                rawAmount={queryResponse?.amountsOut[index].amount ?? 0n}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
