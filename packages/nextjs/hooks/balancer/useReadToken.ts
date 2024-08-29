import { BALANCER_ROUTER, PERMIT2, erc20Abi, permit2Abi } from "@balancer/sdk";
import { Address, zeroAddress } from "viem";
import { useContractRead, useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { UseToken } from "~~/hooks/balancer/types";

/**
 * Custom hook for dealing with a single token
 */
export const useReadToken = (token: Address): UseToken => {
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

  return {
    tokenAllowance: tokenAllowance ? tokenAllowance[0] : 0n,
    refetchTokenAllowance,
    tokenBalance: tokenBalance ? tokenBalance : 0n,
    refetchTokenBalance,
  };
};
