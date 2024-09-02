import { erc20Abi } from "@balancer/sdk";
import { Address, zeroAddress } from "viem";
import { useContractRead, useWalletClient } from "wagmi";

export const useAllowanceOnToken = (token: Address, spender: Address) => {
  const { data: walletClient } = useWalletClient();
  const connectedAddress = walletClient?.account.address || zeroAddress;

  return useContractRead({
    address: token,
    abi: erc20Abi,
    functionName: "allowance",
    args: [connectedAddress, spender],
  });
};
