import { useMemo } from "react";
import { BALANCER_ROUTER, InputAmount, PERMIT2, erc20Abi, permit2Abi } from "@balancer/sdk";
import { zeroAddress } from "viem";
import { useContractReads, useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { Permit2Allowance, UseTokens } from "~~/hooks/balancer/types";
import { type TokenBalances } from "~~/hooks/balancer/types";

/**
 * Custom hook for dealing with multiple tokens
 */
export const useReadTokens = (amountsIn: InputAmount[]): UseTokens => {
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
    const balancesObject: TokenBalances = {};
    if (balances) {
      balances.forEach((res, idx) => {
        const address = amountsIn[idx].address;
        const balance = (res.result as bigint) ?? 0n;
        balancesObject[address] = balance;
      });
    } else {
      amountsIn.forEach(token => {
        balancesObject[token.address] = 0n;
      });
    }
    return balancesObject;
  }, [balances, amountsIn]);

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
