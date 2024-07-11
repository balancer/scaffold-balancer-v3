import { SwapKind, TokenAmount } from "@balancer/sdk";
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
// Pool Hooks
//////////////////

export type UseSwap = {
  querySwap: () => Promise<QuerySwapResponse>;
  swap: () => Promise<TransactionHash>;
};

export type UseAddLiquidity = {
  queryAddLiquidity: () => Promise<QueryAddLiquidityResponse>;
  addLiquidity: () => Promise<TransactionHash>;
};

export type UseRemoveLiquidity = {
  queryRemoveLiquidity: (rawAmount: bigint) => Promise<QueryRemoveLiquidityResponse>;
  removeLiquidity: () => Promise<TransactionHash>;
};

///////////////////
// Pool Action Forms
//////////////////
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

export type QueryPoolActionError = { message: string } | null;

export type QuerySwapResponse = {
  swapKind?: SwapKind;
  expectedAmount?: TokenAmount;
  minOrMaxAmount?: TokenAmount;
  error?: QueryPoolActionError;
};

export type QueryAddLiquidityResponse = {
  expectedBptOut?: TokenAmount;
  minBptOut?: TokenAmount;
  error?: QueryPoolActionError;
};

export type QueryRemoveLiquidityResponse = {
  expectedAmountsOut?: TokenAmount[];
  minAmountsOut?: TokenAmount[];
  error?: QueryPoolActionError;
};

export type TokenInfo = {
  symbol: string;
  name: string;
  rawAmount: bigint;
  decimals: number;
};

export type PoolActionReceipt = {
  data: TokenInfo[];
  transactionHash: string;
} | null;

export type TransactionHash = string | null;

///////////////////////
// Token Hooks
//////////////////////

export type UseToken = {
  tokenAllowance: bigint;
  tokenBalance: bigint;
  refetchTokenAllowance: () => void;
  refetchTokenBalance: () => void;
};

export type UseTokens = {
  tokenAllowances: (bigint | undefined)[] | undefined;
  refetchTokenAllowances: () => void;
  tokenBalances?: (bigint | undefined)[];
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
