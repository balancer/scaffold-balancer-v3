"use client";

import { useState } from "react";
import { PoolActions, PoolAttributes, PoolComposition, PoolSelector, UserLiquidity } from "./_components/";
import type { NextPage } from "next";
import { type Address } from "viem";
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

  const [selectedPool, setSelectedPool] = useState<Address>(scaffoldPools[0].address);
  const { data: pool } = usePoolContract(selectedPool);

  return (
    <div className="flex-grow bg-base-300">
      <div className="max-w-screen-2xl mx-auto">
        <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20">
          <div className="pb-7">
            <h1 className="text-3xl md:text-5xl font-bold my-7">🌊 Custom Pools</h1>
            <p className="text-xl my-0">
              Balancer is infinitely extensible to allow for any conceivable pool type with custom curves, logic,
              parameters, and more. Each pool deployed to balancer is its own smart contract. This tool allows you to
              interact with any pool currently deployed (custom or existing). To get started, select one of your custom
              pools deployed through scaffold eth or enter the contract address of the desired pool below.
            </p>
          </div>

          <PoolSelector scaffoldPools={scaffoldPools} setSelectedPool={setSelectedPool} />

          <div className="text-center mb-5 border-base-100">
            <h3 className="font-extrabold text-transparent text-3xl bg-clip-text bg-gradient-to-r from-pink-500 to-yellow-500 mb-0">
              {pool?.name}
            </h3>
            <h3 className="md:text-2xl text-base-100">{pool?.address}</h3>
          </div>

          {selectedPool && (
            <div className="w-full">
              <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-7 mb-5">
                <div className="flex flex-col gap-7">
                  <UserLiquidity poolAddress={selectedPool} />
                  <PoolComposition poolAddress={selectedPool} />
                  <PoolAttributes poolAddress={selectedPool} />
                </div>
                <PoolActions />
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Pools;
