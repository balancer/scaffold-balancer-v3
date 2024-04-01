import { type Address } from "viem";

export type Pool = {
  address: Address | undefined;
  decimals: number;
  isRegistered: boolean;
  name: string;
  symbol: string;
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
  hasDynamicSwapFee: boolean;
  isPoolRegistered: boolean;
  isPoolInitialized: boolean;
  isPoolPaused: boolean;
  isPoolInRecoveryMode: boolean;
  pauseWindowEndTime: number;
  staticSwapFeePercentage: bigint;
  tokenDecimalDiffs: number;
  liquidityManagement: {
    supportsAddLiquidityCustom: boolean;
    supportsRemoveLiquidityCustom: boolean;
  };
  hooks: {
    shouldCallAfterAddLiquidity: boolean;
    shouldCallAfterInitialize: boolean;
    shouldCallAfterRemoveLiquidity: boolean;
    shouldCallAfterSwap: boolean;
    shouldCallBeforeAddLiquidity: boolean;
    shouldCallBeforeInitialize: boolean;
    shouldCallBeforeRemoveLiquidity: boolean;
    shouldCallBeforeSwap: boolean;
  };
};
