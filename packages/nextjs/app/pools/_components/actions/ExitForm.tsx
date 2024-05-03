import { useState } from "react";
import { ActionSuccessAlert, PoolActionButton, QueryErrorAlert, QueryResultsWrapper, TokenField } from ".";
import { PoolActionsProps } from "../PoolActions";
import { parseUnits } from "viem";
import { useExit } from "~~/hooks/balancer/";
import { QueryExitResponse, QueryPoolActionError } from "~~/hooks/balancer/types";
import { formatToHuman } from "~~/utils/formatToHuman";

const initialBptIn = {
  rawAmount: 0n, // needed for precision to allow max exit
  displayValue: "", // shown in UI
};

/**
 * 1. Query the results of exit transaction
 * 2. User sends transaction to exit the pool
 */
export const ExitForm: React.FC<PoolActionsProps> = ({ pool, refetchPool }) => {
  const [queryResponse, setQueryResponse] = useState<QueryExitResponse | null>(null);
  const [queryError, setQueryError] = useState<QueryPoolActionError>(null);
  const [exitTxUrl, setExitTxUrl] = useState<string | null>(null);
  const [isQuerying, setIsQuerying] = useState(false);
  const [isExiting, setIsExiting] = useState(false);
  const [bptIn, setBptIn] = useState(initialBptIn);
  const { queryExit, exitPool } = useExit(pool);

  const handleAmountChange = (amount: string) => {
    setQueryError(null);
    const rawAmount = parseUnits(amount, pool.decimals);
    setBptIn({ rawAmount, displayValue: amount });
    setQueryResponse(null);
  };

  const handleQueryExit = async () => {
    setIsQuerying(true);
    const response = await queryExit(bptIn.rawAmount);
    if (response.error) {
      setQueryError(response.error);
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
      displayValue: formatToHuman(pool.userBalance || 0n, pool.decimals),
    });
    setQueryResponse(null);
  };

  const { expectedAmountsOut } = queryResponse ?? {};

  return (
    <section>
      <TokenField
        label="BPT In"
        tokenSymbol={pool.symbol}
        value={bptIn.displayValue}
        onAmountChange={handleAmountChange}
        balance={formatToHuman(pool.userBalance, pool.decimals)}
        setMaxAmount={setMaxAmount}
      />

      {exitTxUrl && expectedAmountsOut ? (
        <ActionSuccessAlert transactionHash={exitTxUrl} rows={[{ title: "", rawAmount: 0n, decimals: 18 }]} />
      ) : !expectedAmountsOut ? (
        <PoolActionButton onClick={handleQueryExit} isDisabled={isQuerying} isFormEmpty={bptIn.displayValue === ""}>
          Query
        </PoolActionButton>
      ) : (
        <PoolActionButton isDisabled={isExiting} onClick={handleExitPool}>
          Exit
        </PoolActionButton>
      )}

      {expectedAmountsOut && (
        <QueryResultsWrapper title="Expected Tokens Out">
          {pool.poolTokens.map((token, index) => (
            <div key={token.address} className={`${index === 0 ? "mb-3" : ""} flex justify-between items-center`}>
              <div>
                <div className="font-bold">{token.symbol}</div>
                <div className="text-sm">{token.name}</div>
              </div>
              <div>
                {expectedAmountsOut && (
                  <div>
                    <div className="font-bold text-end">{expectedAmountsOut[index].toSignificant(4)}</div>
                    <div className="text-sm">{expectedAmountsOut[index].amount.toString()}</div>
                  </div>
                )}
              </div>
            </div>
          ))}
        </QueryResultsWrapper>
      )}

      {queryError && <QueryErrorAlert message={queryError.message} />}
    </section>
  );
};
