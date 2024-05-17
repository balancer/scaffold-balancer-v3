import { formatUnits } from "viem";

/**
 * Formats the token amount with the specified number of decimals and returns it
 * as a string with four decimal places.
 */
export const formatToHuman = (amount: bigint, decimals: number): string => {
  return Number(formatUnits(amount || 0n, decimals)).toFixed(4);
};
