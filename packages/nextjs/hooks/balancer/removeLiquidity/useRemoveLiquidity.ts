import { RemoveLiquidity, RemoveLiquidityQueryOutput, Slippage } from "@balancer/sdk";
import { useMutation } from "@tanstack/react-query";
import { useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

export const useRemoveLiquidity = () => {
  const { data: walletClient } = useWalletClient();
  const removeLiquidity = new RemoveLiquidity();
  const { chainId } = useTargetFork();
  const writeTx = useTransactor();

  const doRemoveLiquidity = async (queryOutput: RemoveLiquidityQueryOutput | undefined) => {
    if (!walletClient) throw new Error("Must connect a wallet to send a transaction");
    if (!queryOutput) throw new Error("Query output is required to remove liquidity");

    const slippage = Slippage.fromPercentage("1"); // 1%
    // Construct call object for transaction
    const call = removeLiquidity.buildCall({
      ...queryOutput,
      slippage,
      chainId,
      wethIsEth: false,
    });

    const txHash = await writeTx(
      () =>
        walletClient.sendTransaction({
          account: walletClient.account,
          data: call.callData,
          to: call.to,
          value: call.value,
        }),
      { blockConfirmations: 1 },
    );
    if (!txHash) throw new Error("Transaction failed");

    const blockExplorerTxURL = getBlockExplorerTxLink(chainId, txHash);
    return blockExplorerTxURL;
  };

  return useMutation({
    mutationFn: (queryOutput: RemoveLiquidityQueryOutput | undefined) => doRemoveLiquidity(queryOutput),
  });
};
