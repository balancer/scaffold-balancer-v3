"use client";

import { Fragment, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import {
  HooksConfig,
  PoolActions,
  PoolAttributes,
  PoolComposition,
  PoolConfig,
  PoolSelector,
  UserLiquidity,
} from "./_components/";
import { type NextPage } from "next";
import { type Address } from "viem";
import { SkeletonLoader } from "~~/components/common";
import { usePoolContract } from "~~/hooks/balancer";
import { type Pool } from "~~/hooks/balancer/types";
import { type RefetchPool } from "~~/hooks/balancer/usePoolContract";

/**
 * 1. Search by pool address or select from dropdown
 * 2. Display pool info including composition, attributes, and configurations
 * 3. Perform actions within the selected pool by swapping and adding/removing liquidity
 */
const Pools: NextPage = () => {
  const [selectedPoolAddress, setSelectedPoolAddress] = useState<Address | null>(null);

  const { data: pool, refetch: refetchPool, isLoading, isError, isSuccess } = usePoolContract(selectedPoolAddress);

  const searchParams = useSearchParams();
  const poolAddress = searchParams.get("address");

  useEffect(() => {
    if (poolAddress) {
      setSelectedPoolAddress(poolAddress);
    }
  }, [poolAddress]);

  return (
    <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20">
      <div className="">
        <h1 className="text-3xl md:text-5xl font-semibold my-7 text-center">Custom Pools</h1>
        <div className="text-xl">
          Select one of the pools deployed to your local fork or search by pool contract address
        </div>
      </div>

      <PoolSelector selectedPoolAddress={selectedPoolAddress} setSelectedPoolAddress={setSelectedPoolAddress} />

      {isLoading ? (
        <PoolPageSkeleton />
      ) : isError ? (
        <div className="text-red-500 text-xl text-center">
          <div className="mb-3">Error fetching pool data. The pool contract address was not valid</div>
          <div>{selectedPoolAddress}</div>
        </div>
      ) : (
        isSuccess && pool && <PoolDashboard pool={pool} refetchPool={refetchPool} />
      )}
    </div>
  );
};

export default Pools;

const PoolDashboard = ({ pool, refetchPool }: { pool: Pool; refetchPool: RefetchPool }) => {
  return (
    <Fragment>
      <div className="flex justify-center text-center pb-7 w-full rounded-lg">
        <div>
          <h3 className="font-semibold text-3xl xl:text-4xl my-0 text-transparent bg-clip-text bg-gradient-to-r from-violet-500 via-violet-400 to-orange-500">
            {pool.name}
          </h3>
        </div>
      </div>
      <div className="w-full">
        <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-7 mb-5">
          <div className="flex flex-col gap-7">
            <UserLiquidity pool={pool} />
            <PoolComposition pool={pool} />
            <PoolAttributes pool={pool} />
          </div>
          <div className="flex flex-col gap-7">
            {pool.poolConfig?.isPoolInitialized && <PoolActions pool={pool} refetchPool={refetchPool} />}
            <HooksConfig pool={pool} />
            <PoolConfig pool={pool} />
          </div>
        </div>
      </div>
    </Fragment>
  );
};

const PoolPageSkeleton = () => {
  return (
    <div className="w-full">
      <div className="flex h-20 mb-7">
        <SkeletonLoader />
      </div>
      <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-7 mb-5">
        <div className="flex flex-col gap-7">
          <div className="w-full h-60">
            <SkeletonLoader />
          </div>
          <div className="w-full h-60">
            <SkeletonLoader />
          </div>
          <div className="w-full h-60">
            <SkeletonLoader />
          </div>
        </div>
        <div className="flex flex-col gap-7">
          <div className="w-full h-72">
            <SkeletonLoader />
          </div>
          <div className="w-full h-72">
            <SkeletonLoader />
          </div>
        </div>
      </div>
    </div>
  );
};
