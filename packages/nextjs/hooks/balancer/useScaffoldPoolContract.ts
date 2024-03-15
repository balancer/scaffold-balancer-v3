import type { Pool } from "./types";
import { useDeployedContractInfo, useScaffoldContractRead } from "~~/hooks/scaffold-eth";

type DeployedPoolNames = "ConstantPricePool" | "DynamicPricePool";

/**
 * @dev naive implementation that uses scaffold hook to get pool contract info
 * @notice scaffold hooks revolve around contract names, not addresses
 */
export const useScaffoldPoolContract = (contractName: DeployedPoolNames): Pool => {
  const { data: deployedContractData } = useDeployedContractInfo(contractName);

  const { data: name } = useScaffoldContractRead({
    contractName,
    functionName: "name",
  });

  const { data: symbol } = useScaffoldContractRead({
    contractName,
    functionName: "symbol",
  });

  const { data: totalSupply } = useScaffoldContractRead({
    contractName,
    functionName: "totalSupply",
  });

  const { data: decimals } = useScaffoldContractRead({
    contractName,
    functionName: "decimals",
  });

  const { data: vaultAddress } = useScaffoldContractRead({
    contractName,
    functionName: "getVault",
  });

  return {
    name,
    address: deployedContractData?.address,
    symbol,
    totalSupply,
    decimals,
    vaultAddress,
  };
};
