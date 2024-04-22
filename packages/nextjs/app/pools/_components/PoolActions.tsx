import { useState } from "react";
import { ExitForm, JoinForm, SwapForm } from "./actions";
import { type Pool } from "~~/hooks/balancer/types";
import { type RefetchPool } from "~~/hooks/balancer/usePoolContract";

type Action = "Swap" | "Join" | "Exit";

export interface PoolActionsProps {
  pool: Pool;
  refetchPool: RefetchPool;
}

/**
 * Allow user to perform swap, join, and exit transactions with a pool
 */
export const PoolActions: React.FC<PoolActionsProps> = ({ pool, refetchPool }) => {
  const [activeTab, setActiveTab] = useState<Action>("Swap");

  const tabs = {
    Swap: <SwapForm pool={pool} refetchPool={refetchPool} />,
    Join: <JoinForm pool={pool} refetchPool={refetchPool} />,
    Exit: <ExitForm pool={pool} refetchPool={refetchPool} />,
  };

  return (
    <div>
      <div className="w-full bg-base-200 rounded-xl p-5">
        <h5 className="text-xl font-bold mb-3">Pool Actions</h5>
        <div className="border border-base-100 rounded-lg">
          <div className="flex">
            {Object.keys(tabs).map(tab => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab as Action)}
                className={`font-bold py-3 flex-1  ${
                  activeTab === tab
                    ? "border border-neutral rounded-tl-lg rounded-tr-lg bg-neutral text-neutral-content"
                    : "border-b border-neutral hover:border hover:border-neutral rounded-tl-lg rounded-tr-lg"
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
