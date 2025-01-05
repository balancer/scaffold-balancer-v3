import { formatUnits, isHex, toHex } from "viem";

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

/**
 * Converts a string input to a hex string with '0x' prefix
 * Handles three cases:
 * 1. Already hex string: returns as-is
 * 2. Numeric string: converts to hex number
 * 3. Regular string: converts to hex representation of ASCII
 *
 * @param input - The string to convert
 * @returns A hex string prefixed with '0x'
 * @example
 * toHexString("0x123") // returns "0x123"
 * toHexString("42") // returns "0x2a"
 * toHexString("hello") // returns "0x68656c6c6f"
 */
export const formatToHex = (input: string): `0x${string}` => {
  // If already hex, return as-is
  if (isHex(input)) return input;

  // Check if string is numeric
  const isNumeric = (str: string): boolean => /^\d+$/.test(str);

  // If numeric, convert to hex number
  if (isNumeric(input)) {
    return `0x${Number(input).toString(16)}`;
  }

  // Otherwise convert string to hex
  return toHex(input);
};
