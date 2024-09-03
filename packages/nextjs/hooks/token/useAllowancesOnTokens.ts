import { useEffect, useState } from "react";
import { InputAmount, PERMIT2, erc20Abi } from "@balancer/sdk";
import { zeroAddress } from "viem";
import { useContractReads, useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";

/**
 * Figure out which tokens have approved the permit2 contract to spend their tokens
 */
export const useAllowancesOnTokens = (tokenInputs: InputAmount[]) => {
  const [tokensToApprove, setTokensToApprove] = useState<InputAmount[]>([]);
  const [sufficientAllowances, setSufficientAllowances] = useState(false);

  const { data: walletClient } = useWalletClient();
  const connectedAddress = walletClient?.account.address || zeroAddress;
  const { chainId } = useTargetFork();

  const { data: tokenAllowances, refetch: refetchTokenAllowances } = useContractReads({
    contracts: tokenInputs.map(token => ({
      address: token.address,
      abi: erc20Abi,
      functionName: "allowance",
      args: [connectedAddress, PERMIT2[chainId]],
    })),
  });

  // console.log("tokenAllowances", tokenAllowances);
  // console.log("tokensToApprove", tokensToApprove);

  useEffect(() => {
    if (tokenAllowances) {
      // console.log("tokenAllowances", tokenAllowances);
      const tokensNeedingApproval = tokenInputs.filter((token, index) => {
        const allowance = tokenAllowances[index].result as bigint;
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
  }, [tokenInputs, tokenAllowances]);

  return { tokensToApprove, sufficientAllowances, refetchTokenAllowances };
};
