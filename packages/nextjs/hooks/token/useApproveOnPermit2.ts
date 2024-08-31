import { BALANCER_ROUTER, PERMIT2, permit2Abi } from "@balancer/sdk";
import { useMutation } from "@tanstack/react-query";
import { Address } from "viem";
import { useContractWrite } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { MaxUint48, MaxUint160 } from "~~/utils/constants";

// Using permit2 contract, approve the Router to spend the connected account's account's tokens
export const useApproveOnPermit2 = (token: Address) => {
  const { chainId } = useTargetFork();
  const writeTx = useTransactor();

  const { writeAsync: approveRouter } = useContractWrite({
    address: PERMIT2[chainId],
    abi: permit2Abi,
    functionName: "approve",
    args: [token, BALANCER_ROUTER[chainId], MaxUint160, MaxUint48],
  });

  const approve = async () => {
    await writeTx(() => approveRouter(), {
      blockConfirmations: 1,
      onBlockConfirmation: () => {
        console.log("Using permit2 contract, user approved Router to spend max amount of", token);
      },
    });
  };

  return useMutation({
    mutationFn: () => approve(),
  });
};
