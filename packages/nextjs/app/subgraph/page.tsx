"use client";

import { gql, useQuery } from "@apollo/client";
import type { NextPage } from "next";
import { SkeletonLoader } from "~~/components/common";
import { Address } from "~~/components/scaffold-eth";

const POOLS_QUERY = gql`
  query AllPools {
    pools {
      address
      name
      symbol
      totalShares
      tokens {
        name
        symbol
      }
    }
  }
`;

const Subgraph: NextPage = () => {
  const { data } = useQuery(POOLS_QUERY, { fetchPolicy: "network-only" });

  return (
    <div className="flex-grow bg-base-300">
      <div className="max-w-screen-2xl mx-auto">
        <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20">
          <div className="mb-10">
            <h1 className="text-3xl md:text-5xl font-bold my-10">📡 Subgraph</h1>
            <p className="text-xl">
              In order for end users to interact with a pool, the pool contract must first be indexed by Balancer&apos;s
              official subgraph. See all the pools currently indexed by the Balancer v3 sepolia subgraph below.
            </p>
          </div>
          <div className="flex w-full">
            <div className="overflow-x-auto rounded-lg bg-base-200 w-full">
              {data ? (
                <table className="table text-lg">
                  <thead>
                    <tr className="text-lg bg-base-100 border-b border-accent">
                      <th className="border-r border-accent">Address</th>
                      <th className="border-r border-accent">Name</th>
                      <th className="border-r border-accent">Symbol</th>
                      <th className="border-r border-accent">Tokens</th>
                      <th>Total Shares</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.pools.map((pool: any, index: number) => (
                      <tr key={index} className={`${index < data.pools.length - 1 ? "border-b border-accent" : ""}`}>
                        <td className="border-r border-accent">
                          <Address address={pool.address} />
                        </td>
                        <td className="border-r border-accent">{pool.name}</td>
                        <td className="border-r border-accent">{pool.symbol}</td>
                        <td className="border-r border-accent">
                          {pool.tokens.map((token: any, index: number) => (
                            <div key={index}>{token.symbol}</div>
                          ))}
                        </td>
                        <td>{pool.totalShares}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ) : (
                <div className="w-full h-96">
                  <SkeletonLoader />
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Subgraph;
