import { useDeployedContractInfo, useScaffoldContractRead } from "~~/hooks/scaffold-eth";

export interface PoolDetails {
  name: string | undefined;
  address: string | undefined;
  symbol: string | undefined;
  decimals: number | undefined;
  totalSupply: bigint | undefined;
  vaultAddress: string | undefined;
}

type DeployedPoolNames = "ConstantPricePool";

export const usePoolContract = (contractName: DeployedPoolNames): PoolDetails => {
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
    totalSupply: totalSupply,
    decimals,
    vaultAddress,
  };
};
