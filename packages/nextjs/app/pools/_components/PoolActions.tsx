import { useState } from "react";
import { Exit } from "./Exit";
import { Join } from "./Join";
import { SwapTab } from "./Swap";
import { type Pool } from "~~/hooks/balancer/types";

type Action = "Swap" | "Join" | "Exit";

/**
 * Allow user to perform swap, join, and exit transactions with a pool
 *
 * inspirational demo 👉 https://docs.balancer.fi/tools/core/pools.html
 */
export const PoolActions = ({ pool }: { pool: Pool }) => {
  const [activeTab, setActiveTab] = useState<Action>("Swap");

  const tabs = {
    Swap: <SwapTab pool={pool} />,
    Join: <Join />,
    Exit: <Exit />,
  };

  return (
    <div>
      <div className="w-full bg-base-200 rounded-xl p-5">
        <h5 className="text-xl font-bold mb-3">Pool Actions</h5>
        <div className="border border-base-100 rounded-xl">
          <div className="flex border-b border-base-100">
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
    </div>
  );
};
