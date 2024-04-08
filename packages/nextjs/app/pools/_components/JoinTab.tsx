import React, { useEffect, useState } from "react";
import { TokenField } from "./TokenField";
import { InputAmount } from "@balancer/sdk";
import { formatUnits, parseAbi, parseUnits } from "viem";
import { useAccount, useContractReads, useContractWrite } from "wagmi";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";
import { GradientButton, OutlinedButton } from "~~/components/common";
import { useJoin } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";

const initialQueryResponse = {
  expectedBptOut: "0",
  minBptOut: "0",
};

/**
 * 1. Query the results of join transaction
 * 2. User approves the vault for the tokens used in the join transaction (only if necessary)
 * 3. User joins the pool
 */
export const JoinTab = ({ pool }: { pool: Pool }) => {
  const [queryResponse, setQueryResponse] = useState(initialQueryResponse);
  const { expectedBptOut, minBptOut } = queryResponse;
  const [tokensToApprove, setTokensToApprove] = useState<any[]>([]);
  const [sufficientAllowances, setSufficientAllowances] = useState(false);
  const [isApproving, setIsApproving] = useState(false); // Flag to indicate if approval process is ongoing
  const [tokenInputs, setTokenInputs] = useState<InputAmount[]>(
    pool.poolTokens.map(token => ({
      address: token.address as `0x${string}`,
      decimals: token.decimals,
      rawAmount: 0n,
    })),
  );
  const [joinTxUrl, setJoinTxUrl] = useState<string | undefined>();

  const { queryJoin, joinPool } = useJoin(pool.address as `0x${string}`);
  const writeTx = useTransactor(); // scaffold hook for tx status toast notifications

  const {
    writeAsync: approveAsync,
    isSuccess,
    isError,
  } = useContractWrite({
    address: tokensToApprove[0]?.address,
    abi: parseAbi(["function approve(address spender, uint256 amount) returns (bool)"]),
    functionName: "approve",
    args: [pool.vaultAddress, tokensToApprove[0]?.rawAmount || 0n],
  });

  const { address: connectedAddress } = useAccount();
  const { data: allowances } = useContractReads({
    contracts: tokenInputs.map(token => ({
      address: token.address,
      abi: parseAbi(["function allowance(address owner, address spender) returns (uint256)"]),
      functionName: "allowance",
      args: [connectedAddress as string, pool.vaultAddress],
    })),
  });

  // Initiates token approval tx `tokensToApprove` changes??
  useEffect(() => {
    const approveToken = async () => {
      if (tokensToApprove?.length > 0 && !isApproving) {
        setIsApproving(true);
        try {
          await writeTx(approveAsync, { blockConfirmations: 1 });
          setTokensToApprove(tokens => tokens.slice(1)); // Remove the approved token from the queue
        } catch (error) {
          console.error("Approval error:", error);
        } finally {
          setIsApproving(false);
        }
      }
    };

    approveToken();
  }, [tokensToApprove, approveAsync, writeTx, isApproving, isError, isSuccess]);

  useEffect(() => {
    if (allowances && allowances.length === tokenInputs.length) {
      const allTokensApproved = tokenInputs.every((token, index) => {
        const allowance = BigInt((allowances[index]?.result as string) || "0");
        return allowance >= token.rawAmount;
      });

      setSufficientAllowances(allTokensApproved);
    }
  }, [allowances, tokensToApprove, tokenInputs]); // Re-run this effect when allowances or tokenInputs change

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
      setTokenInputs(
        pool.poolTokens.map(token => ({
          address: token.address as `0x${string}`,
          decimals: token.decimals,
          rawAmount: 0n,
        })),
      );
    } catch (e) {
      console.error("error", e);
    }
  };

  return (
    <section>
      {/* Token Inputs */}
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
            allowance={allowances && formatUnits((allowances[index].result as bigint) || 0n, token.decimals)}
          />
        ))}
      </div>

      {/* Query, Approve, and Join Buttons */}
      <div className={`grid gap-5 ${expectedBptOut === "0" ? "grid-cols-1" : "grid-cols-2"}`}>
        <div>
          <GradientButton onClick={handleQueryJoin} isDisabled={!tokenInputs.some(token => token.rawAmount > 0n)}>
            Query Join
          </GradientButton>
        </div>
        {expectedBptOut === "0" ? null : !sufficientAllowances ? (
          <div>
            <OutlinedButton onClick={() => setTokensToApprove(tokenInputs)}>Approve</OutlinedButton>
          </div>
        ) : (
          <div>
            <OutlinedButton onClick={handleJoinPool}>Send Join</OutlinedButton>
          </div>
        )}
      </div>

      {/* Query Result Display */}
      <div className="bg-[#FCD34D40] border border-amber-400 rounded-lg p-5 mt-5">
        <>
          <div className="flex flex-wrap justify-between mb-3">
            <div>Expected BPT Out</div>
            <div>{expectedBptOut}</div>
          </div>
          <div className="flex flex-wrap justify-between">
            <div>Minimum BPT Out</div>
            <div>{minBptOut}</div>
          </div>
          {joinTxUrl && (
            <div className="flex flex-wrap justify-between mt-3">
              <div>Actual BPT Out</div>
              <a
                rel="noopener"
                target="_blank"
                href={joinTxUrl}
                className="text-neutral underline flex items-center gap-1"
              >
                block explorer <ArrowTopRightOnSquareIcon className="w-4 h-4" />
              </a>
            </div>
          )}
        </>
      </div>
    </section>
  );
};
