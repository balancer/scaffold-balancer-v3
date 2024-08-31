import { formatUnits } from "viem";
import { Address } from "~~/components/scaffold-eth";
import { Pool } from "~~/hooks/balancer/types";
import { formatToPercentage } from "~~/utils/";

export const PoolAttributes = ({ pool }: { pool: Pool }) => {
  const detailsRows = [
    { attribute: "Name", detail: pool.name },
    { attribute: "Symbol", detail: pool.symbol },
    { attribute: "Decimals", detail: pool.decimals },
    { attribute: "Total Supply", detail: formatUnits(pool.totalSupply, pool.decimals) },
    { attribute: "Mininum Swap Fee %", detail: formatToPercentage(pool.minSwapFeePercentage) },
    { attribute: "Maximum Swap Fee %", detail: formatToPercentage(pool.maxSwapFeePercentage) },
    { attribute: "Mininum Invariant Ratio", detail: formatToPercentage(pool.minInvariantRatio) },
    { attribute: "Maximum Invariant Ratio", detail: formatToPercentage(pool.maxInvariantRatio) },
    { attribute: "Pool Address", detail: <Address address={pool.address} /> },
    { attribute: "Vault Address", detail: <Address address={pool.vaultAddress} /> },
  ];

  return (
    <div className="w-full">
      <div className="overflow-x-auto rounded-lg bg-base-200 p-5 shadow-lg">
        <h5 className="text-xl font-bold mb-3">Pool Attributes</h5>

        <dl className="rounded-lg">
          {detailsRows.map(({ attribute, detail }, index) => (
            <div key={attribute} className={`flex justify-between ${index == detailsRows.length - 1 ? "" : ""}`}>
              <dt className="px-3 py-2 ">{attribute}:</dt>
              <dd className="px-3 py-2">{detail}</dd>
            </div>
          ))}
        </dl>
      </div>
    </div>
  );
};
