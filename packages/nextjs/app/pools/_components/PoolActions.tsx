"use client";

import { useState } from "react";

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
          Swap a token with the pool
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
