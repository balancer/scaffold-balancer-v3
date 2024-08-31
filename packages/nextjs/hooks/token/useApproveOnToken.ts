import { erc20Abi } from "@balancer/sdk";
import { useMutation } from "@tanstack/react-query";
import { Address } from "viem";
import { useContractWrite } from "wagmi";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { MaxUint256 } from "~~/utils/constants";

export const useApproveOnToken = (token: Address, spender: Address) => {
  const writeTx = useTransactor();

  const { writeAsync: maxApprovePermit2 } = useContractWrite({
    address: token,
    abi: erc20Abi,
    functionName: "approve",
    args: [spender, MaxUint256], // point this approval at permit2 contract
  });

  const approve = async () => {
    await writeTx(() => maxApprovePermit2(), {
      blockConfirmations: 1,
      onBlockConfirmation: () => {
        console.log("Using token contract, user approved permit2 contract to spend max amount of", token);
      },
    });
  };

  return useMutation({
    mutationFn: () => approve(),
  });
};
