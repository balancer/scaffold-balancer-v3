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
            <div className="flex flex-wrap justify-between items-center">
              <h1 className="text-3xl md:text-5xl font-bold my-10">📡 Subgraph</h1>
              <a
                href="https://api.studio.thegraph.com/proxy/31386/balancer-v3-sepolia/version/latest/graphql?query=query+AllPools+%7B%0A++pools+%7B%0A++++address%0A++++isInitialized%0A++++totalShares%0A++++tokens+%7B%0A++++++address%0A++++++balance%0A++++++name%0A++++++symbol%0A++++%7D%0A++%7D%0A%7D"
                target="_blank"
                rel="noopener noreferrer"
                className="btn btn-accent rounded-lg"
              >
                Explore Subgraph
              </a>
            </div>
            <p className="text-xl">
              In order for end users to interact with a pool, the pool contract must first be indexed by Balancer&apos;s
              official subgraph. See all the pools currently indexed by the Balancer v3 sepolia subgraph below.
            </p>
          </div>
          <div className="flex w-full">
            <div className="overflow-x-auto rounded-lg bg-base-200 w-full p-5">
              {data ? (
                <div className="border border-base-100 rounded-lg">
                  <table className="table text-lg">
                    <thead>
                      <tr className="text-lg border-b border-base-100">
                        <th className="border-r border-base-100">Address</th>
                        <th className="border-r border-base-100">Name</th>
                        <th className="border-r border-base-100">Symbol</th>
                        <th className="border-r border-base-100">Tokens</th>
                        <th>Total Shares</th>
                      </tr>
                    </thead>
                    <tbody>
                      {data.pools.map((pool: any, index: number) => (
                        <tr
                          key={index}
                          className={`${index < data.pools.length - 1 ? "border-b border-base-100" : ""}`}
                        >
                          <td className="border-r border-base-100">
                            <Address address={pool.address} />
                          </td>
                          <td className="border-r border-base-100">{pool.name}</td>
                          <td className="border-r border-base-100">{pool.symbol}</td>
                          <td className="border-r border-base-100">
                            {pool.tokens.map((token: any, index: number) => (
                              <div key={index}>{token.symbol}</div>
                            ))}
                          </td>
                          <td>{pool.totalShares}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
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
