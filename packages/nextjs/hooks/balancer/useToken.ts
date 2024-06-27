import { BALANCER_ROUTER, PERMIT2, erc20Abi, permit2Abi } from "@balancer/sdk";
import { WriteContractResult } from "@wagmi/core";
import { Address, zeroAddress } from "viem";
import { useContractRead, useContractWrite, useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { MaxUint48, MaxUint160, MaxUint256 } from "~~/utils/constants";

type UseTokenHook = {
  tokenAllowance: bigint;
  tokenBalance: bigint;
  refetchTokenAllowance: () => void;
  refetchTokenBalance: () => void;
  approveSpenderOnToken: () => Promise<WriteContractResult>;
  approveSpenderOnPermit2: () => Promise<WriteContractResult>;
};

/**
 * Custom hook for dealing with a single token
 */
export const useToken = (token: Address): UseTokenHook => {
  const { data: walletClient } = useWalletClient();
  const connectedAddress = walletClient?.account.address || zeroAddress;
  const { chainId } = useTargetFork();

  // Balance of token for the connected account
  const { data: tokenBalance, refetch: refetchTokenBalance } = useContractRead({
    address: token,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: [connectedAddress],
  });

  // Allowance for Router to spend account's tokens from Permit2
  const { data: tokenAllowance, refetch: refetchTokenAllowance } = useContractRead({
    address: PERMIT2[chainId],
    abi: permit2Abi,
    functionName: "allowance",
    args: [connectedAddress, token, BALANCER_ROUTER[chainId]],
  });

  // Max approve canonical Permit2 address to spend account's tokens
  const { writeAsync: approveSpenderOnToken } = useContractWrite({
    address: token,
    abi: erc20Abi,
    functionName: "approve",
    args: [PERMIT2[chainId], MaxUint256], // point this approval at permit2 contract
  });

  // Approve Router to spend account's tokens using Permit2
  const { writeAsync: approveSpenderOnPermit2 } = useContractWrite({
    address: PERMIT2[chainId],
    abi: permit2Abi,
    functionName: "approve",
    args: [token, BALANCER_ROUTER[chainId], MaxUint160, MaxUint48],
  });

  return {
    tokenAllowance: tokenAllowance ? tokenAllowance[0] : 0n,
    refetchTokenAllowance,
    tokenBalance: tokenBalance ? tokenBalance : 0n,
    refetchTokenBalance,
    approveSpenderOnToken,
    approveSpenderOnPermit2,
  };
};
