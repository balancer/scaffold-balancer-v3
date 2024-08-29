import React, { useEffect, useState } from "react";
import { PoolActionButton, QueryErrorAlert, QueryResponseAlert, TokenField, TransactionReceiptAlert } from ".";
import { PoolActionsProps } from "../PoolActions";
import { BALANCER_ROUTER, InputAmount, PERMIT2, erc20Abi, permit2Abi } from "@balancer/sdk";
import { calculateProportionalAmounts } from "@balancer/sdk";
import { formatUnits, parseUnits } from "viem";
import { useContractEvent, usePublicClient, useWalletClient } from "wagmi";
import abis from "~~/contracts/abis";
import { useAddLiquidity, useTargetFork, useTokens } from "~~/hooks/balancer/";
import { PoolActionReceipt, QueryAddLiquidityResponse, QueryPoolActionError, TokenInfo } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { MaxUint48, MaxUint160, MaxUint256 } from "~~/utils/constants";

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
  const [tokensToApprove, setTokensToApprove] = useState<InputAmount[]>([]);
  const [tokenInputs, setTokenInputs] = useState<InputAmount[]>(initialTokenInputs);
  const [queryResponse, setQueryResponse] = useState<QueryAddLiquidityResponse | null>(null);
  const [sufficientAllowances, setSufficientAllowances] = useState(false);
  const [queryError, setQueryError] = useState<QueryPoolActionError>();
  const [isApproving, setIsApproving] = useState(false);
  const [isQuerying, setIsQuerying] = useState(false);
  const [isAddingLiquidity, setIsAddingLiquidity] = useState(false);
  const [addLiquidityReceipt, setAddLiquidityReceipt] = useState<PoolActionReceipt>(null);
  const [bptOut, setBptOut] = useState<InputAmount>({
    rawAmount: 0n,
    decimals: pool.decimals,
    address: pool.address as `0x${string}`,
  });

  const { tokenAllowances, refetchTokenAllowances } = useTokens(tokenInputs);
  const { queryAddLiquidity, addLiquidity } = useAddLiquidity(pool, tokenInputs);
  const writeTx = useTransactor(); // scaffold hook for tx status toast notifications
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();
  const { chainId } = useTargetFork();

  useEffect(() => {
    // Determine which tokens need to be approved
    async function determineTokensToApprove() {
      if (tokenAllowances) {
        const tokensNeedingApproval = tokenInputs.filter((token, index) => {
          const allowance = tokenAllowances[index] || 0n;
          return allowance < token.rawAmount;
        });
        setTokensToApprove(tokensNeedingApproval);
        // Check if all tokens have sufficient tokenAllowances
        if (tokensNeedingApproval.length > 0) {
          setSufficientAllowances(false);
        } else {
          setSufficientAllowances(true);
        }
      }
    }
    determineTokensToApprove();
  }, [tokenInputs, tokenAllowances]);

  const handleInputChange = (index: number, value: string) => {
    setQueryError(null);
    setQueryResponse(null);
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

  const handleQueryAddLiquidity = async () => {
    setQueryResponse(null);
    setAddLiquidityReceipt(null);
    setIsQuerying(true);
    const response = await queryAddLiquidity(bptOut);
    if (response.error) {
      setQueryError(response.error);
    } else {
      setQueryResponse(response);
    }
    setIsQuerying(false);
  };

  const handleApprove = async () => {
    if (!walletClient) throw new Error("Wallet client not connected!");
    tokensToApprove.forEach(async token => {
      try {
        setIsApproving(true);
        // Max approve canonical Permit2 address to spend account's tokens
        const { request: approveSpenderOnToken } = await publicClient.simulateContract({
          address: token.address,
          abi: erc20Abi,
          functionName: "approve",
          account: walletClient.account,
          args: [PERMIT2[chainId], MaxUint256],
        });
        await writeTx(() => walletClient.writeContract(approveSpenderOnToken), {
          blockConfirmations: 1,
          onBlockConfirmation: () => {
            console.log("Approved permit2 contract to spend max amount of", token.address);
          },
        });
        // Approve Router to spend account's tokens using Permit2.approve(token, spender, amount, deadline)
        const { request: approveSpenderOnPermit2 } = await publicClient.simulateContract({
          address: PERMIT2[chainId],
          abi: permit2Abi,
          functionName: "approve",
          account: walletClient.account,
          args: [token.address, BALANCER_ROUTER[chainId], MaxUint160, MaxUint48],
        });
        await writeTx(() => walletClient.writeContract(approveSpenderOnPermit2), {
          blockConfirmations: 1,
          onBlockConfirmation: () => {
            console.log("Approved router to spend max amount of", token.address);
            refetchTokenAllowances();
            setIsApproving(false);
          },
        });
      } catch (error) {
        console.error("Approval error", error);
        setIsApproving(false);
      }
    });
  };

  const handleAddLiquidity = async () => {
    try {
      setIsAddingLiquidity(true);
      await addLiquidity();
      refetchTokenAllowances();
      refetchTokenBalances();
      refetchPool();
    } catch (e) {
      console.error("error", e);
    } finally {
      setIsAddingLiquidity(false);
    }
  };

  useContractEvent({
    address: pool.address,
    abi: abis.balancer.Pool,
    eventName: "Transfer",
    listener(log: any[]) {
      const data: TokenInfo = {
        symbol: pool.symbol,
        name: pool.name,
        decimals: pool.decimals,
        rawAmount: log[0].args.value,
      };
      setAddLiquidityReceipt({ data: [data], transactionHash: log[0].transactionHash });
    },
  });

  const { expectedBptOut, minBptOut } = queryResponse || {};

  return (
    <section>
      <div className="mb-5">
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
      </div>

      {!expectedBptOut || (expectedBptOut && addLiquidityReceipt) ? (
        <PoolActionButton
          label="Query"
          onClick={handleQueryAddLiquidity}
          isDisabled={isQuerying}
          isFormEmpty={tokenInputs.every(token => token.rawAmount === 0n)}
        />
      ) : !sufficientAllowances ? (
        <PoolActionButton label="Approve" isDisabled={isApproving} onClick={handleApprove} />
      ) : (
        <PoolActionButton label="Add Liquidity" isDisabled={isAddingLiquidity} onClick={handleAddLiquidity} />
      )}

      {addLiquidityReceipt && (
        <TransactionReceiptAlert
          title="Actual BPT Out"
          transactionHash={addLiquidityReceipt.transactionHash}
          data={addLiquidityReceipt.data}
        />
      )}

      {expectedBptOut && minBptOut && (
        <QueryResponseAlert
          title="BPT Out"
          data={[
            {
              type: "Expected",
              description: "Expected BPT Out",
              rawAmount: expectedBptOut.amount,
              decimals: pool.decimals,
            },
            {
              type: "Minimum",
              description: "Minimum BPT Out",
              rawAmount: minBptOut.amount,
              decimals: pool.decimals,
            },
          ]}
        />
      )}

      {queryError && <QueryErrorAlert message={queryError.message} />}
    </section>
  );
};
