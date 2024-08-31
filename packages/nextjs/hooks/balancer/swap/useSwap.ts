import { ExactInQueryOutput, ExactOutQueryOutput, Slippage, Swap, SwapInput } from "@balancer/sdk";
import { useMutation } from "@tanstack/react-query";
import { useWalletClient } from "wagmi";
// import { useTargetFork } from "~~/hooks/balancer";
import { useTransactor } from "~~/hooks/scaffold-eth";

export const useSwap = (swapInput: SwapInput) => {
  const { data: walletClient } = useWalletClient();
  // const { chainId } = useTargetFork();
  const writeTx = useTransactor();

  const swap = new Swap(swapInput);

  const doSwap = async (queryOutput: ExactInQueryOutput | ExactOutQueryOutput | undefined) => {
    if (!walletClient) throw new Error("Must connect a wallet to send a transaction");
    if (!queryOutput) throw new Error("Query output is required to swap");

    const deadline = 999999999999999999n; // Deadline for the swap, in this case infinite
    const slippage = Slippage.fromPercentage("0.1"); // 0.1%

    const call = swap.buildCall({
      slippage,
      deadline,
      queryOutput,
      wethIsEth: false,
    });

    const txHashPromise = () =>
      walletClient.sendTransaction({
        account: walletClient.account,
        data: call.callData,
        to: call.to,
        value: call.value,
      });
    const txHash = await writeTx(txHashPromise, { blockConfirmations: 1 });
    if (!txHash) throw new Error("Transaction failed");

    return txHash;
  };

  return useMutation({
    mutationFn: (queryOutput: ExactInQueryOutput | ExactOutQueryOutput | undefined) => doSwap(queryOutput),
  });
};
