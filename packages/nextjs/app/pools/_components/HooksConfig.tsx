import { Address } from "~~/components/scaffold-eth";
import { type Pool } from "~~/hooks/balancer/types";

/**
 * Display a pool's hooks config information
 */
export const HooksConfig = ({ pool }: { pool: Pool }) => {
  // only render the component if the pool has a poolConfig
  if (!pool.hooksConfig) {
    return null;
  }

  const detailsRows = [
    { key: "hooksContract", value: <Address address={pool.hooksConfig.hooksContract} /> },
    { key: "shouldCallBeforeInitialize", value: pool.hooksConfig.shouldCallBeforeInitialize.toString() },
    { key: "shouldCallAfterInitialize", value: pool.hooksConfig.shouldCallAfterInitialize.toString() },
    { key: "shouldCallComputeDynamicSwapFee", value: pool.hooksConfig.shouldCallComputeDynamicSwapFee.toString() },
    { key: "shouldCallBeforeSwap", value: pool.hooksConfig.shouldCallBeforeSwap.toString() },
    { key: "shouldCallAfterSwap", value: pool.hooksConfig.shouldCallAfterSwap.toString() },
    { key: "shouldCallAfterAddLiquidity", value: pool.hooksConfig.shouldCallAfterAddLiquidity.toString() },
    { key: "shouldCallBeforeRemoveLiquidity", value: pool.hooksConfig.shouldCallBeforeRemoveLiquidity.toString() },
    { key: "shouldCallAfterRemoveLiquidity", value: pool.hooksConfig.shouldCallAfterRemoveLiquidity.toString() },
  ];

  const filteredRows = detailsRows.filter(({ value }) => value !== "false");

  return (
    <div className="w-full">
      <div className="overflow-x-auto rounded-lg bg-base-200 p-5">
        <h5 className="text-xl font-bold mb-3">Hooks Config</h5>
        <dl className="border border-base-100 rounded-lg">
          {filteredRows.map(({ key, value }, index) => (
            <div
              key={key}
              className={`grid grid-cols-2 ${index == filteredRows.length - 1 ? "" : "border-b border-base-100"}`}
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
