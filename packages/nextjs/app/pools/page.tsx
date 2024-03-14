"use client";

import { useState } from "react";
import { PoolActions } from "./_components/PoolActions";
import { PoolComposition } from "./_components/PoolComposition";
import { PoolDetails } from "./_components/PoolDetails";
import type { NextPage } from "next";
import deployedContractsData from "~~/contracts/deployedContracts";
import scaffoldConfig from "~~/scaffold.config";
import { ContractName } from "~~/utils/scaffold-eth/contract";

const Pools: NextPage = () => {
  const deployedPools = deployedContractsData[scaffoldConfig.targetNetworks[0].id];
  const poolContractNames = Object.keys(deployedPools) as ContractName[];
  const [selectedPool, setSelectedPool] = useState(poolContractNames[0]);

  return (
    <div className="bg-base-300 flex-grow">
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

        <section className="flex gap-5 w-full mb-5 items-center text-xl border-b border-white py-7">
          <div>Deployed Custom Pools:</div>
          {poolContractNames.length > 0 &&
            poolContractNames.map(contractName => (
              <button
                key={contractName}
                onClick={() => setSelectedPool(contractName)}
                className={`btn btn-secondary font-light hover:border-transparent ${
                  contractName === selectedPool
                    ? "bg-base-100 hover:bg-base-300 no-animation"
                    : "bg-base-300 hover:bg-secondary"
                }`}
              >
                {contractName}
              </button>
            ))}
        </section>

        <div className="flex w-full mb-3">
          <h3 className="font-extrabold text-transparent text-3xl bg-clip-text bg-gradient-to-r from-pink-500 to-yellow-500">
            {selectedPool}
          </h3>
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 w-full gap-10">
          <PoolComposition />
          <PoolActions />
        </div>
        <PoolDetails contractName={selectedPool} />
      </div>
    </div>
  );
};

export default Pools;
