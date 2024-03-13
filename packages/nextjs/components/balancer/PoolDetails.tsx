import { formatUnits } from "viem";
import { Address } from "~~/components/scaffold-eth";
import { usePoolContract } from "~~/hooks/balancer";

/**
 * Display all the contract details for a balancer pool
 */
export const PoolDetails = () => {
  const pool = usePoolContract("ConstantPricePool");
  return (
    <div className="flex flex-col gap-5 text-xl">
      <div className="flex gap-5">
        <div>Name:</div>
        <div>{pool.name}</div>
      </div>

      <div className="flex gap-5">
        <div>Symbol:</div>
        <div>({pool.symbol})</div>
      </div>

      <div className="flex gap-5">
        <div>Pool Address:</div>
        <div>
          <Address address={pool.address} size="xl" />
        </div>
      </div>

      <div className="flex gap-5">
        <div>Vault Address:</div>
        <div>
          <Address address={pool.vaultAddress} size="xl" />
        </div>
      </div>

      <div className="flex gap-5">
        <div>Total Supply:</div>
        <div>{formatUnits(pool.totalSupply || 0n, pool.decimals || 18)}</div>
      </div>
    </div>
  );
};
