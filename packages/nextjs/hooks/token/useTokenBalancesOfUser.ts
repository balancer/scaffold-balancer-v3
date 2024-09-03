import { useMemo } from "react";
import { erc20Abi } from "@balancer/sdk";
import { zeroAddress } from "viem";
import { useContractReads, useWalletClient } from "wagmi";
import { type TokenBalances } from "~~/hooks/balancer/types";

/**
 * Hook for fetching and refetching pool token balances of a user
 * Should refactor this mess one day :D
 */
export const useTokenBalancesOfUser = (tokens: { address: string }[]) => {
  const { data: walletClient } = useWalletClient();
  const connectedAddress = walletClient?.account.address || zeroAddress;

  const { data: balances, refetch: refetchTokenBalances } = useContractReads({
    contracts: tokens.map(token => ({
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
        const address = tokens[idx].address;
        const balance = (res.result as bigint) ?? 0n;
        balancesObject[address] = balance;
      });
    } else {
      tokens.forEach(token => {
        balancesObject[token.address] = 0n;
      });
    }
    return balancesObject;
  }, [balances, tokens]);

  return {
    tokenBalances,
    refetchTokenBalances,
  };
};
