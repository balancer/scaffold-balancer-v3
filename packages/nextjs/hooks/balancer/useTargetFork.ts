import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import scaffoldConfig from "~~/scaffold.config";

export const useTargetFork = () => {
  const { targetNetwork } = useTargetNetwork();

  let rpcUrl;
  // gnosis does not support alchemy?
  if (targetNetwork.id === 100) {
    rpcUrl = targetNetwork.rpcUrls.default.http[0];
  } else {
    // default rpc url is not supported for sepolia or mainnet
    rpcUrl = targetNetwork.rpcUrls.alchemy.http[0] + "/" + scaffoldConfig.alchemyApiKey;
  }

  let chainId = targetNetwork.id;
  // If using local network, use the chainId from scaffoldConfig's targetFork
  if (targetNetwork.id === 31337) {
    chainId = scaffoldConfig.targetFork.id;
  }

  return { rpcUrl, chainId };
};
