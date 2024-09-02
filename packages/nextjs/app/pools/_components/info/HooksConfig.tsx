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
    { key: "Hooks Address", value: <Address address={pool.hooksConfig.hooksContract} /> },
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
    <div className="overflow-x-auto rounded-lg bg-base-200 p-5 shadow-lg">
      <h5 className="text-xl font-bold mb-3">Hooks Config</h5>
      <dl className=" rounded-lg">
        {filteredRows.map(({ key, value }, index) => (
          <div key={key} className={`flex justify-between ${index == filteredRows.length - 1 ? "" : ""}`}>
            <dt className="px-3 py-2">{key}:</dt>
            <dd className="px-3 py-2">{value}</dd>
          </div>
        ))}
      </dl>
    </div>
  );
};
