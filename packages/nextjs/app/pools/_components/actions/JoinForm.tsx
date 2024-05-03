import React, { useEffect, useState } from "react";
import { ActionSuccessAlert, PoolActionButton, QueryErrorAlert, QueryResultsWrapper, TokenField } from ".";
import { PoolActionsProps } from "../PoolActions";
import { InputAmount } from "@balancer/sdk";
import { formatUnits, parseAbi, parseUnits } from "viem";
import { useAccount, usePublicClient, useWalletClient } from "wagmi";
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
  const [tokensToApprove, setTokensToApprove] = useState<InputAmount[]>([]);
  const [tokenInputs, setTokenInputs] = useState<InputAmount[]>(
    pool.poolTokens.map(token => ({
      address: token.address as `0x${string}`,
      decimals: token.decimals,
      rawAmount: 0n,
    })),
  );
  const [queryResponse, setQueryResponse] = useState<QueryJoinResponse | null>(null);
  const [sufficientAllowances, setSufficientAllowances] = useState(false);
  const [queryError, setQueryError] = useState<QueryPoolActionError>();
  const [joinTxUrl, setJoinTxUrl] = useState<string | null>(null);
  const [isApproving, setIsApproving] = useState(false);
  const [isQuerying, setIsQuerying] = useState(false);
  const [isJoining, setIsJoining] = useState(false);

  const { queryJoin, joinPool, allowances, refetchAllowances, tokenBalances } = useJoin(pool, tokenInputs);
  const writeTx = useTransactor(); // scaffold hook for tx status toast notifications
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();
  const account = useAccount();

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
    const updatedTokens = tokenInputs.map((token, idx) => {
      if (idx === index) {
        return { ...token, rawAmount: parseUnits(value, token.decimals) };
      }
      return token;
    });
    setTokenInputs(updatedTokens);
    setQueryResponse(null);
  };

  const handleQueryJoin = async () => {
    setIsQuerying(true);
    const response = await queryJoin();
    if (response.error) {
      setQueryError(response.error);
    } else {
      setQueryResponse(response);
    }
    setIsQuerying(false);
  };

  const handleJoinPool = async () => {
    try {
      setIsJoining(true);
      const txUrl = await joinPool();
      setJoinTxUrl(txUrl);
      refetchAllowances();
      refetchPool();
    } catch (e) {
      console.error("error", e);
    } finally {
      setIsJoining(false);
    }
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
          account: account.address,
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

      {joinTxUrl && expectedBptOut ? (
        <ActionSuccessAlert transactionHash={joinTxUrl} rows={[{ title: "", rawAmount: 0n, decimals: 18 }]} />
      ) : !expectedBptOut ? (
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

      {expectedBptOut && minBptOut && (
        <QueryResultsWrapper title="BPT Out">
          <div className="flex flex-wrap justify-between mb-3">
            <div className="font-bold">Expected</div>
            <div className="text-end">
              <div className="font-bold">{formatToHuman(BigInt(expectedBptOut.amount), pool.decimals)}</div>
              <div className="text-sm">{expectedBptOut.amount.toString()}</div>
            </div>
          </div>
          <div className="flex flex-wrap justify-between">
            <div className="font-bold">Minimum</div>
            <div className="text-end">
              <div className="font-bold">{formatToHuman(BigInt(minBptOut.amount), pool.decimals)}</div>
              <div className="text-sm">{minBptOut.amount.toString()}</div>
            </div>
          </div>
        </QueryResultsWrapper>
      )}

      {queryError && <QueryErrorAlert message={queryError.message} />}
    </section>
  );
};
