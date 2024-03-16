"use client";

import { useState } from "react";
import { PoolActions, PoolComposition, PoolDetails } from "./_components/";
import type { NextPage } from "next";
import { type Address, isAddress } from "viem";
import { MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import deployedContractsData from "~~/contracts/deployedContracts";
import scaffoldConfig from "~~/scaffold.config";

const Pools: NextPage = () => {
  const [poolAddress, setPoolAddress] = useState<Address>("");

  const isValidAddress = isAddress(poolAddress);

  const scaffoldPoolsRawData = deployedContractsData[scaffoldConfig.targetNetworks[0].id];
  const scaffoldPools = Object.entries(scaffoldPoolsRawData).map(([name, details]) => ({
    name,
    ...details,
  }));

  const [selectedPool, setSelectedPool] = useState<Address>(scaffoldPools[0].address);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

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

        <section className="flex justify-center flex-wrap gap-5 w-full mb-5 items-center text-xl border-b border-white py-5">
          <div className={`dropdown dropdown-end ${isDropdownOpen ? "dropdown-open" : ""}`}>
            <div
              tabIndex={0}
              role="button"
              className="btn text-lg btn-accent w-96"
              onClick={() => setIsDropdownOpen(!isDropdownOpen)}
            >
              Choose Custom Pool
            </div>
            <ul
              tabIndex={0}
              className={`dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52 mt-3 ${
                !isDropdownOpen ? "hidden" : ""
              }`}
            >
              {scaffoldPools.map(pool => (
                <li key={pool.name}>
                  <button
                    onClick={() => {
                      setSelectedPool(pool.address);
                      setIsDropdownOpen(false); // Close the dropdown
                    }}
                  >
                    {pool.name}
                  </button>
                </li>
              ))}
            </ul>
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
            <div className="relative">
              <input
                value={poolAddress}
                onChange={e => setPoolAddress(e.target.value)}
                className="input input-bordered bg-base-200 w-96 text-center pr-16"
                placeholder="Search by contract addresss"
              />
              <button
                className="btn btn-sm btn-accent absolute top-2 right-3 "
                type="submit"
                disabled={!isValidAddress}
              >
                <MagnifyingGlassIcon className="h-5 w-5" />
              </button>
            </div>
          </form>
        </section>

        <div className="flex w-full mb-3 overflow-auto">
          <h3 className="font-extrabold text-transparent text-3xl bg-clip-text bg-gradient-to-r from-pink-500 to-yellow-500">
            {selectedPool}
          </h3>
        </div>
        {selectedPool && (
          <div className="w-full">
            <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-10 mb-5">
              <PoolDetails poolAddress={selectedPool} />
              <PoolActions />
            </div>
            <div className="w-full">
              <PoolComposition />
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Pools;
