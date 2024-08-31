import { type Pool } from "~~/hooks/balancer/types";
import { formatToPercentage } from "~~/utils/";

export const PoolConfig = ({ pool }: { pool: Pool }) => {
  // only render the component if the pool has a poolConfig
  if (!pool.poolConfig) {
    return null;
  }

  const detailsRows = [
    { key: "Static Swap Fee %", value: formatToPercentage(pool.poolConfig.staticSwapFeePercentage) },
    { key: "Aggregate Swap Fee %", value: formatToPercentage(pool.poolConfig.aggregateSwapFeePercentage) },
    { key: "Aggregate Yield Fee %", value: formatToPercentage(pool.poolConfig.aggregateYieldFeePercentage) },
    { key: "Token Decimal Diffs", value: pool.poolConfig.tokenDecimalDiffs.toString() },
    {
      key: "Disable Unbalanced Liquidity",
      value: pool.poolConfig.liquidityManagement.disableUnbalancedLiquidity.toString(),
    },
    {
      key: "Enable Add Liquidity Custom",
      value: pool.poolConfig.liquidityManagement.enableAddLiquidityCustom.toString(),
    },
    {
      key: "Enable Remove Liquidity Custom",
      value: pool.poolConfig.liquidityManagement.enableRemoveLiquidityCustom.toString(),
    },
    {
      key: "Enable Donation",
      value: pool.poolConfig.liquidityManagement.enableDonation.toString(),
    },
    { key: "Is Pool Paused", value: pool.poolConfig.isPoolPaused.toString() },
    { key: "Is Pool In Recovery Mode", value: pool.poolConfig.isPoolInRecoveryMode.toString() },
  ];

  return (
    <div className="overflow-x-auto rounded-lg bg-base-200 p-5 shadow-lg">
      <h5 className="text-xl font-bold mb-3">Pool Config</h5>
      <dl className="rounded-lg">
        {detailsRows.map(({ key, value }, index) => (
          <div key={key} className={`flex justify-between ${index == detailsRows.length - 1 ? "" : ""}`}>
            <dt className="px-3 py-2">{key}:</dt>
            <dd className="px-3 py-2">{value}</dd>
          </div>
        ))}
      </dl>
    </div>
  );
};
