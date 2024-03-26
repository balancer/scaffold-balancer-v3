import { SkeletonLoader } from "~~/components/common";
import { usePoolContract } from "~~/hooks/balancer";

/**
 * Display a pool's configuration details
 *
 * https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#getpoolconfig
 */
export const PoolConfig = ({ poolAddress }: { poolAddress: string }) => {
  const { data: pool, isLoading } = usePoolContract(poolAddress);

  const detailsRows = [
    { key: "isPoolRegistered", value: pool?.poolConfig?.isPoolRegistered?.toString() },
    { key: "isPoolInitialized", value: pool?.poolConfig?.isPoolInitialized?.toString() },
    { key: "isPoolPaused", value: pool?.poolConfig?.isPoolPaused?.toString() },
    { key: "pauseWindowEndTime", value: pool?.poolConfig?.pauseWindowEndTime?.toString() },
    { key: "staticSwapFeePercentage", value: pool?.poolConfig?.staticSwapFeePercentage?.toString() },
    { key: "hasDynamicSwapFee", value: pool?.poolConfig?.hasDynamicSwapFee?.toString() },
  ];
  return (
    <div className="w-full">
      <div className="overflow-x-auto rounded-lg bg-base-200 p-5">
        <h5 className="text-xl font-bold mb-3">Pool Config</h5>
        {isLoading ? (
          <div className="w-full h-60">
            <SkeletonLoader />
          </div>
        ) : (
          <div className="border border-base-100 rounded-lg">
            {detailsRows.map(({ key, value }, index) => (
              <div
                key={key}
                className={`grid grid-cols-2 ${index == detailsRows.length - 1 ? "" : "border-b border-base-100"}`}
              >
                <div className="p-3 border-r border-base-100">{key}</div>
                <div className="p-3">{value}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
