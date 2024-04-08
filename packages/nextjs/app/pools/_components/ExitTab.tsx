import { useState } from "react";
import { TokenField } from "./TokenField";
import { formatUnits, parseUnits } from "viem";
import { GradientButton } from "~~/components/common";
import { useExit } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";

/**
 *
 */
export const ExitTab = ({ pool }: { pool: Pool }) => {
  const [bptAmountIn, setBptAmountIn] = useState("");

  const { userPoolBalance, queryExit } = useExit(pool);

  const handleAmountChange = (amount: string) => {
    setBptAmountIn(amount);
  };

  const handleExitQuery = async () => {
    const rawAmount = parseUnits(bptAmountIn, pool.decimals);
    queryExit(rawAmount);
  };

  console.log("userPoolBalance", userPoolBalance);

  return (
    <section>
      <TokenField
        label="BPT In"
        tokenSymbol={pool.symbol}
        value={bptAmountIn}
        onAmountChange={handleAmountChange}
        balance={Number(formatUnits(userPoolBalance || 0n, pool.decimals)).toFixed(4)}
      />
      <div>
        <GradientButton onClick={handleExitQuery} isDisabled={false}>
          Query Exit
        </GradientButton>
      </div>
    </section>
  );
};
