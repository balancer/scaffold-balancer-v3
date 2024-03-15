"use client";

import { Fragment, useState } from "react";
import { PoolActions, PoolComposition, PoolDetails } from "./_components/";
import type { NextPage } from "next";
import { type Address, isAddress } from "viem";
import { MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { AddressInput } from "~~/components/scaffold-eth";
import deployedContractsData from "~~/contracts/deployedContracts";
import scaffoldConfig from "~~/scaffold.config";

const Pools: NextPage = () => {
  const [poolAddress, setPoolAddress] = useState<Address>("");
  const [selectedPool, setSelectedPool] = useState<Address>("");

  const isValidAddress = isAddress(poolAddress);

  const scaffoldPoolsRawData = deployedContractsData[scaffoldConfig.targetNetworks[0].id];
  const scaffoldPools = Object.entries(scaffoldPoolsRawData).map(([name, details]) => ({
    name,
    ...details,
  }));

  return (
    <div className="bg-base-300 flex-grow">
      <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20">
        <div className="pb-10 border-b border-white">
          <h1 className="text-3xl md:text-5xl font-bold my-10">🌊 Pools</h1>
          <p className="text-xl my-0">
            Balancer is infinitely extensible to allow for any conceivable pool type with custom curves, logic,
            parameters, and more. Each pool deployed to balancer is its own smart contract. This tool allows you to
            interact with any pool currently deployed (custom or existing). To get started, select one of your custom
            pools deployed through scaffold eth or enter the contract address of the desired pool below.
          </p>
        </div>

        <section className="flex justify-between flex-wrap gap-5 w-full mb-5 items-center text-xl border-b border-white py-7">
          <div className="flex items-center gap-5">
            <select
              className="select select-base-100 w-72"
              value={selectedPool}
              onChange={e => setSelectedPool(e.target.value)}
            >
              <option disabled value={""}>
                Select your custom pool
              </option>
              {scaffoldPools.map(pool => (
                <option key={pool.name} value={pool.address}>
                  {pool.name}
                </option>
              ))}
            </select>
          </div>
          <div>OR</div>
          <form
            className="flex flex-row items-center gap-2"
            onSubmit={event => {
              event.preventDefault();
              setSelectedPool(poolAddress);
              setPoolAddress("");
            }}
          >
            <AddressInput value={poolAddress} onChange={setPoolAddress} placeholder={"Search by contract address"} />
            <button className="btn btn-sm btn-accent" type="submit" disabled={!isValidAddress}>
              <MagnifyingGlassIcon className="h-5 w-5" />
            </button>
          </form>
        </section>

        <div className="flex w-full mb-3 overflow-auto">
          <h3 className="font-extrabold text-transparent text-3xl bg-clip-text bg-gradient-to-r from-pink-500 to-yellow-500">
            {selectedPool}
          </h3>
        </div>
        {selectedPool && (
          <Fragment>
            <div className="grid grid-cols-1 lg:grid-cols-2 w-full gap-10 mb-5">
              <PoolDetails poolAddress={selectedPool} />
              <PoolActions />
            </div>
            <div className="w-full">
              <PoolComposition />
            </div>
          </Fragment>
        )}
      </div>
    </div>
  );
};

export default Pools;
