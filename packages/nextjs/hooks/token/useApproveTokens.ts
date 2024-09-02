import { useEffect, useState } from "react";
import { useReadTokens } from ".";
import { BALANCER_ROUTER, InputAmount, PERMIT2, erc20Abi, permit2Abi } from "@balancer/sdk";
import { usePublicClient, useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { MaxUint48, MaxUint160, MaxUint256 } from "~~/utils/constants";

/**
 * Only used for the AddLiquidityForm component
 * Should refactor this mess one day :D
 */
export const useApproveTokens = (tokenInputs: InputAmount[]) => {
  const [tokensToApprove, setTokensToApprove] = useState<InputAmount[]>([]);
  const [sufficientAllowances, setSufficientAllowances] = useState(false);
  const [isApproving, setIsApproving] = useState(false);
  const writeTx = useTransactor(); // scaffold hook for tx status toast notifications
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();

  const { chainId } = useTargetFork();

  const { tokenAllowances, refetchTokenAllowances } = useReadTokens(tokenInputs);

  const approveTokens = () => {
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

  return { approveTokens, sufficientAllowances, isApproving };
};
