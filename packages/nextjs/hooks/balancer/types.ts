// import { Address } from "viem";

export type Pool = {
  name: string | undefined;
  address: string | undefined;
  vaultAddress: string | undefined;
  symbol: string | undefined;
  decimals: number | undefined;
  totalSupply: bigint | undefined;
};
