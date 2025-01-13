"use client";

import { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { PoolOperations, PoolPageSkeleton, PoolSelector } from "./_components/";
import { HooksConfig, PoolAttributes, PoolComposition, PoolConfig, UserLiquidity } from "./_components/info";
import { type NextPage } from "next";
import { type Address } from "viem";
import { Alert } from "~~/components/common";
import { type Pool, type RefetchPool, useReadPool } from "~~/hooks/balancer/";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";

/**
 * 1. Search by pool address or select from dropdown
 * 2. Display pool info including composition, attributes, and configurations
 * 3. Perform actions within the selected pool by swapping and adding/removing liquidity
 */
const Pools: NextPage = () => {
  const { targetNetwork } = useTargetNetwork();

  const instructions =
    targetNetwork.id === 31337 ? (
      "Select one of the example custom pools or search by pool contract address"
    ) : (
      <div>
        Search by pool contract address. Find one for {targetNetwork.name} at{" "}
        <Link
          href={`https://${
            targetNetwork.name.toUpperCase() === "SEPOLIA" ? "test." : ""
          }balancer.fi/pools?protocolVersion=3&networks=${
            targetNetwork.name.toUpperCase() === "ETHEREUM" ? "MAINNET" : targetNetwork.name.toUpperCase()
          }`}
          target="_blank"
          rel="noopener noreferrer"
          className="underline hover:text-primary"
        >
          balancer.fi/pools
        </Link>
      </div>
    );

  return (
    <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20">
      <div className="">
        <h1 className="text-3xl md:text-5xl font-semibold mb-7 text-center">Custom Pools</h1>
        <div className="text-xl mb-7">{instructions}</div>
      </div>

      <Suspense fallback={<PoolPageSkeleton />}>
        <PoolPageContent />
      </Suspense>
    </div>
  );
};

export default Pools;

const PoolPageContent = () => {
  const [selectedPoolAddress, setSelectedPoolAddress] = useState<Address | null>(null);

  const { data: pool, refetch: refetchPool, isLoading, isError, isSuccess } = useReadPool(selectedPoolAddress);
  const { targetNetwork } = useTargetNetwork();

  const searchParams = useSearchParams();
  const router = useRouter();
  const poolAddress = searchParams.get("address");
  const network = searchParams.get("network");

  useEffect(() => {
    if (poolAddress && network === targetNetwork.id.toString()) {
      setSelectedPoolAddress(poolAddress);
    } else {
      // Clear pool selection if network doesn't match or no pool address
      setSelectedPoolAddress(null);
      router.replace(`/pools?network=${targetNetwork.id}`);
    }
  }, [poolAddress, targetNetwork, router, network]);

  return (
    <>
      <PoolSelector selectedPoolAddress={selectedPoolAddress} setSelectedPoolAddress={setSelectedPoolAddress} />

      {isLoading ? (
        <PoolPageSkeleton />
      ) : isError ? (
        <Alert type="error">
          Error attempting to fetch pool data for {selectedPoolAddress} on the {targetNetwork.name} network
        </Alert>
      ) : (
        isSuccess && pool && <PoolDashboard pool={pool} refetchPool={refetchPool} />
      )}
    </>
  );
};

const PoolDashboard = ({ pool, refetchPool }: { pool: Pool; refetchPool: RefetchPool }) => {
  return (
    <>
      <h3 className="mb-7 font-semibold text-3xl xl:text-4xl text-transparent bg-clip-text bg-gradient-to-r from-violet-500 via-violet-400 to-orange-500">
        {pool.name}
      </h3>

      <div className="w-full">
        <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-7 mb-5">
          <div className="flex flex-col gap-7">
            <UserLiquidity pool={pool} />
            <PoolComposition pool={pool} />
            <HooksConfig pool={pool} />
            <PoolConfig pool={pool} />
          </div>
          <div className="flex flex-col gap-7">
            {pool.poolConfig?.isPoolInitialized && (
              <PoolOperations key={pool.address} pool={pool} refetchPool={refetchPool} />
            )}
            <PoolAttributes pool={pool} />
          </div>
        </div>
      </div>
    </>
  );
};
