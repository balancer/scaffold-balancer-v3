interface NetworkConfigEntryTypes {
  name: string;
  balancer: {
    vaultAddr: string;
    vaultExtensionAddr: string;
    routerAddr: string;
    batchRouterAddr: string;
  };
  customPool: {
    name: string;
    tokenConfig: {
      token: string;
      tokenType: number;
      rateProvider: string;
      yieldFeeExempt: boolean;
    }[];
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
    customPool: {
      name: "ConstantPricePool",
      tokenConfig: [
        {
          token: "0xB77EB1A70A96fDAAeB31DB1b42F2b8b5846b2613", // sepoliaDAI
          tokenType: 0, // STANDARD
          // https://docs-v3.balancer.fi/reference/contracts/rate-providers.html#none-of-the-assets
          rateProvider: "0x0000000000000000000000000000000000000000",
          yieldFeeExempt: false,
        },
        {
          token: "0x80D6d3946ed8A1Da4E226aa21CCdDc32bd127d1A", // sepoliaUSDC
          tokenType: 0, // STANDARD
          // https://docs-v3.balancer.fi/reference/contracts/rate-providers.html#none-of-the-assets
          rateProvider: "0x0000000000000000000000000000000000000000",
          yieldFeeExempt: false,
        },
      ],
    },
  },
};

const developmentChains: string[] = ["hardhat", "foundry", "localhost"];

export { networkConfig, developmentChains };
