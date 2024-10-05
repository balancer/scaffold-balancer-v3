"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { PoolOperations, PoolPageSkeleton, PoolSelector } from "./_components/";
import { HooksConfig, PoolAttributes, PoolComposition, PoolConfig, UserLiquidity } from "./_components/info";
import { type NextPage } from "next";
import { type Address } from "viem";
import { Alert } from "~~/components/common";
import { type Pool, type RefetchPool, useReadPool } from "~~/hooks/balancer/";
import { useScaffoldContractRead, useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

/**
 * 1. Search by pool address or select from dropdown
 * 2. Display pool info including composition, attributes, and configurations
 * 3. Perform actions within the selected pool by swapping and adding/removing liquidity
 */
const Pools: NextPage = () => {
  return (
    <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20">
      <div className="">
        <h1 className="text-3xl md:text-5xl font-semibold mb-7 text-center">Custom Pools</h1>
        <div className="text-xl mb-7">
          Select one of the pools deployed to your local fork or search by pool contract address
        </div>
      </div>

      <Suspense fallback={<PoolPageSkeleton />}>
        <PoolPageContent />
      </Suspense>
    </div>
  );
};

export default Pools;

const PoolPageContent = () => {
  const [selectedPoolAddress, setSelectedPoolAddress] = useState<Address | null>(null);

  const { data: pool, refetch: refetchPool, isLoading, isError, isSuccess } = useReadPool(selectedPoolAddress);

  const searchParams = useSearchParams();
  const poolAddress = searchParams.get("address");

  useEffect(() => {
    if (poolAddress) {
      setSelectedPoolAddress(poolAddress);
    }
  }, [poolAddress]);

  return (
    <>
      <PoolSelector selectedPoolAddress={selectedPoolAddress} setSelectedPoolAddress={setSelectedPoolAddress} />
      {isLoading ? (
        <PoolPageSkeleton />
      ) : isError ? (
        <Alert type="error">Error attempting to fetch pool data for {selectedPoolAddress}</Alert>
      ) : (
        isSuccess && pool && <PoolDashboard pool={pool} refetchPool={refetchPool} />
      )}
    </>
  );
};

const PoolDashboard = ({ pool, refetchPool }: { pool: Pool; refetchPool: RefetchPool }) => {
  const searchParams = useSearchParams();
  const poolAddress = searchParams.get("address");

  const { data: linkedTokenAddress } = useScaffoldContractRead({
    contractName: "NftCheckHook",
    functionName: "getLinkedTokenAddress",
  });

  const { data: token } = useScaffoldContractRead({
    contractName: "NftCheckHook",
    functionName: "getToken",
  });

  const { writeAsync: initializePool } = useScaffoldContractWrite({
    contractName: "Router",
    functionName: "initialize",
    address: "0xB12FcB422aAe6720f882E22C340964a7723f2387",
    args: [
      poolAddress!,
      linkedTokenAddress! > token! ? [token!, linkedTokenAddress!] : [linkedTokenAddress!, token!],
      [BigInt(50e18), BigInt(50e18)],
      BigInt(99e18),
      false,
      "0x",
    ],
  });

  return (
    <>
      <h3 className="mb-7 font-semibold text-3xl xl:text-4xl text-transparent bg-clip-text bg-gradient-to-r from-violet-500 via-violet-400 to-orange-500">
        {pool.name}
      </h3>

      {/* <button onClick={transferNft} className="p-2 m-2 border-2 rounded-full border-solid border-red-600">Transfer NFT</button> */}
      <button
        onClick={() => {
          initializePool();
        }}
        className="p-2 mb-8 m-2 border-2 rounded-full border-solid border-red-600"
      >
        Initialize Pool
      </button>

      <div className="w-full">
        <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-7 mb-5">
          <div className="flex flex-col gap-7">
            <UserLiquidity pool={pool} />
            <PoolComposition pool={pool} />
            <HooksConfig pool={pool} />
            <PoolConfig pool={pool} />
          </div>
          <div className="flex flex-col gap-7">
            {pool.poolConfig?.isPoolInitialized && (
              <PoolOperations key={pool.address} pool={pool} refetchPool={refetchPool} />
            )}
            <PoolAttributes pool={pool} />
          </div>
        </div>
      </div>
    </>
  );
};
