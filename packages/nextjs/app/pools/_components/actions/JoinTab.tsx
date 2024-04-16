import React, { useEffect, useState } from "react";
import { PoolActionsProps } from "../PoolActions";
import { PoolActionButton, QueryResults, SuccessNotification, TokenField } from "./";
import { InputAmount } from "@balancer/sdk";
import { formatUnits, parseAbi, parseUnits } from "viem";
import { useAccount, usePublicClient, useWalletClient } from "wagmi";
import { useJoin } from "~~/hooks/balancer/";
import { useTransactor } from "~~/hooks/scaffold-eth";

const initialQueryResponse = {
  expectedBptOut: "0",
  minBptOut: "0",
};

/**
 * 1. Query the results of join transaction
 * 2. User approves the vault for the tokens used in the join transaction (if necessary)
 * 3. User sends transaction to join the pool
 */
export const JoinTab: React.FC<PoolActionsProps> = ({ pool, refetchPool }) => {
  const initialTokenInputs = pool.poolTokens.map(token => ({
    address: token.address as `0x${string}`,
    decimals: token.decimals,
    rawAmount: 0n,
  }));
  const [tokenInputs, setTokenInputs] = useState<InputAmount[]>(initialTokenInputs);
  const [queryResponse, setQueryResponse] = useState(initialQueryResponse);
  const [joinTxUrl, setJoinTxUrl] = useState<string | undefined>();
  const [sufficientAllowances, setSufficientAllowances] = useState(false);
  const [tokensToApprove, setTokensToApprove] = useState<any[]>([]);
  const [isQuerying, setIsQuerying] = useState(false);
  const [isApproving, setIsApproving] = useState(false);
  const [isJoining, setIsJoining] = useState(false);

  const { queryJoin, joinPool, allowances, refetchAllowances, tokenBalances } = useJoin(pool, tokenInputs);
  const writeTx = useTransactor(); // scaffold hook for tx status toast notifications
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();
  const account = useAccount();

  useEffect(() => {
    async function determineTokensToApprove() {
      if (allowances) {
        const tokensNeedingApproval = tokenInputs.filter((token, index) => {
          const allowance = BigInt((allowances[index]?.result as string) || "0");
          return allowance < token.rawAmount; // Check if allowance is less than required amount
        });
        setTokensToApprove(tokensNeedingApproval);
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
    const updatedTokens = tokenInputs.map((token, idx) => {
      if (idx === index) {
        return { ...token, rawAmount: parseUnits(value, token.decimals) };
      }
      return token;
    });
    setTokenInputs(updatedTokens);
    setQueryResponse(initialQueryResponse);
  };

  const handleQueryJoin = async () => {
    try {
      setIsQuerying(true);
      const queryResponse = await queryJoin(tokenInputs);
      if (!queryResponse) throw new Error("Query response is undefined");
      setQueryResponse(queryResponse);
    } catch (error) {
      console.error("Query error", error);
    } finally {
      setIsQuerying(false);
    }
  };

  const handleJoinPool = async () => {
    try {
      setIsJoining(true);
      const txUrl = await joinPool();
      setJoinTxUrl(txUrl);
      setTokenInputs(initialTokenInputs);
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
            allowance={
              allowances && Number(formatUnits((allowances[index].result as bigint) || 0n, token.decimals)).toFixed(4)
            }
            balance={
              tokenBalances &&
              Number(formatUnits((tokenBalances[index].result as bigint) || 0n, token.decimals)).toFixed(4)
            }
          />
        ))}
      </div>

      {joinTxUrl && queryResponse.expectedBptOut !== "0" ? (
        <SuccessNotification transactionUrl={joinTxUrl} />
      ) : queryResponse.expectedBptOut === "0" ? (
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

      {queryResponse.expectedBptOut !== "0" && (
        <QueryResults title="BPT Out">
          <div className="flex flex-wrap justify-between mb-3">
            <div className="font-bold">Expected</div>
            <div className="text-end">
              <div className="font-bold">
                {Number(formatUnits(BigInt(queryResponse.expectedBptOut), pool.decimals)).toFixed(4)}
              </div>
              <div className="text-sm">{queryResponse.expectedBptOut}</div>
            </div>
          </div>
          <div className="flex flex-wrap justify-between">
            <div className="font-bold">Minimum</div>
            <div className="text-end">
              <div className="font-bold">
                {Number(formatUnits(BigInt(queryResponse.minBptOut), pool.decimals)).toFixed(4)}
              </div>
              <div className="text-sm">{queryResponse.minBptOut}</div>
            </div>
          </div>
        </QueryResults>
      )}
    </section>
  );
};
