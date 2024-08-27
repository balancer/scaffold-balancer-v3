import { useState } from "react";
import {
  AddLiquidity,
  AddLiquidityBuildCallOutput,
  AddLiquidityInput,
  AddLiquidityKind,
  InputAmount,
  OnChainProvider,
  PoolState,
  Slippage,
  calculateProportionalAmounts,
} from "@balancer/sdk";
import { formatUnits } from "viem";
import { useWalletClient } from "wagmi";
import { useTargetFork } from "~~/hooks/balancer";
import { Pool, UseAddLiquidity } from "~~/hooks/balancer/types";
import { useTransactor } from "~~/hooks/scaffold-eth";
import { getBlockExplorerTxLink } from "~~/utils/scaffold-eth";

/**
 * Custom hook for adding liquidity to a pool where `queryAddLiquidity()` sets state of
 * the call object that is used to construct the transaction that is later sent by `addLiquidity()`
 */
export const useAddLiquidity = (pool: Pool, amountsIn: InputAmount[]): UseAddLiquidity => {
  const [call, setCall] = useState<AddLiquidityBuildCallOutput>();
  const { data: walletClient } = useWalletClient();
  const { rpcUrl, chainId } = useTargetFork();
  const writeTx = useTransactor();

  const queryAddLiquidity = async () => {
    try {
      const slippage = Slippage.fromPercentage("1"); // 1%
      const onchainProvider = new OnChainProvider(rpcUrl, chainId);
      const poolId = pool.address as `0x${string}`;
      const poolState: PoolState = await onchainProvider.pools.fetchPoolState(poolId, "CustomPool");

      // Construct the addLiquidity input object
      let addLiquidityInput: AddLiquidityInput;

      if (pool.poolConfig?.liquidityManagement.disableUnbalancedLiquidity) {
        const poolStateWithBalances = {
          address: poolState.address,
          // the pool's total supply from on chain read?
          totalShares: formatUnits(pool.totalSupply, pool.decimals) as `${number}`,
          tokens: pool.poolTokens.map(token => ({
            address: token.address as `0x${string}`,
            decimals: token.decimals,
            // use the pools token balances from on chain read?
            balance: formatUnits(token.balance, token.decimals) as `${number}`,
          })),
        };
        // What should referenceAmount be??? (the 2nd arg)
        const { bptAmount } = calculateProportionalAmounts(poolStateWithBalances, amountsIn[0]);

        addLiquidityInput = {
          bptOut: bptAmount,
          chainId,
          rpcUrl,
          kind: AddLiquidityKind.Proportional,
        };
      } else {
        addLiquidityInput = {
          amountsIn,
          chainId,
          rpcUrl,
          kind: AddLiquidityKind.Unbalanced,
        };
      }

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

  const addLiquidity = async () => {
    try {
      if (!walletClient) {
        throw new Error("Must connect a wallet to send a transaction");
      }
      if (!call) {
        throw new Error("tx call object is undefined");
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

  return { queryAddLiquidity, addLiquidity };
};
