import { useState } from "react";
import Link from "next/link";
import { AddLiquidityForm, RemoveLiquidityForm, SwapForm } from "./actions";
import { erc20Abi } from "@balancer/sdk";
import { useAccount, useContractReads, useWalletClient } from "wagmi";
import { ExclamationTriangleIcon } from "@heroicons/react/24/outline";
import { type Pool } from "~~/hooks/balancer/types";
import { type RefetchPool } from "~~/hooks/balancer/usePoolContract";
import { useAccountBalance } from "~~/hooks/scaffold-eth";

type Action = "Swap" | "AddLiquidity" | "RemoveLiquidity";

export interface PoolActionsProps {
  pool: Pool;
  refetchPool: RefetchPool;
}

/**
 * Allow user to swap, add liquidity, and remove liquidity from a pool
 */
export const PoolActions: React.FC<PoolActionsProps> = ({ pool, refetchPool }) => {
  const [activeTab, setActiveTab] = useState<Action>("Swap");

  const { address } = useAccount();
  const { balance } = useAccountBalance(address);
  const { data: walletClient } = useWalletClient();
  const { data: tokenBalances } = useContractReads({
    contracts: pool.poolTokens.map(token => ({
      address: token.address,
      abi: erc20Abi,
      functionName: "balanceOf",
      args: [walletClient?.account.address as string],
    })),
  });

  const userHasNoTokens = tokenBalances?.every(balance => balance.result === 0n);

  const tabs = {
    Swap: <SwapForm pool={pool} refetchPool={refetchPool} />,
    AddLiquidity: <AddLiquidityForm pool={pool} refetchPool={refetchPool} />,
    RemoveLiquidity: <RemoveLiquidityForm pool={pool} refetchPool={refetchPool} />,
  };

  return (
    <div>
      <div className="w-full bg-base-200 rounded-xl p-5">
        <div className="flex mb-3 items-center gap-5">
          <h5 className="text-xl font-bold text-nowrap">Pool Actions</h5>
          {address && !balance ? <Alert>Click the faucet button in the top right corner!</Alert> : null}
          {balance !== 0 && userHasNoTokens && (
            <Alert>
              Mint some mock tokens on the{" "}
              <Link className="link" href="/debug">
                Debug Contracts
              </Link>{" "}
              page
            </Alert>
          )}
        </div>
        <div className="border border-base-100 rounded-lg">
          <div className="flex">
            {Object.keys(tabs).map(tab => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab as Action)}
                className={`font-bold py-3 flex-1  ${
                  activeTab === tab
                    ? "border border-neutral rounded-tl-lg rounded-tr-lg bg-base-100"
                    : "border-b border-base-100 hover:bg-base-100 hover:border hover:border-base-100 rounded-tl-lg rounded-tr-lg"
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

const Alert = ({ children }: { children: React.ReactNode }) => {
  return (
    <div className="text-neutral bg-[#fb923c40] border border-orange-400 rounded-lg py-1 px-5 flex gap-2 items-center justify-center">
      <div>
        <ExclamationTriangleIcon className="w-5 h-5" />
      </div>
      <div className="">{children}</div>
    </div>
  );
};
