import { useEffect, useState } from "react";
import { type TokenAmount } from "@balancer/sdk";
import { useAccount } from "wagmi";
import { useRemoveLiquidity } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";
import { formatToHuman } from "~~/utils/formatToHuman";

/**
 * If there is a connected user, display their liquidity within the pool
 */
export const UserLiquidity = ({ pool }: { pool: Pool }) => {
  const [expectedAmountsOut, setExpectedAmountsOut] = useState<TokenAmount[] | undefined>();

  const { isConnected } = useAccount();
  const { queryRemoveLiquidity } = useRemoveLiquidity(pool);

  useEffect(() => {
    async function sendQuery() {
      if (pool.userBalance > 0n) {
        const { expectedAmountsOut } = await queryRemoveLiquidity(pool.userBalance);
        setExpectedAmountsOut(expectedAmountsOut);
      } else {
        setExpectedAmountsOut(undefined);
      }
    }
    sendQuery();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pool.userBalance]); // excluded queryRemoveLiquidity from deps array because it causes infinite re-renders

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
              <div className="font-bold">BPT</div>
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
                    {expectedAmountsOut ? formatToHuman(expectedAmountsOut[index].amount, token.decimals) : "0.0000"}
                  </div>
                  <div className="text-sm">
                    {expectedAmountsOut ? expectedAmountsOut[index].amount.toString() : "0"}
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
