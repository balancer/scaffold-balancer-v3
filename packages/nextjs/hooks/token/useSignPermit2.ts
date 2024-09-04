import {
  AllowanceTransfer,
  BALANCER_ROUTER,
  MaxSigDeadline,
  PERMIT2,
  Permit2Batch,
  PermitDetails,
} from "@balancer/sdk";
import { useTargetFork } from "~~/hooks/balancer";

export const useSignPermit2 = () => {
  const { chainId } = useTargetFork();

  const signPermit2 = async (walletClient: any, details: PermitDetails[]) => {
    if (!walletClient) throw new Error("Must connect a wallet to sign a permit");
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

    return { signature, batch };
  };

  return { signPermit2 };
};
