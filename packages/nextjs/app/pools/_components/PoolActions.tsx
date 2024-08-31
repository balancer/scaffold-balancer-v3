import { useState } from "react";
import { AddLiquidityForm, RemoveLiquidityForm, SwapForm } from "./actions";
import { useAccount } from "wagmi";
import { ExclamationTriangleIcon } from "@heroicons/react/24/outline";
import { useReadTokens } from "~~/hooks/balancer";
import { type Pool, RefetchPool } from "~~/hooks/balancer";
import { useAccountBalance, useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

type Action = "Swap" | "AddLiquidity" | "RemoveLiquidity";

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
    rawAmount: 0n, // Quirky solution cus useReadTokens expects type InputAmount[] cus originally built for AddLiquidityForm :D
  }));

  const { tokenBalances, refetchTokenBalances } = useReadTokens(tokens);

  const userHasNoTokens = Object.values(tokenBalances).every(balance => balance === 0n);

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
      <div className="w-full bg-base-200 rounded-xl p-5 shadow-lg min-h-[516px]">
        <div className="flex mb-3 items-center justify-between gap-5">
          <h5 className="text-xl font-bold text-nowrap">Pool Actions</h5>
          {address && !balance ? (
            <Alert>Click the faucet button in the top right corner!</Alert>
          ) : balance !== 0 && userHasNoTokens ? (
            <ZeroTokensAlert refetchTokenBalances={refetchTokenBalances} />
          ) : pool.poolConfig?.liquidityManagement.disableUnbalancedLiquidity ? (
            <Alert>This pool only allows proportional liquidity operations</Alert>
          ) : null}
        </div>
        <div className="bg-neutral rounded-lg">
          <div className="flex">
            {Object.keys(tabs).map(tab => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab as Action)}
                className={`font-bold py-3 flex-1  ${
                  activeTab === tab
                    ? "rounded-tl-lg rounded-tr-lg text-neutral-700 bg-gradient-to-b from-custom-beige-start to-custom-beige-end to-100%"
                    : "border-b border-base-300 hover:bg-base-300 rounded-tl-lg rounded-tr-lg"
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

const ZeroTokensAlert = ({ refetchTokenBalances }: { refetchTokenBalances: () => void }) => {
  const { writeAsync: mintToken1 } = useScaffoldContractWrite({
    contractName: "MockToken1",
    functionName: "mint",
    args: [100000000000000000000n],
  });

  const { writeAsync: mintToken2 } = useScaffoldContractWrite({
    contractName: "MockToken2",
    functionName: "mint",
    args: [100000000000000000000n],
  });

  return (
    <Alert>
      To mint 100 of each mock token{" "}
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
  );
};

const Alert = ({ children }: { children: React.ReactNode }) => {
  return (
    <div className="text-warning bg-warning-tint border border-warning rounded-lg py-1 px-5 flex gap-2 items-center justify-center">
      <div>
        <ExclamationTriangleIcon className="w-5 h-5" />
      </div>
      <div className="">{children}</div>
    </div>
  );
};
