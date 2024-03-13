"use client";

import type { NextPage } from "next";
import { PoolDetails } from "~~/components/balancer/PoolDetails";

const Pools: NextPage = () => {
  return (
    <>
      <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20">
        <div className="pb-10 border-b border-white">
          <h1 className="text-3xl md:text-5xl font-bold my-10">🌊 Pools</h1>
          <p className="text-xl my-0">
            Balancer is infinitely extensible to allow for any conceivable pool type with custom curves, logic,
            parameters, and more. Each pool deployed to balancer is its own smart contract. This tool allows you to
            interact with any pool currently deployed (custom or existing). To get started, enter the contract address
            of the desired pool below.
          </p>
        </div>

        <div className="p-10 w-full">
          <PoolDetails />
        </div>
      </div>
    </>
  );
};

export default Pools;
