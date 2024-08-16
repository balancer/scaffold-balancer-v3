import Link from "next/link";
import { HooksCards } from "./_components/HooksCards";
import type { NextPage } from "next";

export type HookDetails = {
  id: number;
  title: string;
  source: string;
  description: string;
  github: string;
  additional_link: string;
  created_by: string;
  audited: "Yes" | "No";
  category: string[];
};

const Hooks: NextPage = async () => {
  let hooks: HookDetails[] | null = null;
  const response = await fetch("https://raw.githubusercontent.com/burns2854/balancer-hooks/main/hook-data.json");
  if (response.ok) {
    hooks = await response.json();
  }

  return (
    <div className="flex items-center flex-col flex-grow py-10 px-5 md:px-10 xl:px-20 bg-base-300">
      <div className="mb-7 w-full text-center">
        <h1 className="text-3xl md:text-5xl font-bold mb-7 text-center">Pool Hooks</h1>
        <div className="text-xl my-10">
          Extend the functionality of liquidity pools with hooks contracts. Consider utilizing one of the examples below
          or{" "}
          <Link
            target="_blank"
            rel="noopener noreferrer"
            href="https://balancer-hooks.vercel.app/submit-hook.html"
            className="link"
          >
            submit your own creation
          </Link>
          .
        </div>
      </div>
      <div className="w-full flex flex-col gap-3">
        <div className="w-full grid grid-cols-8 font-bold text-lg">
          <div className="col-start-1 col-end-4">Name</div>
          <div className="col-start-4 col-end-6 text-start hidden md:flex">Repo URL</div>
          <div className="col-start-7 col-end-7">Category</div>
          <div className="col-start-8 col-end-8">Created By</div>
        </div>
        {hooks ? <HooksCards hooks={hooks} /> : <div className="text-xl text-error">Error fetching hooks data!</div>}
      </div>
    </div>
  );
};

export default Hooks;
