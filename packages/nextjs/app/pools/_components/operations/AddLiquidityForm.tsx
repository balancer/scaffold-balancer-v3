import React, { useCallback, useState } from "react";
import { ResultsDisplay, TokenField, TransactionButton } from ".";
import { InputAmount, PERMIT2, calculateProportionalAmounts, erc20Abi } from "@balancer/sdk";
import { useQueryClient } from "@tanstack/react-query";
import debounce from "lodash.debounce";
import { formatUnits, parseUnits } from "viem";
import { useContractEvent, useContractRead } from "wagmi";
import { Alert } from "~~/components/common/";
import abis from "~~/contracts/abis";
import { useAddLiquidity, useQueryAddLiquidity, useTargetFork } from "~~/hooks/balancer/";
import { PoolActionsProps, PoolOperationReceipt, TokenAmountDetails } from "~~/hooks/balancer/types";
import { useAllowancesOnTokens, useApproveOnToken } from "~~/hooks/token/";

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
  const [referenceAmount, setReferenceAmount] = useState<InputAmount>(); // only for the proportional add liquidity case
  const [isCalculatingProportional, setIsCalculatingProportional] = useState(false);

  const queryClient = useQueryClient();
  const {
    data: queryResponse,
    isFetching: isQueryFetching,
    error: queryError,
    refetch: refetchQueryAddLiquidity,
  } = useQueryAddLiquidity(pool, tokenInputs, referenceAmount);
  const { tokensToApprove, refetchTokenAllowances } = useAllowancesOnTokens(tokenInputs);
  const {
    mutate: addLiquidity,
    isPending: isAddLiquidityPending,
    error: addLiquidityError,
  } = useAddLiquidity(tokenInputs);

  // Delay update of token inputs so user has time to finish typing numbers longer than 1 digit
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const debouncedSetTokenInputs = useCallback(
    debounce(updatedTokens => {
      setTokenInputs(updatedTokens);
      setIsCalculatingProportional(false);
    }, 1000),
    [],
  );

  const handleInputChange = (index: number, value: string) => {
    queryClient.removeQueries({ queryKey: ["queryAddLiquidity"] });
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

      setIsCalculatingProportional(true);
      const referenceAmount = updatedTokens[index];
      const { tokenAmounts } = calculateProportionalAmounts(poolStateWithBalances, referenceAmount);
      setReferenceAmount(referenceAmount);
      setTokenInputs(updatedTokens);
      debouncedSetTokenInputs(tokenAmounts);
    } else {
      setTokenInputs(updatedTokens);
    }
  };

  const handleQueryAddLiquidity = () => {
    queryClient.removeQueries({ queryKey: ["queryAddLiquidity"] });
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

  const error: Error | null = queryError || addLiquidityError;
  const isFormEmpty = tokenInputs.some(token => token.rawAmount === 0n);

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
        <TransactionButton
          label="Query"
          onClick={handleQueryAddLiquidity}
          isDisabled={isQueryFetching}
          isFormEmpty={isFormEmpty || isCalculatingProportional}
        />
      ) : tokensToApprove.length > 0 ? (
        <ApproveButtons tokens={tokensToApprove} refetchTokenAllowances={refetchTokenAllowances} />
      ) : (
        <TransactionButton label="Add Liquidity" isDisabled={isAddLiquidityPending} onClick={handleAddLiquidity} />
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

      {error && <Alert type="error">{error.message}</Alert>}
    </section>
  );
};

const ApproveButtons = ({
  tokens,
  refetchTokenAllowances,
}: {
  tokens: InputAmount[];
  refetchTokenAllowances: () => void;
}) => {
  const { chainId } = useTargetFork();
  const token = tokens[0];

  const { data: symbol } = useContractRead({
    address: token.address,
    abi: erc20Abi,
    functionName: "symbol",
  });

  const {
    mutateAsync: approve,
    isPending: isApprovePending,
    error: approveError,
  } = useApproveOnToken(token.address, PERMIT2[chainId]);

  const handleApprove = async () => {
    await approve();
    refetchTokenAllowances();
  };

  return (
    <div>
      <TransactionButton label={`Approve ${symbol}`} isDisabled={isApprovePending} onClick={handleApprove} />
      {approveError && <Alert type="error">{approveError.message}</Alert>}
    </div>
  );
};
