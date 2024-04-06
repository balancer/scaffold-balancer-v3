import { useAccount } from "wagmi";
import { type Pool } from "~~/hooks/balancer/types";

/**
 * If there is a connected user, display their liquidity within the pool
 */
export const UserLiquidity = ({ pool }: { pool: Pool }) => {
  const {
    isConnected,
    // address
  } = useAccount();

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
            <div>TODO</div>
          </div>
          <div className="p-3 flex flex-col gap-3">
            {pool.poolTokens.map((token: any) => (
              <div key={token.address} className="flex justify-between items-center">
                <div>
                  <div className="font-bold">{token.symbol}</div>
                  <div className="text-sm">{token.name}</div>
                </div>
                <div>
                  <div className="flex justify-end">TODO</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
