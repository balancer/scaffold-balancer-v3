import { SkeletonLoader } from "~~/components/common";
import { usePoolContract } from "~~/hooks/balancer";

/**
 * Display a pool's token composition including the tokens' symbols, names, and balances
 */
export const PoolComposition = ({ poolAddress }: { poolAddress: string }) => {
  const { data: pool, isLoading: isLoadingPool } = usePoolContract(poolAddress);

  return (
    <div className="w-full flex flex-col">
      <div className="bg-base-200 p-4 rounded-lg ">
        <h5 className="text-xl font-bold mb-3">Pool Composition</h5>

        {isLoadingPool ? (
          <div className="w-full h-48">
            <SkeletonLoader />
          </div>
        ) : (
          <div className="border border-base-100 rounded-lg">
            <div className="flex justify-between items-center border-base-100 border-b p-3">
              <div>
                <div className="font-bold">{pool?.symbol}</div>
                <div className="text-sm">{pool?.name}</div>
              </div>
              <div>{pool?.totalSupply}</div>
            </div>
            <div className="p-3 flex flex-col gap-3">
              {pool?.poolTokens.length > 0 ? (
                pool?.poolTokens?.map((token: any) => (
                  <div key={token.address} className="flex justify-between items-center">
                    <div>
                      <div className="font-bold">{token.symbol}</div>
                      <div className="text-sm">{token.name}</div>
                    </div>
                    <div>
                      <div className="flex justify-end">{token.balance}</div>
                    </div>
                  </div>
                ))
              ) : (
                <div>Pool has no token composition since it has not been registered!</div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
