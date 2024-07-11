import { useMemo } from "react";
import { BALANCER_ROUTER, InputAmount, PERMIT2, erc20Abi, permit2Abi } from "@balancer/sdk";
import { zeroAddress } from "viem";
import { useContractReads, useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { Permit2Allowance, UseTokens } from "~~/hooks/balancer/types";

/**
 * Custom hook for dealing with multiple tokens
 */
export const useTokens = (amountsIn: InputAmount[]): UseTokens => {
  const { data: walletClient } = useWalletClient();
  const connectedAddress = walletClient?.account.address || zeroAddress;
  const { chainId } = useTargetFork();

  const { data: balances, refetch: refetchTokenBalances } = useContractReads({
    contracts: amountsIn.map(token => ({
      address: token.address,
      abi: erc20Abi,
      functionName: "balanceOf",
      args: [connectedAddress],
    })),
  });

  const tokenBalances = useMemo(() => {
    return balances?.map(balance => {
      if (typeof balance.result === "bigint") {
        return balance.result;
      }
      return undefined;
    });
  }, [balances]); // Only recompute if tokenAllowances changes

  const { data: allowances, refetch: refetchTokenAllowances } = useContractReads({
    contracts: amountsIn.map(token => ({
      address: PERMIT2[chainId],
      abi: permit2Abi,
      functionName: "allowance",
      args: [connectedAddress, token.address, BALANCER_ROUTER[chainId]],
    })),
  });

  const tokenAllowances = useMemo(() => {
    if (!allowances) return undefined;
    return allowances.map((allowance: Permit2Allowance) => {
      if (allowance.status === "success" && Array.isArray(allowance.result)) {
        return allowance.result[0];
      }
      return undefined;
    });
  }, [allowances]); // Only recompute if allowances changes

  return {
    tokenAllowances,
    refetchTokenAllowances,
    tokenBalances,
    refetchTokenBalances,
  };
};
