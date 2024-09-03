import {
  ExactInQueryOutput,
  ExactOutQueryOutput,
  MaxAllowanceExpiration,
  PermitDetails, //  Permit2Helper,
  Slippage,
  Swap,
  SwapInput,
} from "@balancer/sdk";
import { useMutation } from "@tanstack/react-query";
import { useWalletClient } from "wagmi";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { useAllowanceOnPermit2, useSignPermit2 } from "~~/hooks/token";

export const useSwap = (swapInput: SwapInput) => {
  const tokenIn = swapInput.paths[0].tokens[0];
  const amountIn = swapInput.paths[0].inputAmountRaw;

  const { data: walletClient } = useWalletClient();
  const writeTx = useTransactor();
  const { data, refetch: refetchAllowanceOnPermit2 } = useAllowanceOnPermit2(tokenIn.address);
  const allowanceOnPermit2 = data?.[0];
  const nonce = data?.[2];

  const swap = new Swap(swapInput);

  const { signPermit2 } = useSignPermit2();

  const doSwap = async (queryOutput: ExactInQueryOutput | ExactOutQueryOutput | undefined) => {
    if (!walletClient) throw new Error("Must connect a wallet to send a transaction");
    if (!queryOutput) throw new Error("Query output is required to swap");

    const deadline = 999999999999999999n; // Deadline for the swap, in this case infinite
    const slippage = Slippage.fromPercentage("0.1"); // 0.1%
    const buildCallInput = {
      slippage,
      deadline,
      queryOutput,
      wethIsEth: false,
    };

    let call;

    if (allowanceOnPermit2 !== undefined && allowanceOnPermit2 < amountIn) {
      if (nonce === undefined) throw new Error("Nonce is required to sign the permit");

      const details: PermitDetails[] = [
        {
          token: tokenIn.address,
          amount: amountIn,
          expiration: Number(MaxAllowanceExpiration),
          nonce,
        },
      ];
      const permit2 = await signPermit2(walletClient, details);

      call = swap.buildCallWithPermit2(buildCallInput, permit2);
    } else {
      call = swap.buildCall(buildCallInput);
    }

    const txHashPromise = () =>
      walletClient.sendTransaction({
        account: walletClient.account,
        data: call.callData,
        to: call.to,
        value: call.value,
      });

    const txHash = await writeTx(txHashPromise, { blockConfirmations: 1 });
    if (!txHash) throw new Error("Transaction failed");

    refetchAllowanceOnPermit2();

    return txHash;
  };

  return useMutation({
    mutationFn: (queryOutput: ExactInQueryOutput | ExactOutQueryOutput | undefined) => doSwap(queryOutput),
  });
};
