import { formatUnits } from "viem";

export const formatToHuman = (amount: bigint, decimals: number, to = 4): string => {
  return Number(formatUnits(amount || 0n, decimals)).toFixed(to);
};

export const formatToPercentage = (value: bigint) => {
  const scale = BigInt("1000000000000000000"); // 1e18
  // Multiply first to maintain precision in the calculation
  const swapFee = (value * 10000n) / scale; // Multiplying by a larger number to retain more precision
  // Convert to number and then adjust to the percentage format
  const percentage = Number(swapFee) / 100; // Now divide by 100 here to adjust back to a proper percentage
  return `${percentage}%`; // Format to two decimal places
};
