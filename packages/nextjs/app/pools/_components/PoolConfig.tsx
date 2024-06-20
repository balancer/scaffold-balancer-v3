import { type Pool } from "~~/hooks/balancer/types";

/**
 * Display a pool's configuration details
 */
export const PoolConfig = ({ pool }: { pool: Pool }) => {
  // only render the component if the pool has a poolConfig
  if (!pool.poolConfig) {
    return null;
  }

  const detailsRows = [
    { key: "tokenDecimalDiffs", value: pool.poolConfig.tokenDecimalDiffs.toString() },
    { key: "staticSwapFeePercentage", value: pool.poolConfig.staticSwapFeePercentage.toString() },
    { key: "aggregateSwapFeePercentage", value: pool.poolConfig.aggregateSwapFeePercentage.toString() },
    { key: "isPoolPaused", value: pool.poolConfig.isPoolPaused.toString() },
    { key: "pauseWindowEndTime", value: pool.poolConfig.pauseWindowEndTime.toString() },
    { key: "isPoolInRecoveryMode", value: pool.poolConfig.isPoolInRecoveryMode.toString() },
  ];

  return (
    <div className="w-full">
      <div className="overflow-x-auto rounded-lg bg-base-200 p-5">
        <h5 className="text-xl font-bold mb-3">Pool Config</h5>
        <dl className="border border-base-100 rounded-lg">
          {detailsRows.map(({ key, value }, index) => (
            <div
              key={key}
              className={`grid grid-cols-2 ${index == detailsRows.length - 1 ? "" : "border-b border-base-100"}`}
            >
              <dt className="p-3 border-r border-base-100">{key}</dt>
              <dd className="p-3">{value}</dd>
            </div>
          ))}
        </dl>
      </div>
    </div>
  );
};
