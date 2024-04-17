import { useState } from "react";
import {
  AddLiquidity,
  AddLiquidityInput,
  AddLiquidityKind,
  BalancerApi, //   ChainId,
  InputAmount,
  Slippage,
} from "@balancer/sdk";
import { parseAbi } from "viem";
import { useContractReads, usePublicClient, useWalletClient } from "wagmi";
import { type Pool } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

type QueryJoinResponse = Promise<{ expectedBptOut: string; minBptOut: string } | undefined>;

type JoinPoolTxResponse = Promise<string | undefined>;

type JoinPoolFunctions = {
  queryJoin: (amountsIn: InputAmount[]) => QueryJoinResponse;
  joinPool: () => JoinPoolTxResponse;
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

  const queryJoin = async (): QueryJoinResponse => {
    try {
      // User defined (along with the queryJoin parameters)
      const chainId = await publicClient.getChainId();
      const rpcUrl = publicClient?.chain.rpcUrls.default.http[0] as string;
      const slippage = Slippage.fromPercentage("1"); // 1%

      // API used to fetch relevant pool data for addLiquidity.query
      const balancerApi = new BalancerApi("https://backend-v3-canary.beets-ftm-node.com/graphql", chainId);
      const poolState = await balancerApi.pools.fetchPoolState(pool.address.toLowerCase());

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
      const expectedBptOut = queryOutput.bptOut.amount.toString();

      // Applies slippage to the BPT out amount and constructs the call
      const call = addLiquidity.buildCall({
        ...queryOutput,
        slippage,
        chainId,
        wethIsEth: false,
      });
      const minBptOut = call.minBptOut.amount.toString();

      setCall(call);

      return { expectedBptOut, minBptOut };
    } catch (error) {
      throw error; // throw it for handling in consuming component
    }
  };

  const joinPool = async (): JoinPoolTxResponse => {
    try {
      if (!walletClient) {
        throw new Error("Client is undefined");
      }

      const txHashPromise = () =>
        walletClient.sendTransaction({
          account: walletClient.account,
          data: call.call,
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
