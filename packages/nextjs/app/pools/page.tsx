"use client";

import { Fragment, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { PoolActions, PoolAttributes, PoolComposition, PoolConfig, PoolSelector, UserLiquidity } from "./_components/";
import type { NextPage } from "next";
import { type Address } from "viem";
import { SkeletonLoader } from "~~/components/common";
import { usePoolContract } from "~~/hooks/balancer";

/**
 * Page for viewing custom pool data and performing actions (swap, join, exit) on a pool
 */
const Pools: NextPage = () => {
  const [selectedPoolAddress, setSelectedPoolAddress] = useState<Address | null>(null);

  const {
    data: pool,
    isFetching,
    refetch: refetchPool,
    isLoading,
    isError,
    isSuccess,
    isIdle,
  } = usePoolContract(selectedPoolAddress);

  const searchParams = useSearchParams();
  const poolAddress = searchParams.get("address");

  useEffect(() => {
    if (poolAddress) {
      setSelectedPoolAddress(poolAddress);
    }
  }, [poolAddress]);

  return (
    <div className="flex-grow bg-base-300">
      <div className="max-w-screen-2xl mx-auto">
        <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20">
          <div>
            <h1 className="text-3xl md:text-5xl font-bold my-7">🌊 Custom Pools</h1>
            <p className="text-xl my-0">
              Balancer is infinitely extensible to allow for any conceivable pool type with custom curves, logic,
              parameters, and more. Each pool deployed to balancer is its own smart contract. This tool allows you to
              interact with any v3 pool deployed on sepolia testnet.
            </p>
          </div>

          <PoolSelector setSelectedPoolAddress={setSelectedPoolAddress} />

          {!poolAddress && (
            <div className="text-xl">
              To get started, search by pool contract address or select a pool from the dropdown
            </div>
          )}

          {isFetching || isLoading || (poolAddress && isIdle) ? (
            <PoolPageSkeleton />
          ) : isError ? (
            <div className="text-red-500 text-xl text-center">
              <div className="mb-3">Error fetching pool data. The pool contract address was not valid</div>
              <div>{selectedPoolAddress}</div>
            </div>
          ) : (
            isSuccess &&
            pool && (
              <Fragment>
                <div className="text-center mb-5 bg-base-200 p-3 w-full rounded-lg">
                  <h3 className="font-extrabold text-3xl my-2">{pool.name}</h3>
                  <h5 className="text-sm md:text-lg xl:text-xl">{pool.address}</h5>
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
                      <PoolConfig pool={pool} />
                    </div>
                  </div>
                </div>
              </Fragment>
            )
          )}
        </div>
      </div>
    </div>
  );
};

export default Pools;

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
