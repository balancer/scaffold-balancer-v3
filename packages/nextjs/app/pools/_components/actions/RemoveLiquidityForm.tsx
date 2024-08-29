import { useState } from "react";
import { PoolActionButton, QueryErrorAlert, QueryResponseAlert, TokenField, TransactionReceiptAlert } from ".";
import { PoolActionsProps } from "../PoolActions";
import { BALANCER_ROUTER, RemoveLiquidityBuildCallOutput, VAULT_V3, vaultV3Abi } from "@balancer/sdk";
import { useQueryClient } from "@tanstack/react-query";
import { parseUnits } from "viem";
import { useContractEvent } from "wagmi";
import { useApprove, useQueryRemoveLiquidity, useRemoveLiquidity, useTargetFork } from "~~/hooks/balancer/";
import { PoolActionReceipt, TokenInfo } from "~~/hooks/balancer/types";
import { formatToHuman } from "~~/utils/";

/**
 * 1. Query removing some amount of liquidity from the pool
 * 2. Send transaction to remove liquidity from the pool
 * 3. Display the transaction results to the user
 */
export const RemoveLiquidityForm: React.FC<PoolActionsProps> = ({ pool, refetchPool, refetchTokenBalances }) => {
  const [call, setCall] = useState<RemoveLiquidityBuildCallOutput>();
  const [removeLiquidityReceipt, setRemoveLiquidityReceipt] = useState<PoolActionReceipt>(null);
  const [bptInput, setBptInput] = useState({
    rawAmount: 0n,
    displayValue: "",
  });

  const queryClient = useQueryClient();
  const { chainId } = useTargetFork();
  const { approveSpenderOnToken: approveRouterOnToken } = useApprove(pool.address, BALANCER_ROUTER[chainId]);
  const {
    data: queryResponse,
    isFetching: isQueryFetching,
    error: queryError,
    refetch: refetchQuery,
  } = useQueryRemoveLiquidity("queryRemoveAmount", pool, bptInput.rawAmount, setCall);
  const {
    mutate: removeLiquidity,
    isLoading: isRemoveLiquidityPending,
    error: removeLiquidityError,
  } = useRemoveLiquidity();

  const handleAmountChange = (amount: string) => {
    queryClient.removeQueries(["queryRemoveLiquidity"]);
    setRemoveLiquidityReceipt(null);
    const rawAmount = parseUnits(amount, pool.decimals);
    setBptInput({ rawAmount, displayValue: amount });
  };

  const handleQuery = () => {
    queryClient.removeQueries(["queryRemoveLiquidity"]);
    setRemoveLiquidityReceipt(null);
    refetchQuery();
  };

  const handleRemoveLiquidity = async () => {
    await approveRouterOnToken();

    removeLiquidity(call, {
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
      const data: TokenInfo[] = log[0].args.deltas.map((delta: bigint, idx: number) => ({
        symbol: pool.poolTokens[idx].symbol,
        name: pool.poolTokens[idx].name,
        rawAmount: -delta,
        decimals: pool.poolTokens[idx].decimals,
      }));
      setRemoveLiquidityReceipt({ data, transactionHash: log[0].transactionHash });
    },
  });

  const error = queryError || removeLiquidityError;
  const isFormEmpty = bptInput.displayValue === "";

  return (
    <section>
      <TokenField
        label="BPT In"
        token={{ address: pool.address, symbol: pool.symbol, decimals: pool.decimals }}
        value={bptInput.displayValue}
        onAmountChange={handleAmountChange}
        userBalance={pool.userBalance}
        setMaxAmount={setMaxAmount}
      />

      {!queryResponse || removeLiquidityReceipt || isFormEmpty ? (
        <PoolActionButton label="Query" onClick={handleQuery} isDisabled={isQueryFetching} isFormEmpty={isFormEmpty} />
      ) : (
        <PoolActionButton
          label="Remove Liquidity"
          isDisabled={isRemoveLiquidityPending}
          onClick={handleRemoveLiquidity}
        />
      )}

      {queryResponse && !isFormEmpty && (
        <QueryResponseAlert
          title="Expected Tokens Out"
          data={pool.poolTokens.map((token, index) => ({
            type: token.symbol,
            description: token.name,
            rawAmount: queryResponse.amountsOut[index].amount,
            decimals: token.decimals,
          }))}
        />
      )}

      {removeLiquidityReceipt && (
        <TransactionReceiptAlert
          title="Actual Tokens Out"
          transactionHash={removeLiquidityReceipt.transactionHash}
          data={removeLiquidityReceipt.data}
        />
      )}

      {(error as Error) && <QueryErrorAlert message={(error as Error).message} />}
    </section>
  );
};
