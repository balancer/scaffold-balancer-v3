import { useState } from "react";
import { TokenAmount } from "@balancer/sdk";
import { formatUnits, parseUnits } from "viem";
import { PoolFeedback, TokenField } from "~~/app/pools/_components";
import { StyledQueryButton, StyledTxButton } from "~~/components/common";
import { useExit } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";

type ExitQueryResponse = {
  expectedAmountsOut: TokenAmount[] | undefined;
  minAmountsOut: TokenAmount[] | undefined;
};

/**
 *
 */
export const ExitTab = ({ pool }: { pool: Pool }) => {
  const [bptAmountIn, setBptAmountIn] = useState("");
  const [exitTxUrl, setExitTxUrl] = useState<string | undefined>();
  const [queryResponse, setQueryResponse] = useState<ExitQueryResponse>({
    expectedAmountsOut: undefined,
    minAmountsOut: undefined,
  });

  const { userPoolBalance, queryExit, exitPool } = useExit(pool);

  const handleAmountChange = (amount: string) => {
    setBptAmountIn(amount);
    setQueryResponse({ expectedAmountsOut: undefined, minAmountsOut: undefined });
  };

  const handleExitQuery = async () => {
    const rawAmount = parseUnits(bptAmountIn, pool.decimals);
    const { expectedAmountsOut, minAmountsOut } = await queryExit(rawAmount);
    setQueryResponse({ expectedAmountsOut, minAmountsOut });
  };

  const handleExitPool = async () => {
    const txUrl = await exitPool();
    setExitTxUrl(txUrl);
  };

  return (
    <section>
      <TokenField
        label="BPT In"
        tokenSymbol={pool.symbol}
        value={bptAmountIn}
        onAmountChange={handleAmountChange}
        balance={Number(formatUnits(userPoolBalance || 0n, pool.decimals)).toFixed(4)}
      />
      <div className={`grid gap-5 ${queryResponse.expectedAmountsOut ? "grid-cols-2" : "grid-cols-1"}`}>
        <StyledQueryButton onClick={handleExitQuery} isDisabled={bptAmountIn === ""}>
          Query Exit
        </StyledQueryButton>
        {queryResponse.expectedAmountsOut && <StyledTxButton onClick={handleExitPool}>Exit Pool</StyledTxButton>}
      </div>

      <PoolFeedback title="Expected Tokens Out" transactionUrl={exitTxUrl}>
        {pool.poolTokens.map((token, index) => (
          <div key={token.address} className={`${index === 0 ? "mb-3" : ""} flex justify-between items-center`}>
            <div>
              <div className="font-bold">{token.symbol}</div>
              <div className="text-sm">{token.name}</div>
            </div>
            <div>
              {queryResponse.expectedAmountsOut ? (
                <div>
                  <div className="font-bold text-end">{queryResponse.expectedAmountsOut[index].toSignificant(4)}</div>
                  <div className="text-sm">{queryResponse.expectedAmountsOut[index].amount.toString()}</div>
                </div>
              ) : (
                <div className="font-bold">0</div>
              )}
            </div>
          </div>
        ))}
      </PoolFeedback>
    </section>
  );
};
