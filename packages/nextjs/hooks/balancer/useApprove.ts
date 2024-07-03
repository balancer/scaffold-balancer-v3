import { PERMIT2, erc20Abi, permit2Abi } from "@balancer/sdk";
import { Address } from "viem";
import { useContractWrite } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { UseApprove } from "~~/hooks/balancer/types";
import { MaxUint48, MaxUint160, MaxUint256 } from "~~/utils/constants";

/**
 * Custom hook for approving spenders both erc20 and permit2 style
 */
export const useApprove = (token: Address, spender: Address): UseApprove => {
  const { chainId } = useTargetFork();

  // Max approve canonical Permit2 address to spend account's tokens
  const { writeAsync: approveSpenderOnToken } = useContractWrite({
    address: token,
    abi: erc20Abi,
    functionName: "approve",
    args: [spender, MaxUint256], // point this approval at permit2 contract
  });

  // Approve Router to spend account's tokens using Permit2
  const { writeAsync: approveSpenderOnPermit2 } = useContractWrite({
    address: PERMIT2[chainId],
    abi: permit2Abi,
    functionName: "approve",
    args: [token, spender, MaxUint160, MaxUint48],
  });

  return {
    approveSpenderOnToken,
    approveSpenderOnPermit2,
  };
};
