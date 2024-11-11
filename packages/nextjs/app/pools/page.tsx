"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { ButtonForm, PoolOperations, PoolPageSkeleton, PoolSelector } from "./_components/";
import { HooksConfig, PoolAttributes, PoolComposition, PoolConfig, UserLiquidity } from "./_components/info";
import { MaxUint256 } from "ethers";
import { type NextPage } from "next";
import { type Address } from "viem";
import { useAccount } from "wagmi";
import { Alert } from "~~/components/common";
import { type Pool, type RefetchPool, useReadPool } from "~~/hooks/balancer/";
import { useDeployedContractInfo, useScaffoldContractRead, useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

/**
 * 1. Search by pool address or select from dropdown
 * 2. Display pool info including composition, attributes, and configurations
 * 3. Perform actions within the selected pool by spping and adding/removing liquidity
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
  const { data: deployedContractData } = useDeployedContractInfo("NftCheckHook");

  const nftCheckHook = deployedContractData?.address;

  const searchParams = useSearchParams();
  const poolAddress = searchParams.get("address");

  const { address: userAddress } = useAccount();

  // button: Transfer NFT
  const { writeAsync: transferNft } = useScaffoldContractWrite({
    contractName: "MockNft",
    functionName: "transferFrom",
    args: [userAddress, nftCheckHook, BigInt(0)],
  });

  const { data: linkedToken = "" } = useScaffoldContractRead({
    contractName: "NftCheckHook",
    functionName: "getLinkedToken",
  });

  const { data: stableToken = "" } = useScaffoldContractRead({
    contractName: "NftCheckHook",
    functionName: "getStableToken",
  });

  const { data: hookBalance } = useScaffoldContractRead({
    contractName: "MockNft",
    functionName: "balanceOf",
    args: [nftCheckHook],
  });
  const hookHasNft = hookBalance && hookBalance !== BigInt(0) ? true : false;

  const { writeAsync: initializePool } = useScaffoldContractWrite({
    contractName: "Router",
    functionName: "initialize",
    args: [
      poolAddress || "",
      linkedToken > stableToken ? [stableToken, linkedToken] : [linkedToken, stableToken],
      [BigInt(50e18), BigInt(50e18)],
      BigInt(99e18),
      false,
      "0x",
    ],
  });

  // button: Approve MST Transfer
  const { writeAsync: approveStableTokens, isSuccess: approveStableTokensSuccess } = useScaffoldContractWrite({
    contractName: "MockStable",
    functionName: "approve",
    // @ts-ignore
    args: [nftCheckHook, MaxUint256],
  });

  // button: Settle Pool
  const { writeAsync: settlePool } = useScaffoldContractWrite({
    contractName: "NftCheckHook",
    functionName: "settle",
  });

  const { data: poolOwner } = useScaffoldContractRead({
    contractName: "NftCheckHook",
    functionName: "owner",
  });

  // button: Approve RWAT Transfer
  const { writeAsync: approveRWATTransfer } = useScaffoldContractWrite({
    contractName: "MockLinked",
    address: linkedToken,
    functionName: "approve",
    args: [nftCheckHook, MaxUint256],
  });

  // button: Redeem
  const { writeAsync: redeem } = useScaffoldContractWrite({
    contractName: "NftCheckHook",
    functionName: "redeem",
  });

  const { data: isPoolInitialized } = useScaffoldContractRead({
    contractName: "Vault",
    functionName: "isPoolInitialized",
    args: [poolAddress || ""],
  });

  console.log("isPoolInitialized:", isPoolInitialized);

  const { data: poolIsSettled } = useScaffoldContractRead({
    contractName: "NftCheckHook",
    functionName: "getPoolIsSettled",
  });

  const userIsOwner = userAddress == poolOwner;

  const { writeAsync: mintStable } = useScaffoldContractWrite({
    contractName: "MockStable",
    functionName: "mint",
    args: [100000000000000000000n],
  });

  useEffect(() => {
    if (isPoolInitialized) {
      console.log("refectching pool");
      refetchPool();
    }
  }, [isPoolInitialized, refetchPool]);

  const PoolActions = () => {
    if (userIsOwner) {
      if (poolIsSettled) {
        return (
          <ButtonForm
            title={"Redeem"}
            buttons={[
              { label: "Approve RWAT Transfer", onClick: approveRWATTransfer, isFormEmpty: false },
              { label: "Redeem", onClick: redeem, isFormEmpty: false },
            ]}
          />
        );
      } else {
        return (
          <ButtonForm
            title={!isPoolInitialized ? "Pool Setup" : "Settle"}
            buttons={
              !isPoolInitialized
                ? [
                    { label: "Transfer NFT", onClick: transferNft, isFormEmpty: hookHasNft },
                    { label: "Initialize Pool", onClick: initializePool, isFormEmpty: !hookHasNft },
                  ]
                : [
                    { label: "Approve MST Transfer", onClick: approveStableTokens, isFormEmpty: !isPoolInitialized },
                    { label: "Settle", onClick: settlePool, isFormEmpty: !approveStableTokensSuccess },
                  ]
            }
          />
        );
      }
    } else {
      if (poolIsSettled) {
        return (
          <ButtonForm
            title={"Redeem"}
            buttons={[
              { label: "Approve RWAT Transfer", onClick: approveRWATTransfer, isFormEmpty: false },
              { label: "Redeem", onClick: redeem, isFormEmpty: false },
            ]}
          />
        );
      } else if (isPoolInitialized) {
        return (
          <>
            <div className="max-w-48">
              <Alert type="info">
                <h5 className="text-xl font-bold mb-3 pt-2">Pool Is Open</h5>
              </Alert>
            </div>
            <div className="max-w-64">
              <Alert type="info">
                To mint 100 MST:{" "}
                <span className="link" onClick={() => mintStable()}>
                  click here
                </span>
              </Alert>
            </div>
          </>
        );
      } else {
        return (
          <div className="max-w-80">
            <Alert type="info">
              <h5 className="text-xl font-bold mb-3 pt-2">Pool Is Not Initialized Yet</h5>
            </Alert>
          </div>
        );
      }
    }
  };

  return (
    <>
      <h3 className="mb-7 font-semibold text-3xl xl:text-4xl text-transparent bg-clip-text bg-gradient-to-r from-violet-500 via-violet-400 to-orange-500">
        {pool.name}
      </h3>
      <div className="w-full">
        <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-7 mb-5">
          <div className="flex flex-col gap-7">
            <PoolActions />

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
