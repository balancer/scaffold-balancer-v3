# 🏗 Scaffold-Balancer

⚖️ Balancer is a decentralized automated market maker (AMM) protocol built on Ethereum that represents a flexible building block for programmable liquidity.

🛠️ This repo is a series of guides and a prototyping tools for creating custom pools that integrate with Balancer v3

## Checkpoint 0: 📦 Environment 📚

### 0.1 Requirements

Before you begin, you need to install the following tools:

- [Node (>= v18.17)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

### 0.2 Quickstart

1. Clone the repo

```
git clone git@github.com:MattPereira/scaffold-balancer-v3.git
```

2. Install dependencies

```
yarn install
```

3. Start Frontend

```
yarn start
```

📱 Open http://localhost:3000 to see the app.

### 0.3 Set Environment Variables

In order to deploy new custom pool contracts on sepolia and execute scripts, you must set a `DEPLOYER_PRIVATE_KEY` at the path `packagages/hardhat/.env` (And your PK must have testnet sepolia ETH)

## Checkpoint 1: 🌊 Create A Custom Pool

### 1.1 Write a Custom Pool Contract

- All custom pool contracts must inherit from `IBasePool` and `BalancerPoolToken` and impliment the three required functions: `onSwap`, `computeInvariant`, and `computeBalance`

- Begin your journey by reading the [docs on creating a custom pool](https://docs-v3.balancer.fi/concepts/guides/create-custom-amm-with-novel-invariant.html#build-your-custom-amm)

### 1.2 Modify the Deploy Script

- You must modify the deploy script to match your custom pool contract names and constructor arguments
- Deploy scripts can be found at `packages/hardhat/deploy`

### 1.3 Deploying your Custom Pool

- Run the deploy script

```
yarn deploy --network sepolia
```

👀 Notice that whenever you deploy new contract the scaffold eth frontend will automatically update to point at the newly deployed contract

### 1.4 Register a new pool with the Vault

Before a pool can be initialized, it must be registered with the Vault. This is the step where the pool declares what tokens it will manage, which hooks the pool supports, and other configuration.

1. Modify the `registerPool.ts` script and `helper.config.ts` file with your desired `registerPool` args
   - [👀 docs on `VaultExtension.registerPool`](https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#registerpool)
2. From the terminal, move into the `packages/hardhat` directory and execute the script

```
yarn hardhat run scripts/registerPool.ts --network sepolia
```

### 1.5 Initialize the Pool

1. Modify the `initializePool.ts` script with your desired `initialize` args

   - [👀 docs on`Router.initialize`](https://docs-v3.balancer.fi/concepts/router/overview.html#initialize)

2. From the terminal, move into the `packages/hardhat` directory and execute the script

```
yarn hardhat run scripts/initializePool.ts --network sepolia
```

### 1.6 Interact with your custom pool

- On the `localhost:3000/pools` page, select your custom pool from the dropdown
- Review the pool details and composition post pool initialization
- Try out executing a swap, join, and exit with your custom pool

## Checkpoint 2: 🧭 Integrate pool with the Smart Order Router (SOR)

TBD

## Checkpoint 3: 📡 Integrate pool with the Balancer v3 Subgraph

TBD

test
