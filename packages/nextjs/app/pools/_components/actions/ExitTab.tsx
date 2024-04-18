import { useState } from "react";
import { PoolActionsProps } from "../PoolActions";
import { ActionSuccessAlert, PoolActionButton, QueryErrorAlert, QueryResultsWrapper, TokenField } from "./";
import { TokenAmount } from "@balancer/sdk";
import { formatUnits, parseUnits } from "viem";
import { useExit } from "~~/hooks/balancer/";

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
export const ExitTab: React.FC<PoolActionsProps> = ({ pool, refetchPool }) => {
  const [bptIn, setBptIn] = useState(initialBptIn);
  const [exitTxUrl, setExitTxUrl] = useState<string | undefined>();
  const [queryResponse, setQueryResponse] = useState<ExitQueryResponse>(initialQueryResponse);
  const [isExiting, setIsExiting] = useState(false);
  const [isQuerying, setIsQuerying] = useState(false);
  const [queryErrorMsg, setQueryErrorMsg] = useState<string | null>();

  const { queryExit, exitPool } = useExit(pool);

  const handleAmountChange = (amount: string) => {
    setQueryErrorMsg(null);
    const rawAmount = parseUnits(amount, pool.decimals);
    setBptIn({ rawAmount, displayValue: amount });
    setQueryResponse({ expectedAmountsOut: undefined, minAmountsOut: undefined });
  };

  const handleQueryExit = async () => {
    setIsQuerying(true);
    const response = await queryExit(bptIn.rawAmount);
    if (response.error) {
      setQueryErrorMsg(response.error.message);
    } else {
      const { expectedAmountsOut, minAmountsOut } = response;
      setQueryResponse({ expectedAmountsOut, minAmountsOut });
    }
    setIsQuerying(false);
  };

  const handleExitPool = async () => {
    try {
      setIsExiting(true);
      const txUrl = await exitPool();
      setExitTxUrl(txUrl);
      setBptIn(initialBptIn);
      refetchPool();
    } catch (error) {
      console.error("Error exiting pool", error);
    } finally {
      setIsExiting(false);
    }
  };

  const setMaxAmount = () => {
    setBptIn({
      rawAmount: pool.userBalance,
      displayValue: Number(formatUnits(pool.userBalance || 0n, pool.decimals)).toFixed(4),
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
        balance={Number(formatUnits(pool.userBalance, pool.decimals)).toFixed(4)}
        setMaxAmount={setMaxAmount}
      />

      {exitTxUrl && queryResponse.expectedAmountsOut ? (
        <ActionSuccessAlert transactionUrl={exitTxUrl} />
      ) : !queryResponse.expectedAmountsOut ? (
        <PoolActionButton onClick={handleQueryExit} isDisabled={isQuerying} isFormEmpty={bptIn.displayValue === ""}>
          Query
        </PoolActionButton>
      ) : (
        <PoolActionButton isDisabled={isExiting} onClick={handleExitPool}>
          Exit
        </PoolActionButton>
      )}

      {queryResponse.expectedAmountsOut && (
        <QueryResultsWrapper title="Expected Tokens Out">
          {pool.poolTokens.map((token, index) => (
            <div key={token.address} className={`${index === 0 ? "mb-3" : ""} flex justify-between items-center`}>
              <div>
                <div className="font-bold">{token.symbol}</div>
                <div className="text-sm">{token.name}</div>
              </div>
              <div>
                {queryResponse.expectedAmountsOut && (
                  <div>
                    <div className="font-bold text-end">{queryResponse.expectedAmountsOut[index].toSignificant(4)}</div>
                    <div className="text-sm">{queryResponse.expectedAmountsOut[index].amount.toString()}</div>
                  </div>
                )}
              </div>
            </div>
          ))}
        </QueryResultsWrapper>
      )}

      {queryErrorMsg && <QueryErrorAlert message={queryErrorMsg} />}
    </section>
  );
};
