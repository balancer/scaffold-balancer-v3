import React, { useEffect, useState } from "react";
import { PoolActionButton, QueryErrorAlert, QueryResponseAlert, TokenField, TransactionReceiptAlert } from ".";
import { PoolActionsProps } from "../PoolActions";
import { InputAmount } from "@balancer/sdk";
import { formatUnits, parseAbi, parseUnits } from "viem";
import { useContractEvent, usePublicClient, useWalletClient } from "wagmi";
import abis from "~~/contracts/abis";
import { useJoin } from "~~/hooks/balancer/";
import { QueryJoinResponse, QueryPoolActionError } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { formatToHuman } from "~~/utils/formatToHuman";

/**
 * 1. Query the results of join transaction
 * 2. User approves the vault for the tokens used in the join transaction (if necessary)
 * 3. User sends transaction to join the pool
 */
export const JoinForm: React.FC<PoolActionsProps> = ({ pool, refetchPool }) => {
  const initialTokenInputs = pool.poolTokens.map(token => ({
    address: token.address as `0x${string}`,
    decimals: token.decimals,
    rawAmount: 0n,
  }));
  const [tokensToApprove, setTokensToApprove] = useState<InputAmount[]>([]);
  const [tokenInputs, setTokenInputs] = useState<InputAmount[]>(initialTokenInputs);
  const [queryResponse, setQueryResponse] = useState<QueryJoinResponse | null>(null);
  const [sufficientAllowances, setSufficientAllowances] = useState(false);
  const [queryError, setQueryError] = useState<QueryPoolActionError>();
  const [isApproving, setIsApproving] = useState(false);
  const [isQuerying, setIsQuerying] = useState(false);
  const [isJoining, setIsJoining] = useState(false);
  const [joinReceipt, setJoinReceipt] = useState<any>(null);

  const { queryJoin, joinPool, allowances, refetchAllowances, tokenBalances } = useJoin(pool, tokenInputs);
  const writeTx = useTransactor(); // scaffold hook for tx status toast notifications
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();

  useEffect(() => {
    // Determine which tokens need to be approved
    async function determineTokensToApprove() {
      if (allowances) {
        const tokensNeedingApproval = tokenInputs.filter((token, index) => {
          const allowance = BigInt((allowances[index]?.result as string) || "0");
          return allowance < token.rawAmount;
        });
        setTokensToApprove(tokensNeedingApproval);
        // Check if all tokens have sufficient allowances
        if (tokensNeedingApproval.length > 0) {
          setSufficientAllowances(false);
        } else {
          setSufficientAllowances(true);
        }
      }
    }
    determineTokensToApprove();
  }, [tokenInputs, allowances]);

  const handleInputChange = (index: number, value: string) => {
    setQueryError(null);
    setQueryResponse(null);
    setJoinReceipt(null);
    const updatedTokens = tokenInputs.map((token, idx) => {
      if (idx === index) {
        return { ...token, rawAmount: parseUnits(value, token.decimals) };
      }
      return token;
    });
    setTokenInputs(updatedTokens);
  };

  const handleQueryJoin = async () => {
    setQueryResponse(null);
    setJoinReceipt(null);
    setIsQuerying(true);
    const response = await queryJoin();
    if (response.error) {
      setQueryError(response.error);
    } else {
      setQueryResponse(response);
    }
    setIsQuerying(false);
  };

  const handleApprove = async () => {
    if (!walletClient) return;

    tokensToApprove.forEach(async token => {
      try {
        setIsApproving(true);
        const { request } = await publicClient.simulateContract({
          address: token.address,
          abi: parseAbi(["function approve(address spender, uint256 amount) returns (bool)"]),
          functionName: "approve",
          account: walletClient.account,
          args: [pool.vaultAddress, token.rawAmount],
        });

        await writeTx(() => walletClient.writeContract(request), {
          blockConfirmations: 1,
          onBlockConfirmation: () => {
            refetchAllowances();
            setIsApproving(false);
          },
        });
      } catch (error) {
        console.error("Approval error", error);
        setIsApproving(false);
      }
    });
  };

  const handleJoinPool = async () => {
    try {
      setIsJoining(true);
      await joinPool();
      refetchAllowances();
      refetchPool();
    } catch (e) {
      console.error("error", e);
    } finally {
      setIsJoining(false);
    }
  };

  useContractEvent({
    address: pool.address,
    abi: abis.balancer.Pool,
    eventName: "Transfer",
    listener(log: any[]) {
      const bptOut = {
        symbol: pool.symbol,
        name: pool.name,
        decimals: pool.decimals,
        rawAmount: log[0].args.value,
      };

      setJoinReceipt({ bptOut, transactionHash: log[0].transactionHash });
    },
  });

  const { expectedBptOut, minBptOut } = queryResponse || {};

  return (
    <section>
      <div className="mb-5">
        {tokenInputs.map((token, index) => (
          <TokenField
            key={token.address}
            label={index === 0 ? "Tokens In" : undefined}
            tokenSymbol={pool.poolTokens[index].symbol}
            value={
              formatUnits(token.rawAmount, token.decimals) === "0" ? "" : formatUnits(token.rawAmount, token.decimals)
            }
            onAmountChange={value => handleInputChange(index, value)}
            allowance={allowances && formatToHuman((allowances[index].result as bigint) || 0n, token.decimals)}
            balance={tokenBalances && formatToHuman((tokenBalances[index].result as bigint) || 0n, token.decimals)}
          />
        ))}
      </div>

      {!expectedBptOut || (expectedBptOut && joinReceipt) ? (
        <PoolActionButton
          onClick={handleQueryJoin}
          isDisabled={isQuerying}
          isFormEmpty={tokenInputs.every(token => token.rawAmount === 0n)}
        >
          Query
        </PoolActionButton>
      ) : !sufficientAllowances ? (
        <PoolActionButton isDisabled={isApproving} onClick={handleApprove}>
          Approve
        </PoolActionButton>
      ) : (
        <PoolActionButton isDisabled={isJoining} onClick={handleJoinPool}>
          Add Liquidity
        </PoolActionButton>
      )}

      {joinReceipt && (
        <TransactionReceiptAlert
          title="Actual BPT Out"
          transactionHash={joinReceipt.transactionHash}
          data={[joinReceipt.bptOut]}
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
