import { useState } from "react";
import { ActionSuccessAlert, PoolActionButton, QueryErrorAlert, QueryResultsWrapper, TokenField } from ".";
import { PoolActionsProps } from "../PoolActions";
import { parseUnits } from "viem";
import { useContractEvent } from "wagmi";
import abis from "~~/contracts/abis";
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
  const [isQuerying, setIsQuerying] = useState(false);
  const [isExiting, setIsExiting] = useState(false);
  const [bptIn, setBptIn] = useState(initialBptIn);
  const [tokensOut, setTokensOut] = useState<any>(null);
  const [poolEvent, setPoolEvent] = useState<any>(null);
  const [transactionHash, setTransactionHash] = useState<string | null>(null);

  const { queryExit, exitPool } = useExit(pool);

  const handleAmountChange = (amount: string) => {
    setQueryError(null);
    setTokensOut(null);
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
      await exitPool();
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

  useContractEvent({
    address: pool.address,
    abi: abis.balancer.Pool,
    eventName: "Transfer",
    listener(log: any[]) {
      console.log("Pool event", log);
      const result = {
        bptInAmount: log[0].args.value,
        transactionHash: log[0].transactionHash,
      };
      setPoolEvent(result);
      setTransactionHash(log[0].transactionHash);
    },
  });

  useContractEvent({
    address: pool.vaultAddress,
    abi: abis.balancer.Vault,
    eventName: "PoolBalanceChanged",
    listener(log: any[]) {
      const tokensOut = log[0].args.deltas.map((delta: bigint, idx: number) => ({
        symbol: pool.poolTokens[idx].symbol,
        name: pool.poolTokens[idx].name,
        rawAmount: -delta,
        decimals: pool.poolTokens[idx].decimals,
      }));
      setTokensOut(tokensOut);
    },
  });

  console.log("tokensOut", tokensOut);

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

      {!expectedAmountsOut ? (
        <PoolActionButton onClick={handleQueryExit} isDisabled={isQuerying} isFormEmpty={bptIn.displayValue === ""}>
          Query
        </PoolActionButton>
      ) : (
        <PoolActionButton isDisabled={isExiting} onClick={handleExitPool}>
          Exit
        </PoolActionButton>
      )}

      {transactionHash && tokensOut && (
        <ActionSuccessAlert title="Actual Tokens Out" transactionHash={poolEvent.transactionHash} rows={tokensOut} />
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
