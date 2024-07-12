import { useState } from "react";
import { AddLiquidityForm, RemoveLiquidityForm, SwapForm } from "./actions";
import { useAccount } from "wagmi";
import { ExclamationTriangleIcon } from "@heroicons/react/24/outline";
import { useTokens } from "~~/hooks/balancer";
import { type Pool, type TokenBalances } from "~~/hooks/balancer/types";
import { type RefetchPool } from "~~/hooks/balancer/usePoolContract";
import { useAccountBalance, useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

type Action = "Swap" | "AddLiquidity" | "RemoveLiquidity";

export interface PoolActionsProps {
  pool: Pool;
  refetchPool: RefetchPool;
  tokenBalances: TokenBalances;
  refetchTokenBalances: () => void;
}

/**
 * Allow user to swap, add liquidity, and remove liquidity from a pool
 */
export const PoolActions: React.FC<{ pool: Pool; refetchPool: RefetchPool }> = ({ pool, refetchPool }) => {
  const [activeTab, setActiveTab] = useState<Action>("Swap");

  const { address } = useAccount();
  const { balance } = useAccountBalance(address);

  const tokens = pool.poolTokens.map(token => ({
    address: token.address as `0x${string}`,
    decimals: token.decimals,
    rawAmount: 0n, // Quirky solution cus useTokens expects type InputAmount[] cus originally built for AddLiquidityForm :D
  }));

  const { tokenBalances, refetchTokenBalances } = useTokens(tokens);

  const userHasNoTokens = Object.values(tokenBalances).every(balance => balance === 0n);

  const { writeAsync: mintToken1 } = useScaffoldContractWrite({
    contractName: "MockToken1",
    functionName: "mint",
    args: [5000000000000000000n],
  });

  const { writeAsync: mintToken2 } = useScaffoldContractWrite({
    contractName: "MockToken2",
    functionName: "mint",
    args: [5000000000000000000n],
  });

  const tabs = {
    Swap: (
      <SwapForm
        pool={pool}
        refetchPool={refetchPool}
        tokenBalances={tokenBalances}
        refetchTokenBalances={refetchTokenBalances}
      />
    ),
    AddLiquidity: (
      <AddLiquidityForm
        pool={pool}
        refetchPool={refetchPool}
        tokenBalances={tokenBalances}
        refetchTokenBalances={refetchTokenBalances}
      />
    ),
    RemoveLiquidity: (
      <RemoveLiquidityForm
        pool={pool}
        refetchPool={refetchPool}
        tokenBalances={tokenBalances}
        refetchTokenBalances={refetchTokenBalances}
      />
    ),
  };

  return (
    <div>
      <div className="w-full bg-base-200 rounded-xl p-5">
        <div className="flex mb-3 items-center gap-5">
          <h5 className="text-xl font-bold text-nowrap">Pool Actions</h5>
          {address && !balance ? <Alert>Click the faucet button in the top right corner!</Alert> : null}
          {balance !== 0 && userHasNoTokens && (
            <Alert>
              Zero balance. To mint mock tokens{" "}
              <span
                className="link"
                onClick={async () => {
                  await mintToken1();
                  await mintToken2();
                  refetchTokenBalances();
                }}
              >
                click here
              </span>
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
    <div className="w-full text-neutral bg-[#fb923c40] border border-orange-400 rounded-lg py-1 px-5 flex gap-2 items-center justify-center">
      <div>
        <ExclamationTriangleIcon className="w-5 h-5" />
      </div>
      <div className="">{children}</div>
    </div>
  );
};
