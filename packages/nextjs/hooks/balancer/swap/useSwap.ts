import {
  AllowanceTransfer,
  BALANCER_ROUTER,
  ExactInQueryOutput,
  ExactOutQueryOutput,
  MaxAllowanceExpiration,
  MaxSigDeadline,
  PERMIT2,
  Permit2Batch,
  PermitDetails, //  Permit2Helper,
  Slippage,
  Swap,
  SwapInput,
  permit2Abi,
} from "@balancer/sdk";
import { useMutation } from "@tanstack/react-query";
// import { decodeErrorResult } from "viem";
import { usePublicClient, useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { useAllowanceOnPermit2 } from "~~/hooks/token";

export const useSwap = (swapInput: SwapInput) => {
  const { data: walletClient } = useWalletClient();
  const publicClient = usePublicClient();
  const writeTx = useTransactor();
  const { chainId } = useTargetFork();
  const tokenIn = swapInput.paths[0].tokens[0];
  const amountIn = swapInput.paths[0].inputAmountRaw;

  // use buildCallWithPermit2 only iff allowanceOnPermit2 is less than swapInput.paths[0].inputAmountRaw
  const { data } = useAllowanceOnPermit2(tokenIn.address);
  const allowanceOnPermit2 = data?.[0];

  const swap = new Swap(swapInput);

  // const value = decodeErrorResult({
  //   abi: permit2Abi,
  //   data: "0x756688fe000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000b68656c6c6f20776f726c64000000000000000000000000000000000000000000",
  // });

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

    if (allowanceOnPermit2 === undefined || allowanceOnPermit2 < amountIn) {
      const spender = BALANCER_ROUTER[chainId];

      const result = await publicClient.readContract({
        abi: permit2Abi,
        address: PERMIT2[chainId],
        functionName: "allowance",
        args: [walletClient.account.address, tokenIn.address, spender],
      });

      const nonce = result[2];

      const details: PermitDetails[] = [
        {
          token: tokenIn.address,
          amount: amountIn,
          expiration: Number(MaxAllowanceExpiration),
          nonce,
        },
      ];

      const batch: Permit2Batch = {
        details,
        spender: BALANCER_ROUTER[chainId],
        sigDeadline: MaxSigDeadline,
      };

      const { domain, types, values } = AllowanceTransfer.getPermitData(batch, PERMIT2[chainId], walletClient.chain.id);

      const signature = await walletClient.signTypedData({
        account: walletClient.account,
        message: {
          ...values,
        },
        domain,
        primaryType: "PermitBatch",
        types,
      });

      const permit2 = { signature, batch };

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

    return txHash;
  };

  return useMutation({
    mutationFn: (queryOutput: ExactInQueryOutput | ExactOutQueryOutput | undefined) => doSwap(queryOutput),
  });
};
