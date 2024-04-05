import React, { useEffect, useState } from "react";
import { InputAmount } from "@balancer/sdk";
import { formatUnits, parseAbi, parseUnits } from "viem";
import { useContractReads, useContractWrite } from "wagmi";
import { useAccount } from "wagmi";
import { ArrowTopRightOnSquareIcon } from "@heroicons/react/24/outline";
import { useJoin } from "~~/hooks/balancer/";
import { type Pool } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";

/**
 * 1. Query the results of join transaction
 * 2. User approves the vault for the tokens used in the join transaction (only if necessary)
 * 3. User joins the pool
 */
export const JoinTab = ({ pool }: { pool: Pool }) => {
  const [queryResponse, setQueryResponse] = useState({
    expectedBptOut: "0",
    minBptOut: "0",
  });
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

  const { queryJoin, joinPool } = useJoin();
  const writeTx = useTransactor();

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
  };

  const handleQueryJoin = async () => {
    const queryResponse = await queryJoin(pool.address as string, tokenInputs);
    setQueryResponse(queryResponse);
  };

  const handleJoinPool = async () => {
    try {
      const txHash = await joinPool();
      setJoinTxUrl(txHash);
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
      <div className="mb-5">
        <div>
          <label>Tokens In</label>
        </div>
        {tokenInputs.map((token, index) => (
          <div key={token.address} className="relative mb-3">
            <input
              value={
                formatUnits(token.rawAmount, token.decimals) === "0" ? "" : formatUnits(token.rawAmount, token.decimals)
              }
              onChange={e => handleInputChange(index, e.target.value)}
              type="number"
              placeholder="0.0"
              className="text-2xl w-full input input-bordered rounded-lg bg-base-200 p-10"
            />

            <div className="absolute top-3 right-3 text-center p-4 bg-base-100 rounded-md font-bold w-24">
              {pool.poolTokens[index].symbol}
            </div>
            <div className="absolute bottom-1 left-1 text-xs ml-2 mt-2">
              Allowance {allowances && formatUnits(allowances[index].result as bigint, token.decimals)}
            </div>
          </div>
        ))}
      </div>
      <div className={`grid gap-5 ${expectedBptOut === "0" ? "grid-cols-1" : "grid-cols-2"}`}>
        <div>
          <button onClick={handleQueryJoin} className="btn btn-neutral mt-3 w-full rounded-md">
            Query Join
          </button>
        </div>
        {expectedBptOut === "0" ? null : !sufficientAllowances ? (
          <div>
            <button onClick={() => setTokensToApprove(tokenInputs)} className="btn btn-warning mt-3 w-full rounded-md">
              Approve
            </button>
          </div>
        ) : (
          <div>
            <button onClick={handleJoinPool} className="btn btn-success mt-3 w-full rounded-md">
              Send Join
            </button>
          </div>
        )}
      </div>
      <div className="border border-base-100 rounded-lg p-5 mt-5 text-lg">
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
