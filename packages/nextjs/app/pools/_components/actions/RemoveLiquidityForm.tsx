import { useState } from "react";
import { PoolActionButton, QueryErrorAlert, QueryResponseAlert, TokenField, TransactionReceiptAlert } from ".";
import { PoolActionsProps } from "../PoolActions";
import { BALANCER_ROUTER, VAULT_V3, vaultV3Abi } from "@balancer/sdk";
import { parseUnits } from "viem";
import { useContractEvent } from "wagmi";
import { useApprove, useRemoveLiquidity, useTargetFork } from "~~/hooks/balancer/";
import {
  PoolActionReceipt,
  QueryPoolActionError,
  QueryRemoveLiquidityResponse,
  TokenInfo,
} from "~~/hooks/balancer/types";
import { formatToHuman } from "~~/utils/formatToHuman";

/**
 * 1. Query removing some amount of liquidity from the pool
 * 2. Send transaction to remove liquidity from the pool
 * 3. Display the transaction results to the user
 */
export const RemoveLiquidityForm: React.FC<PoolActionsProps> = ({ pool, refetchPool }) => {
  const [queryResponse, setQueryResponse] = useState<QueryRemoveLiquidityResponse | null>(null);
  const [queryError, setQueryError] = useState<QueryPoolActionError>(null);
  const [isQuerying, setIsQuerying] = useState(false);
  const [isRemovingLiquidity, setIsRemovingLiquidity] = useState(false);
  const [removeLiquidityReceipt, setRemoveLiquidityReceipt] = useState<PoolActionReceipt>(null);
  const [bptIn, setBptIn] = useState({
    rawAmount: 0n,
    displayValue: "",
  });

  const { queryRemoveLiquidity, removeLiquidity } = useRemoveLiquidity(pool);
  const { chainId } = useTargetFork();
  const { approveSpenderOnToken: approveRouterOnToken } = useApprove(pool.address, BALANCER_ROUTER[chainId]);

  const handleAmountChange = (amount: string) => {
    setQueryError(null);
    setRemoveLiquidityReceipt(null);
    const rawAmount = parseUnits(amount, pool.decimals);
    setBptIn({ rawAmount, displayValue: amount });
    setQueryResponse(null);
  };

  const handleQuery = async () => {
    setQueryError(null);
    setRemoveLiquidityReceipt(null);
    setIsQuerying(true);
    const response = await queryRemoveLiquidity(bptIn.rawAmount);
    if (response.error) {
      setQueryError(response.error);
    } else {
      const { expectedAmountsOut, minAmountsOut } = response;
      setQueryResponse({ expectedAmountsOut, minAmountsOut });
    }
    setIsQuerying(false);
  };

  const handleRemoveLiquidity = async () => {
    try {
      setIsRemovingLiquidity(true);
      // Before removing liquidity, must approve Router to spend account's BPT
      await approveRouterOnToken();
      await removeLiquidity();
      refetchPool();
    } catch (error) {
      console.error("Error removing liquidity", error);
    } finally {
      setIsRemovingLiquidity(false);
    }
  };

  const setMaxAmount = () => {
    setBptIn({
      rawAmount: pool.userBalance,
      displayValue: formatToHuman(pool.userBalance || 0n, pool.decimals),
    });
    setQueryResponse(null);
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

      {!expectedAmountsOut || (expectedAmountsOut && removeLiquidityReceipt) ? (
        <PoolActionButton onClick={handleQuery} isDisabled={isQuerying} isFormEmpty={bptIn.displayValue === ""}>
          Query
        </PoolActionButton>
      ) : (
        <PoolActionButton isDisabled={isRemovingLiquidity} onClick={handleRemoveLiquidity}>
          Remove Liquidity
        </PoolActionButton>
      )}

      {removeLiquidityReceipt && (
        <TransactionReceiptAlert
          title="Actual Tokens Out"
          transactionHash={removeLiquidityReceipt.transactionHash}
          data={removeLiquidityReceipt.data}
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
