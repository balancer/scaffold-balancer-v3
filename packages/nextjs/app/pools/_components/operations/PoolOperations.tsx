import { useState } from "react";
import { AddLiquidityForm, RemoveLiquidityForm, SwapForm } from ".";
import { useAccount } from "wagmi";
import { Alert } from "~~/components/common";
import { Pool, RefetchPool, TokenBalances } from "~~/hooks/balancer";
import { useAccountBalance, useScaffoldContractWrite } from "~~/hooks/scaffold-eth";
import { useTokenBalancesOfUser } from "~~/hooks/token";

type Operation = "Swap" | "AddLiquidity" | "RemoveLiquidity";

/**
 * Allow user to swap, add liquidity, and remove liquidity from a pool
 */
export const PoolOperations: React.FC<{ pool: Pool; refetchPool: RefetchPool }> = ({ pool, refetchPool }) => {
  const [activeTab, setActiveTab] = useState<Operation>("Swap");

  const { tokenBalances, refetchTokenBalances } = useTokenBalancesOfUser(pool.poolTokens);

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
        <div className="flex h-[44px] justify-between gap-5 relative">
          <h5 className="text-xl font-bold text-nowrap">Pool Operations</h5>
          <div className="absolute -top-2 right-0">
            <PoolOperationsAlerts
              tokenBalances={tokenBalances}
              refetchTokenBalances={refetchTokenBalances}
              isUnbalancedLiquidityDisabled={pool.poolConfig?.liquidityManagement.disableUnbalancedLiquidity ?? false}
            />
          </div>
        </div>
        <div className="bg-neutral rounded-lg">
          <div className="flex">
            {Object.keys(tabs).map(tab => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab as Operation)}
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

const PoolOperationsAlerts = ({
  tokenBalances,
  refetchTokenBalances,
  isUnbalancedLiquidityDisabled,
}: {
  tokenBalances: TokenBalances;
  refetchTokenBalances: () => void;
  isUnbalancedLiquidityDisabled: boolean;
}) => {
  const { address } = useAccount();
  const { balance } = useAccountBalance(address);
  const userHasNoTokens = Object.values(tokenBalances).every(balance => balance === 0n);

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

  const handleMintTokens = async () => {
    await mintToken1();
    await mintToken2();
    refetchTokenBalances();
  };

  if (address && !balance) {
    return <Alert type="warning">Click the faucet button in the top right corner!</Alert>;
  }

  if (balance !== 0 && userHasNoTokens) {
    return (
      <Alert type="info">
        To mint 100 of each mock token:{" "}
        <span className="link" onClick={handleMintTokens}>
          click here
        </span>
      </Alert>
    );
  }

  if (isUnbalancedLiquidityDisabled) {
    return <Alert type="info">This pool only allows proportional liquidity operations</Alert>;
  }

  return null;
};
