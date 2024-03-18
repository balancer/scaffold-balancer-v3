"use client";

import { Fragment, useState } from "react";
import { ChevronDownIcon } from "@heroicons/react/24/outline";

type Action = "Swap" | "Join" | "Exit";

/**
 * Allow user to perform swap, join, and exit transactions with a pool
 */
export const PoolActions = () => {
  const [activeTab, setActiveTab] = useState<Action>("Swap");

  const tabs = {
    Swap: <SwapTab />,
    Join: <JoinTab />,
    Exit: <ExitTab />,
  };

  return (
    <div className="w-full">
      <h5 className="text-2xl font-bold mb-3">Actions</h5>

      <div className="w-full bg-base-200 rounded-xl">
        <div className="flex border-b-2 border-base-300">
          {Object.keys(tabs).map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab as Action)}
              className={`py-3 flex-1 hover:font-bold ${
                activeTab === tab ? "bg-base-100 rounded-tl-lg rounded-tr-lg" : ""
              } focus:outline-none`}
            >
              {tab}
            </button>
          ))}
        </div>
        <div className="p-5">{tabs[activeTab]}</div>
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
        <button className="btn btn-accent mt-3 w-full rounded-lg">Query Swap</button>
      </div>
    </Fragment>
  );
};

const JoinTab = () => {
  return (
    <Fragment>
      <div className="mb-5">
        <div>
          <label>Tokens In</label>
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
        <button className="btn btn-accent mt-3 w-full rounded-lg">Query Join</button>
      </div>
    </Fragment>
  );
};

const ExitTab = () => {
  return (
    <Fragment>
      <div className="mb-5">
        <div>
          <label>BPT In</label>
        </div>
        <div className="relative">
          <input type="number" className="text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10" />

          <div tabIndex={0} role="button" className="btn m-1 btn-accent rounded-lg absolute top-3 right-4">
            B-50DAI-50USDe
          </div>
        </div>
      </div>
      <div>
        <button className="btn btn-accent mt-3 w-full rounded-lg">Query Join</button>
      </div>
    </Fragment>
  );
};
