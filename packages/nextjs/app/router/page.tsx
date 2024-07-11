import Link from "next/link";
import type { NextPage } from "next";

const Router: NextPage = () => {
  return (
    <div className="flex items-center flex-col flex-grow py-7 px-5 md:px-10 xl:px-20 bg-base-300">
      <div className="mb-10 w-full">
        <h1 className="text-3xl md:text-5xl font-bold my-10">🧭 Smart Order Router</h1>
        <p className="text-xl">
          {" "}
          <Link
            className="text-blue-400 link"
            target="_blank"
            rel="noopener noreferrer"
            href="https://docs-v3.balancer.fi/data-and-analytics/data-and-analytics/balancer-api.html"
          >
            Guide coming soon™️
          </Link>
        </p>
      </div>
    </div>
  );
};

export default Router;
