"use client";

import { formatUnits } from "viem";
import { Address } from "~~/components/scaffold-eth";
import { usePoolContract } from "~~/hooks/balancer";

/**
 * Display a pool's contract details
 */
export const PoolDetails = ({ contractName }: any) => {
  const pool = usePoolContract(contractName);

  const detailsRows = [
    { attribute: "Name", detail: pool.name },
    { attribute: "Symbol", detail: pool.symbol },
    { attribute: "Contract Address", detail: <Address address={pool.address} size="lg" /> },
    { attribute: "Vault Address", detail: <Address address={pool.vaultAddress} size="lg" /> },
    { attribute: "Total Supply", detail: formatUnits(pool.totalSupply || 0n, pool.decimals || 18) },
  ];
  return (
    <div className="w-full">
      <h5 className="text-2xl font-bold mb-3">Details</h5>
      <div className="overflow-x-auto rounded-lg">
        <table className="table text-lg">
          <thead>
            <tr className="text-lg bg-base-100 border-b border-accent">
              <th className="border-r border-accent">Attribute</th>
              <th>Details</th>
            </tr>
          </thead>
          <tbody className="bg-base-200">
            {detailsRows.map(({ attribute, detail }, index) => (
              <tr key={attribute} className={`${index < detailsRows.length - 1 ? "border-b border-accent" : ""}`}>
                <td className="border-r border-accent">{attribute}</td>
                <td>{detail}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
