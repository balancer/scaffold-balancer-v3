import { RefetchPool } from "./useReadPool";
import { SwapKind } from "@balancer/sdk";
import { WriteContractResult } from "@wagmi/core";
import { type Address } from "viem";

///////////////////
// Pool Data
//////////////////
export type Pool = {
  address: Address;
  decimals: number;
  isRegistered: boolean;
  name: string;
  symbol: string;
  minSwapFeePercentage: bigint;
  maxSwapFeePercentage: bigint;
  minInvariantRatio: bigint;
  maxInvariantRatio: bigint;
  userBalance: bigint;
  poolConfig: PoolConfig | undefined;
  hooksConfig: HooksConfig | undefined;
  poolTokens: Array<PoolTokens> | [];
  totalSupply: bigint;
  vaultAddress: Address;
};

export type PoolTokens = {
  address: Address;
  balance: bigint;
  decimals: number;
  name: string;
  symbol: string;
};

export type PoolConfig = {
  liquidityManagement: {
    disableUnbalancedLiquidity: boolean;
    enableAddLiquidityCustom: boolean;
    enableRemoveLiquidityCustom: boolean;
    enableDonation: boolean;
  };
  staticSwapFeePercentage: bigint;
  aggregateSwapFeePercentage: bigint;
  aggregateYieldFeePercentage: bigint;
  tokenDecimalDiffs: number;
  pauseWindowEndTime: number;
  isPoolRegistered: boolean;
  isPoolInitialized: boolean;
  isPoolPaused: boolean;
  isPoolInRecoveryMode: boolean;
};

export type HooksConfig = {
  shouldCallBeforeInitialize: boolean;
  shouldCallAfterInitialize: boolean;
  shouldCallComputeDynamicSwapFee: boolean;
  shouldCallBeforeSwap: boolean;
  shouldCallAfterSwap: boolean;
  shouldCallBeforeAddLiquidity: boolean;
  shouldCallAfterAddLiquidity: boolean;
  shouldCallBeforeRemoveLiquidity: boolean;
  shouldCallAfterRemoveLiquidity: boolean;
  hooksContract: Address;
};

///////////////////
// Pool Action Forms
//////////////////

export interface PoolActionsProps {
  pool: Pool;
  refetchPool: RefetchPool;
  tokenBalances: TokenBalances;
  refetchTokenBalances: () => void;
}

export type SwapConfig = {
  tokenIn: {
    poolTokensIndex: number;
    amount: string;
    rawAmount: bigint;
  };
  tokenOut: {
    poolTokensIndex: number;
    amount: string;
    rawAmount: bigint;
  };
  swapKind: SwapKind;
};

export type TokenAmountDetails = {
  symbol: string;
  name: string;
  rawAmount: bigint;
  decimals: number;
};

export type PoolOperationReceipt = {
  data: TokenAmountDetails[];
  transactionHash: string;
} | null;

export type TransactionHash = string | null;

///////////////////////
// Token Hooks
//////////////////////

export type TokenBalances = { [key: Address]: bigint };

export type UseTokens = {
  tokenAllowances: (bigint | undefined)[] | undefined;
  refetchTokenAllowances: () => void;
  tokenBalances: TokenBalances;
  refetchTokenBalances: () => void;
};

export type UseApprove = {
  approveSpenderOnToken: () => Promise<WriteContractResult>;
  approveSpenderOnPermit2: () => Promise<WriteContractResult>;
};

export type Permit2Allowance = {
  result?: [bigint, number, number] | unknown; // [amount, nonce, expiry]
  status: "success" | "failure";
  error?: Error | undefined;
};
