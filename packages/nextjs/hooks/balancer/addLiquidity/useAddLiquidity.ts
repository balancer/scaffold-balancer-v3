import { AddLiquidityBuildCallOutput } from "@balancer/sdk";
import { useMutation } from "@tanstack/react-query";
import { useWalletClient } from "wagmi";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

export const useAddLiquidity = () => {
  const { data: walletClient } = useWalletClient();
  const writeTx = useTransactor();

  const addLiquidity = async (call: AddLiquidityBuildCallOutput | undefined) => {
    if (!walletClient) throw new Error("Must connect a wallet to add liquidity");
    if (!call) throw new Error("Add liquidity call object is undefined");

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

    const chainId = await walletClient.getChainId();
    const blockExplorerTxURL = getBlockExplorerTxLink(chainId, txHash);
    return blockExplorerTxURL;
  };

  return useMutation({
    mutationFn: (call: AddLiquidityBuildCallOutput | undefined) => addLiquidity(call),
  });
};
