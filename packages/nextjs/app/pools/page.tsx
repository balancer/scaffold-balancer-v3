"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { PoolOperations, PoolPageSkeleton, PoolSelector } from "./_components/";
import { HooksConfig, PoolAttributes, PoolComposition, PoolConfig, UserLiquidity } from "./_components/info";
import { TransactionButton } from "./_components/operations/";
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
  const { writeAsync: transferNft, isSuccess: transferSuccess } = useScaffoldContractWrite({
    contractName: "MockNft",
    functionName: "transferFrom",
    args: [userAddress, nftCheckHook, BigInt(0)],
  });

  const { data: linkedTokenAddress } = useScaffoldContractRead({
    contractName: "NftCheckHook",
    functionName: "getLinkedToken",
  });

  const { data: token } = useScaffoldContractRead({
    contractName: "NftCheckHook",
    functionName: "getStableToken",
  });

  const { data: hookBalance } = useScaffoldContractRead({
    contractName: "MockNft",
    functionName: "balanceOf",
    args: [nftCheckHook],
  });
  const hookHasNft = hookBalance && hookBalance !== BigInt(0) ? true : false;

  // button: Initialize Pool
  const { writeAsync: initializePool, isSuccess: initializeSuccess } = useScaffoldContractWrite({
    contractName: "Router",
    functionName: "initialize",
    args: [
      poolAddress!,
      // @ts-ignore
      linkedTokenAddress! > token! ? [token!, linkedTokenAddress!] : [linkedTokenAddress!, token!],
      [BigInt(50e18), BigInt(50e18)],
      BigInt(99e18),
      false,
      "0x",
    ],
  });
  console.log("linkedToken, stableToken, poolAddress: ", linkedTokenAddress, token, poolAddress);

  const { data: getSettlementAmount } = useScaffoldContractRead({
    contractName: "NftCheckHook",
    // @ts-ignore
    functionName: "getSettlementAmount",
  });

  // button: Approve MST Transfer
  const { writeAsync: approveStableTokens, isSuccess: approveStableTokensSuccess } = useScaffoldContractWrite({
    contractName: "MockStable",
    functionName: "approve",
    // @ts-ignore
    args: [nftCheckHook, getSettlementAmount!],
  });

  // button: Settle
  const { writeAsync: settlePool } = useScaffoldContractWrite({
    contractName: "NftCheckHook",
    functionName: "settle",
  });

  const { data: poolOwner } = useScaffoldContractRead({
    contractName: "NftCheckHook",
    functionName: "owner",
  });

  const { data: userRWATBalance } = useScaffoldContractRead({
    contractName: "MockLinked",
    // @ts-ignore
    address: linkedTokenAddress,
    functionName: "balanceOf",
    args: [userAddress],
  });
  console.log("RWAT USERBALANCE: ", userRWATBalance);

  // button: Approve RWAT Transfer
  const { writeAsync: approveRWATTransfer } = useScaffoldContractWrite({
    contractName: "MockLinked",
    address: linkedTokenAddress,
    functionName: "approve",
    args: [nftCheckHook, userRWATBalance],
  });

  // button: Redeem
  const { writeAsync: redeem } = useScaffoldContractWrite({
    contractName: "NftCheckHook",
    functionName: "redeem",
  });

  const { data: isPoolInitialized } = useScaffoldContractRead({
    contractName: "Vault",
    functionName: "isPoolInitialized",
    args: [poolAddress!],
  });

  // const { data: getTestVar } = useScaffoldContractRead({
  //   contractName: "NftCheckHook",
  //   // @ts-ignore
  //   functionName: "getSettlementAmount",
  // });

  console.log("successes", hookHasNft, transferSuccess, initializeSuccess);

  return (
    <>
      <h3 className="mb-7 font-semibold text-3xl xl:text-4xl text-transparent bg-clip-text bg-gradient-to-r from-violet-500 via-violet-400 to-orange-500">
        {pool.name}
      </h3>
      <div className="w-full">
        <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-7 mb-5">
          <div className="flex flex-col gap-7">
            <div className="w-full flex flex-col shadow-lg">
              <div className="bg-base-200 p-5 rounded-lg">
                {!isPoolInitialized ? (
                  <h5 className="text-xl font-bold mb-3">Pool Setup</h5>
                ) : userAddress == poolOwner ? (
                  <h5 className="text-xl font-bold mb-3">Settle Pool</h5>
                ) : (
                  <h5 className="text-xl font-bold mb-3">Redeem</h5>
                )}
                <div className="bg-neutral rounded-lg">
                  <div className="border-base-300 border-b p-4">
                    {!isPoolInitialized ? (
                      <>
                        <TransactionButton
                          label="Transfer NFT"
                          onClick={transferNft}
                          className="mb-2"
                          isFormEmpty={hookHasNft}
                        />
                        <TransactionButton
                          label="Initialize Pool"
                          onClick={initializePool}
                          className="mb-2"
                          isFormEmpty={!transferSuccess || initializeSuccess}
                        />
                      </>
                    ) : (
                      <></>
                    )}
                    <TransactionButton
                      label="Reload"
                      onClick={() => {
                        window.location.reload();
                      }}
                      className="mb-2"
                      isFormEmpty={false}
                    />
                    {isPoolInitialized && userAddress == poolOwner ? (
                      <>
                        <TransactionButton
                          label="Approve MST Transfer"
                          onClick={() => {
                            approveStableTokens();
                          }}
                          className="mb-2"
                          isFormEmpty={!isPoolInitialized}
                        />
                        <TransactionButton
                          label="Settle"
                          onClick={() => {
                            settlePool();
                          }}
                          className="mb-2"
                          isFormEmpty={!approveStableTokensSuccess}
                        />
                      </>
                    ) : (
                      <>
                        <TransactionButton
                          label="Approve RWAT Transfer"
                          onClick={() => {
                            approveRWATTransfer();
                          }}
                          className="mb-2"
                          isFormEmpty={false}
                        />
                        <TransactionButton
                          label="Redeem"
                          onClick={() => {
                            redeem();
                          }}
                          className="mb-2"
                          isFormEmpty={false}
                        />
                      </>
                    )}
                    {/* <TransactionButton
                      label="View value"
                      onClick={() => {
                        console.log(getTestVar);
                      }}
                      className="mb-2"
                      isFormEmpty={false}
                    /> */}
                  </div>
                </div>
              </div>
            </div>
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
