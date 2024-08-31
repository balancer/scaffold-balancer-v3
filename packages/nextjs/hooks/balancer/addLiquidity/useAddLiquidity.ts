import { AddLiquidity, AddLiquidityQueryOutput, Slippage } from "@balancer/sdk";
import { useMutation } from "@tanstack/react-query";
import { useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

export const useAddLiquidity = () => {
  const { chainId } = useTargetFork();
  const { data: walletClient } = useWalletClient();
  const writeTx = useTransactor();
  const addLiquidity = new AddLiquidity();

  const doAddLiquidity = async (queryOutput: AddLiquidityQueryOutput | undefined) => {
    if (!walletClient) throw new Error("Must connect a wallet to add liquidity");
    if (!queryOutput) throw new Error("Query output is required to add liquidity");

    const slippage = Slippage.fromPercentage("1"); // 1%

    // Applies slippage to the BPT out amount and constructs the call
    const call = addLiquidity.buildCall({
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
    mutationFn: (queryOutput: AddLiquidityQueryOutput | undefined) => doAddLiquidity(queryOutput),
  });
};
