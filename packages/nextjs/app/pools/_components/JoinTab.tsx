import React, { useEffect, useState } from "react";
import { InputAmount } from "@balancer/sdk";
import { formatUnits, parseAbi, parseUnits } from "viem";
import { useAccount, useContractReads, usePublicClient, useWalletClient } from "wagmi";
import { PoolFeedback, TokenField } from "~~/app/pools/_components";
import { StyledQueryButton, StyledTxButton } from "~~/components/common";
import { useJoin } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";
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
export const JoinTab = ({ pool }: { pool: Pool }) => {
  const initialTokenInputs = pool.poolTokens.map(token => ({
    address: token.address as `0x${string}`,
    decimals: token.decimals,
    rawAmount: 0n,
  }));
  const [tokenInputs, setTokenInputs] = useState<InputAmount[]>(initialTokenInputs);
  const [queryResponse, setQueryResponse] = useState(initialQueryResponse);
  const [joinTxUrl, setJoinTxUrl] = useState<string | undefined>();
  const [sufficientAllowances, setSufficientAllowances] = useState(false);
  const [isApproving, setIsApproving] = useState(false); // Flag to indicate if approval process is ongoing
  const [tokensToApprove, setTokensToApprove] = useState<any[]>([]);

  const { queryJoin, joinPool } = useJoin(pool);
  const account = useAccount();

  const { data: allowances, refetch: refetchAllowances } = useContractReads({
    contracts: tokenInputs.map(token => ({
      address: token.address,
      abi: parseAbi(["function allowance(address owner, address spender) returns (uint256)"]),
      functionName: "allowance",
      args: [account.address as string, pool.vaultAddress],
    })),
  });
  console.log("allowances", allowances);
  const { data: balances } = useContractReads({
    contracts: tokenInputs.map(token => ({
      address: token.address,
      abi: parseAbi(["function balanceOf(address owner) returns (uint256)"]),
      functionName: "balanceOf",
      args: [account.address as string],
    })),
  });

  const writeTx = useTransactor(); // scaffold hook for tx status toast notifications

  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();

  useEffect(() => {
    async function checkAndPrepareApprovals() {
      if (allowances) {
        const tokensNeedingApproval = tokenInputs.filter((token, index) => {
          const allowance = BigInt((allowances[index]?.result as string) || "0");
          return allowance < token.rawAmount; // Check if allowance is less than required amount
        });
        setTokensToApprove(tokensNeedingApproval);
        console.log("tokensNeedingApproval.length", tokensNeedingApproval.length);
        if (tokensNeedingApproval.length > 0) {
          setSufficientAllowances(false);
        } else {
          setSufficientAllowances(true);
        }
      }
    }

    checkAndPrepareApprovals();
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
    const queryResponse = await queryJoin(tokenInputs);
    setQueryResponse(queryResponse);
  };

  const handleJoinPool = async () => {
    try {
      const txUrl = await joinPool();
      setJoinTxUrl(txUrl);
      setTokenInputs(initialTokenInputs);
    } catch (e) {
      console.error("error", e);
    }
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
              balances && Number(formatUnits((balances[index].result as bigint) || 0n, token.decimals)).toFixed(4)
            }
          />
        ))}
      </div>

      <div className={`grid gap-5 ${queryResponse.expectedBptOut === "0" ? "grid-cols-1" : "grid-cols-2"}`}>
        <div>
          <StyledQueryButton onClick={handleQueryJoin} isDisabled={!tokenInputs.some(token => token.rawAmount > 0n)}>
            Query Join
          </StyledQueryButton>
        </div>
        {queryResponse.expectedBptOut === "0" ? null : !sufficientAllowances ? (
          <div>
            <StyledTxButton
              isDisabled={isApproving}
              onClick={() => {
                if (!walletClient) return;
                try {
                  setIsApproving(true);
                  tokensToApprove.forEach(async token => {
                    try {
                      const { request } = await publicClient.simulateContract({
                        address: token.address,
                        abi: parseAbi(["function approve(address spender, uint256 amount) returns (bool)"]),
                        functionName: "approve",
                        account: account.address,
                        args: [pool.vaultAddress, token.rawAmount],
                      });
                      console.log("request", request);
                      await writeTx(() => walletClient.writeContract(request), {
                        blockConfirmations: 1,
                        onBlockConfirmation: txnReceipt => {
                          // Custom logic to run on block confirmation
                          // You can place more complex logic here, such as updating component state,
                          // calling other functions, or triggering notifications
                          refetchAllowances();
                          console.log("Transaction confirmed:", txnReceipt);
                        },
                      });
                    } catch (error) {
                      console.error("Approval error", error);
                      setIsApproving(false);
                    }
                  });
                } catch (error) {
                  console.error("Approval error", error);
                  setIsApproving(false);
                }
              }}
            >
              {isApproving ? "..." : "Approve"}
            </StyledTxButton>
          </div>
        ) : (
          <div>
            <StyledTxButton onClick={handleJoinPool}>Send Join</StyledTxButton>
          </div>
        )}
      </div>

      <PoolFeedback title="BPT Out" transactionUrl={joinTxUrl}>
        <div className="flex flex-wrap justify-between mb-3">
          <div>Expected</div>
          <div>{queryResponse.expectedBptOut}</div>
        </div>
        <div className="flex flex-wrap justify-between">
          <div>Minimum</div>
          <div>{queryResponse.minBptOut}</div>
        </div>
      </PoolFeedback>
    </section>
  );
};
