import { Address } from "~~/components/scaffold-eth";
import { Pool } from "~~/hooks/balancer/types";

/**
 * Display a pool's attritubes
 *
 * @dev do we want to display any of the pool config details?
 * https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#getpoolconfig
 * https://github.com/balancer/balancer-v3-monorepo/blob/48435cb1e0acb212a4103a6bedd2271e94174a01/pkg/interfaces/contracts/vault/VaultTypes.sol#L25-L37
 */
export const PoolAttributes = ({ pool }: { pool: Pool }) => {
  const detailsRows = [
    { attribute: "Name", detail: pool.name },
    { attribute: "Symbol", detail: pool.symbol },
    { attribute: "Contract Address", detail: <Address address={pool.address} size="lg" /> },
    { attribute: "Vault Address", detail: <Address address={pool.vaultAddress} size="lg" /> },
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
