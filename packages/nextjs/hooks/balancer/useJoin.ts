import { useState } from "react";
import {
  AddLiquidity,
  AddLiquidityInput,
  AddLiquidityKind,
  InputAmount,
  OnChainProvider,
  PoolState,
  Slippage,
} from "@balancer/sdk";
import { parseAbi } from "viem";
import { useContractReads, usePublicClient, useWalletClient } from "wagmi";
import { Pool, PoolActionTxUrl, QueryJoinResponse } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

type JoinPoolFunctions = {
  queryJoin: () => Promise<QueryJoinResponse>;
  joinPool: () => Promise<PoolActionTxUrl>;
  allowances: any[] | undefined;
  refetchAllowances: () => void;
  tokenBalances: any[] | undefined;
};

/**
 * Custom hook for adding liquidity to a pool where `queryJoin()` sets state of
 * the call object that is used to construct the transaction that is later sent by `joinPool()`
 */
export const useJoin = (pool: Pool, amountsIn: InputAmount[]): JoinPoolFunctions => {
  const [call, setCall] = useState<any>();

  const { data: walletClient } = useWalletClient();
  const publicClient = usePublicClient();
  const writeTx = useTransactor();

  const queryJoin = async () => {
    try {
      // User defined (along with the queryJoin parameters)
      const rpcUrl = publicClient?.chain.rpcUrls.default.http[0] as string;
      // const chainId = await publicClient.getChainId();
      const chainId = 111555111; // hardcoding to sepolia because query requires chainId of forked network
      const slippage = Slippage.fromPercentage("1"); // 1%

      const onchainProvider = new OnChainProvider(rpcUrl, chainId);
      const poolId = pool.address as `0x${string}`;
      const poolState: PoolState = await onchainProvider.pools.fetchPoolState(poolId, "CustomPool");

      // Construct the addLiquidity input object
      const addLiquidityInput: AddLiquidityInput = {
        amountsIn,
        chainId,
        rpcUrl,
        kind: AddLiquidityKind.Unbalanced,
      };

      // Query addLiquidity to get the amount of BPT out
      const addLiquidity = new AddLiquidity();
      const queryOutput = await addLiquidity.query(addLiquidityInput, poolState);

      // Applies slippage to the BPT out amount and constructs the call
      const call = addLiquidity.buildCall({
        ...queryOutput,
        slippage,
        chainId,
        wethIsEth: false,
      });

      setCall(call);

      return { expectedBptOut: queryOutput.bptOut, minBptOut: call.minBptOut };
    } catch (error) {
      console.error("error", error);
      const message = (error as { shortMessage?: string }).shortMessage || "An unknown error occurred";
      return { error: { message } };
    }
  };

  const joinPool = async () => {
    try {
      if (!walletClient) {
        throw new Error("Client is undefined");
      }

      const txHashPromise = () =>
        walletClient.sendTransaction({
          account: walletClient.account,
          data: call.callData,
          to: call.to,
          value: call.value,
        });

      const hash = await writeTx(txHashPromise, { blockConfirmations: 1 });

      if (!hash) {
        throw new Error("Transaction failed");
      }

      const chainId = await walletClient.getChainId();
      const blockExplorerTxURL = getBlockExplorerTxLink(chainId, hash);
      return blockExplorerTxURL;
    } catch (e) {
      console.error("error", e);
      return null;
    }
  };

  const { data: allowances, refetch: refetchAllowances } = useContractReads({
    contracts: amountsIn.map(token => ({
      address: token.address,
      abi: parseAbi(["function allowance(address owner, address spender) returns (uint256)"]),
      functionName: "allowance",
      args: [walletClient?.account.address as string, pool.vaultAddress],
    })),
  });

  const { data: tokenBalances } = useContractReads({
    contracts: amountsIn.map(token => ({
      address: token.address,
      abi: parseAbi(["function balanceOf(address owner) returns (uint256)"]),
      functionName: "balanceOf",
      args: [walletClient?.account.address as string],
    })),
  });

  return { queryJoin, joinPool, allowances, refetchAllowances, tokenBalances };
};
