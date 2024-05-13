"use client";

import { Fragment, useEffect, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { PoolActions, PoolAttributes, PoolComposition, PoolConfig, PoolSelector, UserLiquidity } from "./_components/";
import { type NextPage } from "next";
import { type Address } from "viem";
import { parseAbi } from "viem";
import { useAccount, useContractReads, useWalletClient } from "wagmi";
import { ExclamationTriangleIcon } from "@heroicons/react/24/outline";
import { SkeletonLoader } from "~~/components/common";
import { usePoolContract } from "~~/hooks/balancer";
import { type Pool } from "~~/hooks/balancer/types";
import { type RefetchPool } from "~~/hooks/balancer/usePoolContract";
import { useAccountBalance } from "~~/hooks/scaffold-eth";

/**
 * Page for viewing custom pool data and performing actions (swap, join, exit) on a pool
 */
const Pools: NextPage = () => {
  const [selectedPoolAddress, setSelectedPoolAddress] = useState<Address | null>(null);

  const { data: pool, refetch: refetchPool, isLoading, isError, isSuccess } = usePoolContract(selectedPoolAddress);

  const { address } = useAccount();
  const { balance } = useAccountBalance(address);
  const searchParams = useSearchParams();
  const poolAddress = searchParams.get("address");

  useEffect(() => {
    if (poolAddress) {
      setSelectedPoolAddress(poolAddress);
    }
  }, [poolAddress]);

  return (
    <div className="flex-grow bg-base-300">
      <div className="max-w-screen-2xl mx-auto">
        <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20">
          <div>
            <h1 className="text-3xl md:text-5xl font-bold my-7">🌊 Custom Pools</h1>
            <p className="text-xl my-0">
              Balancer is infinitely extensible to allow for any conceivable pool type with custom curves, logic,
              parameters, and more. Each pool deployed to balancer is its own smart contract. This tool allows you to
              interact with any v3 pool deployed on a given network.
            </p>
          </div>

          <PoolSelector setSelectedPoolAddress={setSelectedPoolAddress} />

          {!poolAddress && (
            <div className="text-xl mb-10">
              To get started, search by pool contract address or select a pool from the dropdown
            </div>
          )}

          {address && !balance && (
            <Alert>
              The connected account has no funds to pay gas for transactions. Click the faucet button in the top right
              corner to grab some!
            </Alert>
          )}

          {isLoading ? (
            <PoolPageSkeleton />
          ) : isError ? (
            <div className="text-red-500 text-xl text-center">
              <div className="mb-3">Error fetching pool data. The pool contract address was not valid</div>
              <div>{selectedPoolAddress}</div>
            </div>
          ) : (
            isSuccess && pool && <PoolDashboard pool={pool} refetchPool={refetchPool} />
          )}
        </div>
      </div>
    </div>
  );
};

export default Pools;

const PoolDashboard = ({ pool, refetchPool }: { pool: Pool; refetchPool: RefetchPool }) => {
  const { data: walletClient } = useWalletClient();

  const { data: tokenBalances } = useContractReads({
    contracts: pool.poolTokens.map(token => ({
      address: token.address,
      abi: parseAbi(["function balanceOf(address owner) returns (uint256)"]),
      functionName: "balanceOf",
      args: [walletClient?.account.address as string],
    })),
  });

  const userHasNoTokens = tokenBalances?.every(balance => balance.result === 0n);

  return (
    <Fragment>
      {userHasNoTokens && (
        <Alert>
          The connected account has zero balance for all of the selected pool&apos;s tokens. To grab some mock tokens,
          go to the{" "}
          <Link className="link" href="/debug">
            Debug Contracts
          </Link>{" "}
          page and call the mint function!
        </Alert>
      )}
      <div className="text-center mb-5 bg-base-200 p-3 w-full rounded-lg">
        <h3 className="font-extrabold text-3xl my-2">{pool.name}</h3>
        <h5 className="text-sm md:text-lg xl:text-xl">{pool.address}</h5>
      </div>

      <div className="w-full">
        <div className="grid grid-cols-1 xl:grid-cols-2 w-full gap-7 mb-5">
          <div className="flex flex-col gap-7">
            <UserLiquidity pool={pool} />
            <PoolComposition pool={pool} />
            <PoolAttributes pool={pool} />
          </div>
          <div className="flex flex-col gap-7">
            {pool.poolConfig?.isPoolInitialized && <PoolActions pool={pool} refetchPool={refetchPool} />}
            <PoolConfig pool={pool} />
          </div>
        </div>
      </div>
    </Fragment>
  );
};

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

const Alert = ({ children }: { children: React.ReactNode }) => {
  return (
    <div className="bg-[#FCD34D40] border border-amber-500 rounded-lg p-5 mb-5 w-full flex gap-2 items-center justify-center">
      <div>
        <ExclamationTriangleIcon className="w-5 h-5 text-amber-500" />
      </div>
      <div className="dark:text-amber-500 light:text-amber-800">{children}</div>
    </div>
  );
};
