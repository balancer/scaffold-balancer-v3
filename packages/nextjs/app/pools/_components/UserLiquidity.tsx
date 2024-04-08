import { useEffect, useState } from "react";
import { type TokenAmount } from "@balancer/sdk";
import { formatUnits } from "viem";
import { useAccount } from "wagmi";
import { useExit } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";

/**
 * If there is a connected user, display their liquidity within the pool
 */
export const UserLiquidity = ({ pool }: { pool: Pool }) => {
  const [expectedAmountsOut, setExpectedAmountsOut] = useState<TokenAmount[] | undefined>();

  const { isConnected } = useAccount();
  const { userPoolBalance, queryExit } = useExit(pool);

  useEffect(() => {
    async function fetchExitQuery() {
      if (!userPoolBalance) return;
      const { expectedAmountsOut } = await queryExit(userPoolBalance);
      console.log("expectedAmountsOut", expectedAmountsOut);
      setExpectedAmountsOut(expectedAmountsOut);
    }
    fetchExitQuery();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userPoolBalance]); // excluded queryExit from deps array because it causes infinite re-renders

  // only render the component if the pool is initialized and the user is connected
  if (!isConnected || !pool?.poolConfig?.isPoolInitialized) {
    return null;
  }

  return (
    <div className="w-full flex flex-col">
      <div className="bg-base-200 p-4 rounded-lg ">
        <h5 className="text-xl font-bold mb-3">My Liquidity</h5>

        <div className="border border-base-100 rounded-lg">
          <div className="flex justify-between border-base-100 border-b p-3 items-center">
            <div>
              <div className="font-bold">BPT</div>
              <div className="text-sm">{pool.name}</div>
            </div>
            <div>
              <div className="font-bold text-end">
                {Number(formatUnits(userPoolBalance || 0n, pool.decimals)).toFixed(2)}
              </div>
              <div className="text-sm">{userPoolBalance?.toString()}</div>
            </div>
          </div>
          <div className="p-3 flex flex-col gap-3">
            {pool.poolTokens.map((token, index) => (
              <div key={token.address} className="flex justify-between items-center">
                <div>
                  <div className="font-bold">{token.symbol}</div>
                  <div className="text-sm">{token.name}</div>
                </div>
                {expectedAmountsOut && (
                  <div>
                    <div className="font-bold text-end">
                      {Number(formatUnits(expectedAmountsOut[index].amount, token.decimals)).toFixed(2)}
                    </div>
                    <div className="text-sm">{expectedAmountsOut[index].amount.toString()}</div>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
