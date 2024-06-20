import { SwapKind, TokenAmount } from "@balancer/sdk";
import { type Address } from "viem";

// Pool Data
export type Pool = {
  address: Address;
  decimals: number;
  isRegistered: boolean;
  name: string;
  symbol: string;
  userBalance: bigint;
  poolConfig: PoolConfig | undefined;
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
  // hooks: {
  //   shouldCallAfterAddLiquidity: boolean;
  //   shouldCallAfterInitialize: boolean;
  //   shouldCallAfterRemoveLiquidity: boolean;
  //   shouldCallAfterSwap: boolean;
  //   shouldCallBeforeAddLiquidity: boolean;
  //   shouldCallBeforeInitialize: boolean;
  //   shouldCallBeforeRemoveLiquidity: boolean;
  //   shouldCallBeforeSwap: boolean;
  // };
};

// Pool Actions
export type QueryPoolActionError = { message: string } | null;
export type TransactionHash = string | null;

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
