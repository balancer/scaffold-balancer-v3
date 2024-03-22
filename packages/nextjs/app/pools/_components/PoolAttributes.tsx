"use client";

import { formatUnits } from "viem";
import { Address } from "~~/components/scaffold-eth";
import { usePoolContract } from "~~/hooks/balancer";

/**
 * Display a pool's attritubes 
 * @dev do we want to display any of the pool config details? -> https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#getpoolconfig
 * 
 * struct PoolConfig {
    bool isPoolRegistered;
    bool isPoolInitialized;
    bool isPoolPaused;
    bool isPoolInRecoveryMode;
    bool hasDynamicSwapFee;
    uint64 staticSwapFeePercentage; // stores an 18-decimal FP value (max FixedPoint.ONE)
    uint24 tokenDecimalDiffs; // stores 18-(token decimals), for each token
    uint32 pauseWindowEndTime;
    PoolHooks hooks;
    LiquidityManagement liquidityManagement;
    }
 */
export const PoolAttributes = ({ poolAddress }: { poolAddress: string }) => {
  const { data: pool } = usePoolContract(poolAddress);

  const detailsRows = [
    { attribute: "Name", detail: pool?.name },
    { attribute: "Symbol", detail: pool?.symbol },
    { attribute: "Contract Address", detail: <Address address={pool?.address} size="lg" /> },
    { attribute: "Vault Address", detail: <Address address={pool?.vaultAddress} size="lg" /> },
    { attribute: "Total Supply", detail: formatUnits(pool?.totalSupply || 0n, pool?.decimals || 18) },
  ];
  return (
    <div className="w-full">
      <div className="overflow-x-auto rounded-lg bg-base-200 p-5">
        <h5 className="text-xl font-bold mb-3">Pool Attributes</h5>
        <div className="border border-base-100 rounded-lg">
          {detailsRows.map(({ attribute, detail }, index) => (
            <div
              key={attribute}
              className={`p-3 grid grid-cols-2 ${index == detailsRows.length - 1 ? "" : "border-b border-base-100"}`}
            >
              <div>{attribute}</div>
              <div>{detail}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
