import Link from "next/link";
import type { NextPage } from "next";

const Router: NextPage = () => {
  return (
    <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20 bg-base-300">
      <div className="w-full text-center">
        <h1 className="text-3xl md:text-5xl font-bold mb-7 text-center">Smart Order Router</h1>
        <Link
          className="text-blue-400 link text-xl"
          target="_blank"
          rel="noopener noreferrer"
          href="https://docs-v3.balancer.fi/data-and-analytics/data-and-analytics/balancer-api.html"
        >
          Guide coming soon™️
        </Link>
      </div>
    </div>
  );
};

export default Router;
