// import { SkeletonLoader } from "~~/components/common";
import { useVaultContract } from "~~/hooks/balancer";

/**
 * Display a pool's token composition including the tokens' address, balance, and weight
 *
 * https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#pool-information
 */
export const PoolComposition = ({ poolAddress }: { poolAddress: string }) => {
  const { data: pool } = useVaultContract(poolAddress);

  console.log("useVaultContract", pool);

  return (
    <div className="w-full flex flex-col">
      <div className="bg-base-200 p-4 rounded-lg ">
        <h5 className="text-xl font-bold mb-3">Pool Composition</h5>

        <div className="border border-base-100 rounded-lg">
          <div className="flex justify-between font-bold border-base-100 border-b  p-3">
            <h5 className="font-bold">Total liquidity</h5>
            <h5>$0.00</h5>
          </div>
          <div className="p-3 flex flex-col gap-3">
            <div className="flex justify-between">
              <div>
                <div className="font-bold">DAI</div>
                <div className="text-sm">Dai stablecoin</div>
              </div>
              <div>
                <div className="font-bold flex justify-end">0</div>
                <div className="text-sm">$0.00</div>
              </div>
            </div>
            <div className="flex justify-between">
              <div>
                <div className="font-bold">DAI</div>
                <div className="text-sm">Dai stablecoin</div>
              </div>
              <div>
                <div className="font-bold flex justify-end">0</div>
                <div className="text-sm">$0.00</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
