import { useState } from "react";
import { ResultsDisplay, TokenField, TransactionButton } from ".";
import { BALANCER_ROUTER, VAULT_V3, vaultV3Abi } from "@balancer/sdk";
import { useQueryClient } from "@tanstack/react-query";
import { parseUnits } from "viem";
import { useContractEvent } from "wagmi";
import { Alert } from "~~/components/common/";
import { useQueryRemoveLiquidity, useRemoveLiquidity, useTargetFork } from "~~/hooks/balancer/";
import { PoolActionsProps, PoolOperationReceipt, TokenAmountDetails } from "~~/hooks/balancer/types";
import { useAllowanceOnToken, useApproveOnToken } from "~~/hooks/token";
import { formatToHuman } from "~~/utils/";

/**
 * 1. Query removing some amount of liquidity from the pool
 * 2. Send transaction to remove liquidity from the pool
 * 3. Display the transaction results to the user
 */
export const RemoveLiquidityForm: React.FC<PoolActionsProps> = ({ pool, refetchPool, refetchTokenBalances }) => {
  const [removeLiquidityReceipt, setRemoveLiquidityReceipt] = useState<PoolOperationReceipt>(null);
  const [bptInput, setBptInput] = useState({
    rawAmount: 0n,
    displayValue: "",
  });

  const queryClient = useQueryClient();
  const { chainId } = useTargetFork();
  const {
    data: queryResponse,
    isFetching: isQueryFetching,
    error: queryError,
    refetch: refetchQuery,
  } = useQueryRemoveLiquidity("queryRemoveAmount", pool, bptInput.rawAmount);
  const { data: allowance, refetch: refetchAllowance } = useAllowanceOnToken(pool.address, BALANCER_ROUTER[chainId]);
  const {
    mutate: approveRouter,
    isPending: isApprovePending,
    error: approveError,
  } = useApproveOnToken(pool.address, BALANCER_ROUTER[chainId]);
  const {
    mutate: removeLiquidity,
    isPending: isRemoveLiquidityPending,
    error: removeLiquidityError,
  } = useRemoveLiquidity();

  const handleAmountChange = (amount: string) => {
    queryClient.removeQueries({ queryKey: ["queryRemoveLiquidity"] });
    setRemoveLiquidityReceipt(null);
    const rawAmount = parseUnits(amount, pool.decimals);
    setBptInput({ rawAmount, displayValue: amount });
  };

  const handleQuery = () => {
    queryClient.removeQueries({ queryKey: ["queryRemoveLiquidity"] });
    setRemoveLiquidityReceipt(null);
    refetchQuery();
  };

  const handleApprove = () => {
    approveRouter(undefined, {
      onSuccess: () => {
        refetchAllowance();
      },
    });
  };

  const handleRemoveLiquidity = () => {
    removeLiquidity(queryResponse, {
      onSuccess: () => {
        refetchPool();
        refetchTokenBalances();
      },
    });
  };

  const setMaxAmount = () => {
    setBptInput({
      rawAmount: pool.userBalance,
      displayValue: formatToHuman(pool.userBalance || 0n, pool.decimals),
    });
  };

  useContractEvent({
    address: VAULT_V3[chainId],
    abi: vaultV3Abi,
    eventName: "PoolBalanceChanged",
    listener(log: any[]) {
      const data: TokenAmountDetails[] = log[0].args.deltas.map((delta: bigint, idx: number) => ({
        symbol: pool.poolTokens[idx].symbol,
        name: pool.poolTokens[idx].name,
        rawAmount: -delta,
        decimals: pool.poolTokens[idx].decimals,
      }));
      setRemoveLiquidityReceipt({ data, transactionHash: log[0].transactionHash });
    },
  });

  const error: Error | null = queryError || removeLiquidityError || approveError;
  const isFormEmpty = bptInput.displayValue === "";
  const isSufficientAllowance = allowance !== undefined && allowance >= bptInput.rawAmount;

  return (
    <section className="flex flex-col gap-5">
      <TokenField
        label="BPT In"
        token={{ address: pool.address, symbol: pool.symbol, decimals: pool.decimals }}
        value={bptInput.displayValue}
        onAmountChange={handleAmountChange}
        userBalance={pool.userBalance}
        setMaxAmount={setMaxAmount}
      />

      {!queryResponse || removeLiquidityReceipt || isFormEmpty ? (
        <TransactionButton label="Query" onClick={handleQuery} isDisabled={isQueryFetching} isFormEmpty={isFormEmpty} />
      ) : !isSufficientAllowance ? (
        <TransactionButton label={`Approve ${pool.symbol}`} isDisabled={isApprovePending} onClick={handleApprove} />
      ) : (
        <TransactionButton
          label="Remove Liquidity"
          isDisabled={isRemoveLiquidityPending}
          onClick={handleRemoveLiquidity}
        />
      )}

      {queryResponse && !isFormEmpty && (
        <ResultsDisplay
          label="Expected Tokens Out"
          data={pool.poolTokens.map((token, index) => ({
            symbol: token.symbol,
            name: token.name,
            rawAmount: queryResponse.amountsOut[index].amount,
            decimals: token.decimals,
          }))}
        />
      )}

      {removeLiquidityReceipt && (
        <ResultsDisplay
          label="Actual Tokens Out"
          transactionHash={removeLiquidityReceipt.transactionHash}
          data={removeLiquidityReceipt.data}
        />
      )}

      {error && <Alert type="error">{error.message}</Alert>}
    </section>
  );
};
