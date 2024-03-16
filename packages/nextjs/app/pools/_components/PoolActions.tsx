"use client";

import { Fragment, useState } from "react";
import { ChevronDownIcon } from "@heroicons/react/24/outline";

/**
 * Allow user to perform swap, join, and exit transactions with a pool
 */
export const PoolActions = () => {
  const [selectedTab, setSelectedTab] = useState("swap");

  return (
    <div className="w-full">
      <h5 className="text-2xl font-bold mb-3">Actions</h5>
      <div role="tablist" className="tabs tabs-lifted">
        <input
          type="radio"
          name="swap_tab"
          role="tab"
          className="tab"
          aria-label="Swap"
          checked={selectedTab === "swap"}
          onChange={() => setSelectedTab("swap")}
        />
        <div role="tabpanel" className="tab-content bg-base-200 border-base-300 rounded-box p-6">
          <SwapTab />
        </div>

        <input
          type="radio"
          name="join_tab"
          role="tab"
          className="tab"
          aria-label="Join"
          checked={selectedTab === "join"}
          onChange={() => setSelectedTab("join")}
        />
        <div role="tabpanel" className="tab-content bg-base-200 border-base-300 rounded-box p-6">
          Add liquidity to the pool
        </div>

        <input
          type="radio"
          name="exit_tab"
          role="tab"
          className="tab"
          aria-label="Exit"
          checked={selectedTab === "exit"}
          onChange={() => setSelectedTab("exit")}
        />
        <div role="tabpanel" className="tab-content bg-base-200 border-base-300 rounded-box p-6">
          Remove liquidity from the pool
        </div>
      </div>
    </div>
  );
};

const SwapTab = () => {
  return (
    <Fragment>
      <div className="mb-5">
        <div>
          <label>Token In</label>
        </div>
        <div className="relative">
          <input type="number" className="text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10" />
          <div className="dropdown dropdown-end absolute top-3 right-4 ">
            <div tabIndex={0} role="button" className="btn m-1 btn-accent rounded-lg w-24">
              DAI <ChevronDownIcon className="w-4 h-4" />
            </div>
            <ul tabIndex={0} className="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52">
              <li>
                <a>Item 1</a>
              </li>
              <li>
                <a>Item 2</a>
              </li>
            </ul>
          </div>
        </div>
      </div>
      <div className="mb-5">
        <div>
          <label>Token Out</label>
        </div>
        <div className="relative">
          <input type="number" className="text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10" />
          <div className="dropdown dropdown-end absolute top-3 right-4 ">
            <div tabIndex={0} role="button" className="btn m-1 btn-accent rounded-lg w-24">
              USDe <ChevronDownIcon className="w-4 h-4" />
            </div>
            <ul tabIndex={0} className="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52">
              <li>
                <a>Item 1</a>
              </li>
              <li>
                <a>Item 2</a>
              </li>
            </ul>
          </div>
        </div>
      </div>
      <div>
        <button className="btn btn-accent mt-3 w-full rounded-lg">Swap</button>
      </div>
    </Fragment>
  );
};
