import { erc20Abi } from "@balancer/sdk";
import { Address, zeroAddress } from "viem";
import { useContractRead, useWalletClient } from "wagmi";

/**
 * Custom hook for dealing with a single token
 */
export const useTokenBalanceOfUser = (token: Address) => {
  const { data: walletClient } = useWalletClient();
  const connectedAddress = walletClient?.account.address || zeroAddress;

  // Balance of token for the connected account
  return useContractRead({
    address: token,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: [connectedAddress],
  });
};
