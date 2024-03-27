"use client";

import { Fragment, useState } from "react";
import { PoolActions, PoolAttributes, PoolComposition, PoolConfig, PoolSelector, UserLiquidity } from "./_components/";
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

  const [selectedPoolAddress, setSelectedPoolAddress] = useState<string | undefined>();
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
                {!pool.poolConfig.isPoolRegistered && <PoolNotRegisteredAlert />}
                {!pool.poolConfig.isPoolInitialized && pool.poolConfig.isPoolRegistered && <PoolNotInitializedAlert />}

                <div className="text-center mb-5 bg-base-200 p-3 w-full rounded-lg">
                  <h3 className="font-extrabold text-3xl my-2">{pool.name}</h3>
                </div>

                {pool.poolConfig.isPoolRegistered ? (
                  <div className="w-full">
                    <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-7 mb-5">
                      <div className="flex flex-col gap-7">
                        <UserLiquidity pool={pool} />
                        <PoolComposition pool={pool} />
                        <PoolAttributes pool={pool} />
                      </div>
                      <div className="flex flex-col gap-7">
                        <PoolActions />
                        <PoolConfig pool={pool} />
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-7 mb-5">
                    <PoolAttributes pool={pool} />
                  </div>
                )}
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

const PoolNotRegisteredAlert = () => {
  return (
    <div className="w-full mb-5">
      <div role="alert" className="alert alert-warning flex flex-wrap justify-center">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          className="stroke-current shrink-0 h-6 w-6"
          fill="none"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
          />
        </svg>
        <span>
          This pool has not been registered. Check out our{" "}
          <a
            rel="noopener"
            target="_blank"
            className="underline text-blue-700"
            href="https://github.com/MattPereira/scaffold-balancer-v3?tab=readme-ov-file#14-register-a-new-pool-with-the-vault"
          >
            how to register guide
          </a>
        </span>
      </div>
    </div>
  );
};

const PoolNotInitializedAlert = () => {
  return (
    <div className="w-full mb-5">
      <div role="alert" className="alert alert-warning justify-center flex flex-wrap rounded-lg">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          className="stroke-current shrink-0 h-6 w-6"
          fill="none"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
          />
        </svg>
        <span>
          This pool has not been initialized. Check out our{" "}
          <a
            rel="noopener"
            target="_blank"
            className="underline text-blue-700"
            href="https://github.com/MattPereira/scaffold-balancer-v3?tab=readme-ov-file#14-register-a-new-pool-with-the-vault"
          >
            how to initialize guide
          </a>
        </span>
      </div>
    </div>
  );
};
