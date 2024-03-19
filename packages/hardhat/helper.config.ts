interface NetworkConfigEntryTypes {
  name: string;
  balancer: {
    vaultAddr: string;
    vaultExtensionAddr: string;
    routerAddr: string;
    batchRouterAddr: string;
  };
}

// Contracts have constructors that require contract address args that are network specific
const networkConfig: { [key: number]: NetworkConfigEntryTypes } = {
  11155111: {
    name: "sepolia",
    balancer: {
      vaultAddr: "0x1FC7F1F84CFE61a04224AC8D3F87f56214FeC08c",
      vaultExtensionAddr: "0x718e1176f01dDBb2409A77B2847B749c8dF4457f",
      routerAddr: "0xA0De078cd5cFa7088821B83e0bD7545ccfb7c883",
      batchRouterAddr: "0x8A8B9f35765899B3a0291700141470D79EA2eA88",
    },
  },
};

const developmentChains: string[] = ["hardhat", "foundry", "localhost"];

export { networkConfig, developmentChains };
