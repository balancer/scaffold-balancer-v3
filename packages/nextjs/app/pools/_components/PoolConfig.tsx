import { type Pool } from "~~/hooks/balancer/types";

function formatPercentage(value: bigint) {
  const scale = BigInt("1000000000000000000"); // 1e18
  // Multiply first to maintain precision in the calculation
  const swapFee = (value * 10000n) / scale; // Multiplying by a larger number to retain more precision
  // Convert to number and then adjust to the percentage format
  const percentage = Number(swapFee) / 100; // Now divide by 100 here to adjust back to a proper percentage
  return `${percentage}%`; // Format to two decimal places
}

/**
 * Display a pool's configuration details
 */
export const PoolConfig = ({ pool }: { pool: Pool }) => {
  // only render the component if the pool has a poolConfig
  if (!pool.poolConfig) {
    return null;
  }

  const detailsRows = [
    { key: "staticSwapFeePercentage", value: formatPercentage(pool.poolConfig.staticSwapFeePercentage) },
    { key: "aggregateSwapFeePercentage", value: formatPercentage(pool.poolConfig.aggregateSwapFeePercentage) },
    { key: "aggregateYieldFeePercentage", value: formatPercentage(pool.poolConfig.aggregateYieldFeePercentage) },
    { key: "tokenDecimalDiffs", value: pool.poolConfig.tokenDecimalDiffs.toString() },

    {
      key: "disableUnbalancedLiquidity",
      value: pool.poolConfig.liquidityManagement.disableUnbalancedLiquidity.toString(),
    },
    {
      key: "enableAddLiquidityCustom",
      value: pool.poolConfig.liquidityManagement.enableAddLiquidityCustom.toString(),
    },
    {
      key: "enableRemoveLiquidityCustom",
      value: pool.poolConfig.liquidityManagement.enableRemoveLiquidityCustom.toString(),
    },
    { key: "isPoolPaused", value: pool.poolConfig.isPoolPaused.toString() },
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
