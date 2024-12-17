import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import { contracts } from "~~/utils/scaffold-eth/contract";

export function useGetAllContracts() {
  const { targetNetwork } = useTargetNetwork();

  const contractsData = contracts?.[targetNetwork.id];
  return contractsData ? contractsData : {};
}
