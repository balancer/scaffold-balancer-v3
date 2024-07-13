import { formatUnits } from "viem";
import { Address } from "~~/components/scaffold-eth";
import { Pool } from "~~/hooks/balancer/types";

/**
 * Display a pool's attritubes
 */
export const PoolAttributes = ({ pool }: { pool: Pool }) => {
  const detailsRows = [
    { attribute: "Pool Address", detail: <Address address={pool.address} /> },
    { attribute: "Name", detail: pool.name },
    { attribute: "Symbol", detail: pool.symbol },
    { attribute: "Total Supply", detail: formatUnits(pool.totalSupply, pool.decimals) },
    { attribute: "Decimals", detail: pool.decimals },
    { attribute: "Vault Address", detail: <Address address={pool.vaultAddress} /> },
  ];
  return (
    <div className="w-full">
      <div className="overflow-x-auto rounded-lg bg-base-200 p-5">
        <h5 className="text-xl font-bold mb-3">Pool Attributes</h5>

        <dl className="border border-base-100 rounded-lg">
          {detailsRows.map(({ attribute, detail }, index) => (
            <div
              key={attribute}
              className={`grid grid-cols-2 ${index == detailsRows.length - 1 ? "" : "border-b border-base-100"}`}
            >
              <dt className="p-3 border-r border-base-100">{attribute}</dt>
              <dd className="p-3">{detail}</dd>
            </div>
          ))}
        </dl>
      </div>
    </div>
  );
};
