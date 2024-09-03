import {
  AddLiquidity,
  AddLiquidityQueryOutput,
  BALANCER_ROUTER,
  InputAmount,
  MaxAllowanceExpiration,
  PERMIT2,
  PermitDetails,
  Slippage,
  permit2Abi,
} from "@balancer/sdk";
import { useMutation } from "@tanstack/react-query";
import { zeroAddress } from "viem";
import { useContractReads, useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { useSignPermit2 } from "~~/hooks/token";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

export const useAddLiquidity = (amountsIn: InputAmount[]) => {
  const { chainId } = useTargetFork();
  const { data: walletClient } = useWalletClient();
  const connectedAddress = walletClient?.account.address || zeroAddress;
  const writeTx = useTransactor();
  const addLiquidity = new AddLiquidity();
  const { signPermit2 } = useSignPermit2();

  // Fetch permit2 allowances for each token with router as spender
  const { data: allowances, refetch: refetchAllowances } = useContractReads({
    contracts: amountsIn.map(token => ({
      address: PERMIT2[chainId],
      abi: permit2Abi,
      functionName: "allowance",
      args: [connectedAddress, token.address, BALANCER_ROUTER[chainId]],
    })),
  });

  // console.log("permit2 allowances for router", allowances);

  const doAddLiquidity = async (queryOutput: AddLiquidityQueryOutput | undefined) => {
    if (!walletClient) throw new Error("Must connect a wallet to add liquidity");
    if (!queryOutput) throw new Error("Query output is required to add liquidity");
    if (!allowances) throw new Error("Error fetching data from permit2 contract");

    const slippage = Slippage.fromPercentage("1"); // 1%

    const buildCallInput = {
      ...queryOutput,
      slippage,
      chainId,
      wethIsEth: false,
    };

    // determine which tokens need permit2 approval, add them to the PermitDetails[]
    // if no tokens need permit2 approval, build the call like normal?

    const details: PermitDetails[] = amountsIn.map((token, idx) => {
      const permitInfo = allowances[idx];

      if (permitInfo.status === "success" && Array.isArray(permitInfo.result)) {
        const nonce = permitInfo.result[2];
        return {
          token: token.address,
          amount: token.rawAmount,
          expiration: Number(MaxAllowanceExpiration),
          nonce,
        };
      } else {
        throw new Error("Invalid allowance result");
      }
    });

    const permit2 = await signPermit2(walletClient, details);

    const call = addLiquidity.buildCallWithPermit2(buildCallInput, permit2);

    // const call = addLiquidity.buildCall(buildCallInput);

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

    refetchAllowances();
    const blockExplorerTxURL = getBlockExplorerTxLink(chainId, txHash);
    return blockExplorerTxURL;
  };

  return useMutation({
    mutationFn: (queryOutput: AddLiquidityQueryOutput | undefined) => doAddLiquidity(queryOutput),
  });
};
