import React, { useState } from "react";
import { PoolActionButton, ResultsDisplay, TokenField } from ".";
import { InputAmount, calculateProportionalAmounts } from "@balancer/sdk";
import { useQueryClient } from "@tanstack/react-query";
import { formatUnits, parseUnits } from "viem";
import { useContractEvent } from "wagmi";
import { Alert } from "~~/components/common/";
import abis from "~~/contracts/abis";
import { useAddLiquidity, useApproveTokens, useQueryAddLiquidity, useReadTokens } from "~~/hooks/balancer/";
import { PoolActionsProps, PoolOperationReceipt, TokenAmountDetails } from "~~/hooks/balancer/types";

/**
 * 1. Query adding some amount of liquidity to the pool
 * 2. Approve the Balancer vault to spend the tokens to be used in the transaction (if necessary)
 * 3. Send transaction to add liquidity to the pool
 * 4. Display the transaction results to the user
 */
export const AddLiquidityForm: React.FC<PoolActionsProps> = ({
  pool,
  refetchPool,
  tokenBalances,
  refetchTokenBalances,
}) => {
  const initialTokenInputs = pool.poolTokens.map(token => ({
    address: token.address as `0x${string}`,
    decimals: token.decimals,
    rawAmount: 0n,
  }));
  const [tokenInputs, setTokenInputs] = useState<InputAmount[]>(initialTokenInputs);
  const [addLiquidityReceipt, setAddLiquidityReceipt] = useState<PoolOperationReceipt>(null);
  const [bptOut, setBptOut] = useState<InputAmount>(); // only for the proportional add liquidity case

  const {
    data: queryResponse,
    isFetching: isQueryFetching,
    error: queryError,
    refetch: refetchQueryAddLiquidity,
  } = useQueryAddLiquidity(pool, tokenInputs, bptOut);
  const { sufficientAllowances, isApproving, approveTokens } = useApproveTokens(tokenInputs);
  const { mutate: addLiquidity, isLoading: isAddLiquidityPending, error: addLiquidityError } = useAddLiquidity();
  const { refetchTokenAllowances } = useReadTokens(tokenInputs);
  const queryClient = useQueryClient();

  const handleInputChange = (index: number, value: string) => {
    queryClient.removeQueries(["queryAddLiquidity"]);
    setAddLiquidityReceipt(null);
    const updatedTokens = tokenInputs.map((token, idx) => {
      if (idx === index) {
        return { ...token, rawAmount: parseUnits(value, token.decimals) };
      }
      return token;
    });

    if (pool.poolConfig?.liquidityManagement.disableUnbalancedLiquidity) {
      // Read pool supply and token balances on-chain
      const poolStateWithBalances = {
        address: pool.address as `0x${string}`,
        totalShares: formatUnits(pool.totalSupply, pool.decimals) as `${number}`,
        tokens: pool.poolTokens.map(token => ({
          address: token.address as `0x${string}`,
          decimals: token.decimals,
          balance: formatUnits(token.balance, token.decimals) as `${number}`,
        })),
      };
      const referenceAmount = updatedTokens[index];
      const { bptAmount, tokenAmounts } = calculateProportionalAmounts(poolStateWithBalances, referenceAmount);
      setBptOut(bptAmount);
      setTokenInputs(tokenAmounts);
    } else {
      setTokenInputs(updatedTokens);
    }
  };

  const handleQueryAddLiquidity = () => {
    queryClient.removeQueries(["queryAddLiquidity"]);
    refetchQueryAddLiquidity();
    setAddLiquidityReceipt(null);
  };

  const handleAddLiquidity = () => {
    addLiquidity(queryResponse, {
      onSuccess: () => {
        refetchTokenAllowances();
        refetchTokenBalances();
        refetchPool();
      },
    });
  };

  // Listen for Transfer events to update the UI with the actual BPT out amount
  useContractEvent({
    address: pool.address,
    abi: abis.balancer.Pool,
    eventName: "Transfer",
    listener(log: any[]) {
      const data: TokenAmountDetails = {
        symbol: pool.symbol,
        name: pool.name,
        decimals: pool.decimals,
        rawAmount: log[0].args.value,
      };
      setAddLiquidityReceipt({ data: [data], transactionHash: log[0].transactionHash });
    },
  });

  const error = queryError || addLiquidityError;
  const isFormEmpty = tokenInputs.every(token => token.rawAmount === 0n);

  return (
    <section className="flex flex-col gap-5">
      {tokenInputs.map((token, index) => {
        const humanInputAmount = formatUnits(token.rawAmount, token.decimals);
        return (
          <TokenField
            key={token.address}
            label={index === 0 ? "Tokens In" : undefined}
            token={pool.poolTokens[index]}
            userBalance={tokenBalances[token.address]}
            value={humanInputAmount != "0" ? humanInputAmount : ""}
            onAmountChange={value => handleInputChange(index, value)}
          />
        );
      })}

      {!queryResponse || addLiquidityReceipt || isFormEmpty ? (
        <PoolActionButton
          label="Query"
          onClick={handleQueryAddLiquidity}
          isDisabled={isQueryFetching}
          isFormEmpty={isFormEmpty}
        />
      ) : !sufficientAllowances ? (
        <PoolActionButton label="Approve" isDisabled={isApproving} onClick={approveTokens} />
      ) : (
        <PoolActionButton label="Add Liquidity" isDisabled={isAddLiquidityPending} onClick={handleAddLiquidity} />
      )}

      {queryResponse && (
        <ResultsDisplay
          label="Expected BPT Out"
          data={[
            {
              symbol: pool.symbol,
              name: pool.name,
              rawAmount: queryResponse.bptOut.amount,
              decimals: pool.decimals,
            },
          ]}
        />
      )}

      {addLiquidityReceipt && (
        <ResultsDisplay
          label="Actual BPT Out"
          transactionHash={addLiquidityReceipt.transactionHash}
          data={addLiquidityReceipt.data}
        />
      )}

      {(error as Error) && <Alert type="error">{(error as Error).message}</Alert>}
    </section>
  );
};
