import { useState } from "react";
import { PoolActionButton, QueryErrorAlert, QueryResponseAlert, TokenField, TransactionReceiptAlert } from ".";
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
  const [exitReceipt, setExitReceipt] = useState<any>(null);
  // const [poolEvent, setPoolEvent] = useState<any>(null);

  const { queryExit, exitPool } = useExit(pool);

  const handleAmountChange = (amount: string) => {
    setQueryError(null);
    setExitReceipt(null);
    const rawAmount = parseUnits(amount, pool.decimals);
    setBptIn({ rawAmount, displayValue: amount });
    setQueryResponse(null);
  };

  const handleQueryExit = async () => {
    setQueryError(null);
    setExitReceipt(null);
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

  // useContractEvent({
  //   address: pool.address,
  //   abi: abis.balancer.Pool,
  //   eventName: "Transfer",
  //   listener(log: any[]) {
  //     console.log("Pool event", log);
  //     const result = {
  //       bptInAmount: log[0].args.value,
  //       transactionHash: log[0].transactionHash,
  //     };
  //     setPoolEvent(result);
  //     setTransactionHash(log[0].transactionHash);
  //   },
  // });

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
      setExitReceipt({ tokensOut, transactionHash: log[0].transactionHash });
    },
  });

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

      {!expectedAmountsOut || (expectedAmountsOut && exitReceipt) ? (
        <PoolActionButton onClick={handleQueryExit} isDisabled={isQuerying} isFormEmpty={bptIn.displayValue === ""}>
          Query
        </PoolActionButton>
      ) : (
        <PoolActionButton isDisabled={isExiting} onClick={handleExitPool}>
          Exit
        </PoolActionButton>
      )}

      {exitReceipt && (
        <TransactionReceiptAlert
          title="Actual Tokens Out"
          transactionHash={exitReceipt.transactionHash}
          data={exitReceipt.tokensOut}
        />
      )}

      {expectedAmountsOut && (
        <QueryResponseAlert
          title="Expected Tokens Out"
          data={pool.poolTokens.map((token, index) => ({
            type: token.symbol,
            description: token.name,
            rawAmount: expectedAmountsOut[index].amount,
            decimals: token.decimals,
          }))}
        />
      )}

      {queryError && <QueryErrorAlert message={queryError.message} />}
    </section>
  );
};
