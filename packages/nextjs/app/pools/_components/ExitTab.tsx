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

const initialBptIn = {
  rawAmount: 0n,
  displayValue: "",
};

const initialQueryResponse = {
  expectedAmountsOut: undefined,
  minAmountsOut: undefined,
};

/**
 * 1. Query the results of exit transaction
 * 2. User sends transaction to exit the pool
 */
export const ExitTab = ({ pool }: { pool: Pool }) => {
  const [bptIn, setBptIn] = useState(initialBptIn);
  const [exitTxUrl, setExitTxUrl] = useState<string | undefined>();
  const [queryResponse, setQueryResponse] = useState<ExitQueryResponse>(initialQueryResponse);

  const { userPoolBalance, queryExit, exitPool } = useExit(pool);

  const handleAmountChange = (amount: string) => {
    const rawAmount = parseUnits(amount, pool.decimals);
    setBptIn({ rawAmount, displayValue: amount });
    setQueryResponse({ expectedAmountsOut: undefined, minAmountsOut: undefined });
  };

  const handleExitQuery = async () => {
    const { expectedAmountsOut, minAmountsOut } = await queryExit(bptIn.rawAmount);
    setQueryResponse({ expectedAmountsOut, minAmountsOut });
  };

  const handleExitPool = async () => {
    const txUrl = await exitPool();
    setExitTxUrl(txUrl);
    setBptIn(initialBptIn);
  };

  const setMaxAmount = () => {
    setBptIn({
      rawAmount: userPoolBalance || 0n,
      displayValue: Number(formatUnits(userPoolBalance || 0n, pool.decimals)).toFixed(4),
    });
    setQueryResponse({ expectedAmountsOut: undefined, minAmountsOut: undefined });
  };

  return (
    <section>
      <TokenField
        label="BPT In"
        tokenSymbol={pool.symbol}
        value={bptIn.displayValue}
        onAmountChange={handleAmountChange}
        balance={Number(formatUnits(userPoolBalance || 0n, pool.decimals)).toFixed(4)}
        setMaxAmount={setMaxAmount}
      />
      <div className={`grid gap-5 ${queryResponse.expectedAmountsOut ? "grid-cols-2" : "grid-cols-1"}`}>
        <StyledQueryButton onClick={handleExitQuery} isDisabled={bptIn.displayValue === ""}>
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
                <div className="text-end">
                  <div className="font-bold">0.0000</div>
                  <div className="text-sm">0</div>
                </div>
              )}
            </div>
          </div>
        ))}
      </PoolFeedback>
    </section>
  );
};
