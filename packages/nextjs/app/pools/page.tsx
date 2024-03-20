"use client";

import { useState } from "react";
import { PoolActions, PoolComposition, PoolDetails } from "./_components/";
import type { NextPage } from "next";
import { type Address, isAddress } from "viem";
import { ChevronDownIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import deployedContractsData from "~~/contracts/deployedContracts";
import { usePoolContract } from "~~/hooks/balancer";
import scaffoldConfig from "~~/scaffold.config";

/**
 *
 */
const Pools: NextPage = () => {
  const [poolAddressInput, setPoolAddressInput] = useState<Address>("");
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  const isValidAddress = isAddress(poolAddressInput);

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

          <section className="flex justify-center flex-wrap gap-5 w-full mb-5 items-center text-xl py-5 border-b border-t border-accent">
            <div className={`dropdown dropdown-end ${isDropdownOpen ? "dropdown-open" : ""}`}>
              <div
                tabIndex={0}
                role="button"
                className="btn text-lg btn-accent w-96 font-normal relative"
                onClick={() => setIsDropdownOpen(!isDropdownOpen)}
              >
                <div>Choose custom pool</div> <ChevronDownIcon className="absolute top-4 right-5 w-5 h-5" />
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
                setSelectedPool(poolAddressInput);
                setPoolAddressInput("");
              }}
            >
              <div className="relative">
                <input
                  value={poolAddressInput}
                  onChange={e => setPoolAddressInput(e.target.value)}
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
          <div className="text-center mb-3">
            <h3 className="font-extrabold text-transparent text-3xl bg-clip-text bg-gradient-to-r from-pink-500 to-yellow-500 mb-0">
              {pool?.name}
            </h3>
            <h3 className="text-2xl text-base-100">{pool?.address}</h3>
          </div>

          {selectedPool && (
            <div className="w-full">
              <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-10 mb-5">
                <PoolComposition />
                <PoolActions />
              </div>
              <div className="w-full">
                <PoolDetails poolAddress={selectedPool} />
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Pools;
