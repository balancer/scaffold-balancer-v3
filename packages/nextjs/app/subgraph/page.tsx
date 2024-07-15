import Link from "next/link";
import type { NextPage } from "next";

const Subgraph: NextPage = () => {
  return (
    <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20">
      <div className="w-full text-center">
        <h1 className="text-3xl md:text-5xl font-bold mb-7 text-center">Subgraph</h1>
        <p className="text-xl">
          In order for end users to interact with a pool, the contract must first be indexed by Balancer&apos;s official
          subgraph.{" "}
          <Link
            className="text-blue-400 link"
            target="_blank"
            rel="noopener noreferrer"
            href="https://docs-v3.balancer.fi/data-and-analytics/data-and-analytics/subgraph.html"
          >
            Guide coming soon™️
          </Link>
        </p>
      </div>
    </div>
  );
};

export default Subgraph;
