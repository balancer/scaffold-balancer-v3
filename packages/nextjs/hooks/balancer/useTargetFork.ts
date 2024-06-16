import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import scaffoldConfig from "~~/scaffold.config";

export const useTargetFork = () => {
  const { targetNetwork } = useTargetNetwork();

  const rpcUrl = targetNetwork.rpcUrls.default.http[0];

  let chainId = targetNetwork.id;
  // If using local network, use the chainId from scaffoldConfig's targetFork
  if (targetNetwork.id === 31337) {
    chainId = scaffoldConfig.targetFork.id;
  }

  return { rpcUrl, chainId };
};
