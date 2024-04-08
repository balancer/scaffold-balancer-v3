"use client";

import { Fragment, useState } from "react";
import {
  PoolActions,
  PoolAlert,
  PoolAttributes,
  PoolComposition,
  PoolConfig,
  PoolSelector,
  UserLiquidity,
} from "./_components/";
import type { NextPage } from "next";
import { SkeletonLoader } from "~~/components/common";
import deployedContractsData from "~~/contracts/deployedContracts";
import { usePoolContract } from "~~/hooks/balancer";
import scaffoldConfig from "~~/scaffold.config";

/**
 * Page for viewing custom pool data and performing actions (swap, join, exit) on a pool
 */
const Pools: NextPage = () => {
  // Grab custom pool contract info for pools deployed through scaffold-eth
  const scaffoldPoolsRawData = deployedContractsData[scaffoldConfig.targetNetworks[0].id];
  const scaffoldPools = Object.entries(scaffoldPoolsRawData).map(([name, details]) => ({
    name,
    ...details,
  }));

  const [selectedPoolAddress, setSelectedPoolAddress] = useState<string>("0xAc79a8276860BF96D761804E5ed5736D3AFaAECF");
  const {
    data: pool,
    isLoading,
    // isFetchedAfterMount
  } = usePoolContract(selectedPoolAddress);

  return (
    <div className="flex-grow bg-base-300">
      <div className="max-w-screen-2xl mx-auto">
        <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20">
          <div className="pb-7">
            <h1 className="text-3xl md:text-5xl font-bold my-7">🌊 Custom Pools</h1>
            <p className="text-xl my-0">
              Balancer is infinitely extensible to allow for any conceivable pool type with custom curves, logic,
              parameters, and more. Each pool deployed to balancer is its own smart contract. This tool allows you to
              interact with any pool currently deployed (custom or existing).
            </p>
          </div>

          <PoolSelector scaffoldPools={scaffoldPools} setSelectedPoolAddress={setSelectedPoolAddress} />

          {!selectedPoolAddress && (
            <p className="text-xl">
              To get started, select one of your custom pools deployed through Scaffold Eth or search by contract
              address
            </p>
          )}

          {isLoading ? (
            <PoolPageSkeleton />
          ) : (
            pool && (
              <Fragment>
                <div className="text-center mb-5 bg-base-200 p-3 w-full rounded-lg">
                  <h3 className="font-extrabold text-3xl my-2">{pool.name}</h3>
                </div>
                <div className="w-full">
                  <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-7 mb-5">
                    <div className="flex flex-col gap-7">
                      <UserLiquidity pool={pool} />
                      <PoolComposition pool={pool} />
                      <PoolAttributes pool={pool} />
                    </div>
                    <div className="flex flex-col gap-7">
                      {pool.poolConfig?.isPoolRegistered ? (
                        pool.poolConfig?.isPoolInitialized ? (
                          <PoolActions pool={pool} />
                        ) : (
                          <PoolAlert isRegistered={true} />
                        )
                      ) : (
                        <PoolAlert isRegistered={false} />
                      )}

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
