# 🏗 Scaffold Balancer v3

A full stack prototyping tool for building on top of Balancer v3. Accelerate the process of designing and deploying custom pools and hooks contracts. Concentrate on mastering the core concepts within a swift and responsive environment augmented by a local fork and a frontend pool operations playground.

### 🛠️ Tech Stack

| [Balancer SDK](https://github.com/balancer/b-sdk) | [Scaffold ETH 2](https://scaffold-eth-2-docs.vercel.app/) | [Balancer v3 Monorepo](https://github.com/balancer/balancer-v3-monorepo) |
| ------------------------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------ |

### 📚 Prerequisites

- Basic understanding of [Solidity](https://docs.soliditylang.org/) and [Foundry](https://book.getfoundry.sh/)
- Basic understanding of [liquidity pools](https://www.youtube.com/watch?v=cizLhxSKrAc) and [AMMs](https://chain.link/education-hub/what-is-an-automated-market-maker-amm)
- Basic understanding of [Balancer v3](https://docs-v3.balancer.fi/concepts/core-concepts/introduction.html)

### 🎥 Getting Started Demo

[![Getting Started Demo](https://github.com/balancer/scaffold-balancer-v3/assets/73561520/48c67ccc-9edf-48c8-a310-eb06663b6a01)](https://www.youtube.com/watch?v=r0UPuMCxeDs)

### 🪧 Table Of Contents

0. [Environment Setup 🧑‍💻](#0-Environment-Setup-🧑%E2%80%8D💻)
1. [Create a Custom Pool 🌊](#1-Create-a-Custom-Pool-🌊)
2. [Create a Pool Factory 🏭](#2-Create-a-Pool-Factory-🏭)
3. [Create a Pool Hook 🪝](#3-Create-a-Pool-Hook-🪝)
4. [Deploy a Pool Factory 🚢](#4-Deploy-a-Pool-Factory-🚢)
5. [Deploy a Custom Pool ⛵](#5-Deploy-a-Custom-Pool-⛵)
6. [Test the Contracts 🧪](#6-Test-the-Contracts-🧪)

## 0. Environment Setup 🧑‍💻

### 📜 0.1 Requirements

- [Node (>= v18.17)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### 🏃 0.2 Quickstart

#### 0.2.1 Clone the Repository

```bash
git clone https://github.com/balancer/scaffold-balancer-v3.git
```

#### 0.2.2 Install the Dependencies

```bash
yarn install
```

#### 0.2.3 Set environment variables

Set the necessary environment variables in a `packages/foundry/.env` file

```
DEPLOYER_PRIVATE_KEY=0x...
SEPOLIA_RPC_URL=...
```

- The `DEPLOYER_PRIVATE_KEY` must start with `0x`
- The `SEPOLIA_RPC_URL` facilitates running a local fork and sending transactions to sepolia testnet

#### 0.2.4 Start a Local Fork

By default, this project runs on a local anvil fork of the Sepolia testnet

```bash
yarn fork
```

#### 0.2.5 Deploy Contracts

All contracts are deployed from the wallet associated to the `DEPLOYER_PRIVATE_KEY` specified in the `.env`. By default, this wallet receives mock tokens and the resulting BPT from pool initialization

Deploy the pool factory, mock tokens, and hooks contracts

```bash
yarn deploy:factory
```

Deploy, register, and initialize pool #1

```bash
yarn deploy:pool1
```

Deploy, register, and initialize pool #2

```bash
yarn deploy:pool2
```

#### 0.2.6 Start the Frontend

```bash
yarn start
```

#### 0.2.7 Explore the Frontend

- Navigate to http://localhost:3000 to see the home page
- Visit the [Pools Page](http://localhost:3000/pools) to search by address or select using the buttons
- Vist the [Debug Page](http://localhost:3000/debug) to see the mock tokens, factory, and hooks contracts

### 💁 0.3 Scaffold ETH 2 Tips

SE-2 offers a variety of configuration options for connecting an account, choosing networks, and deploying contracts

<details><summary><strong>🔥 Burner Wallet</strong></summary>

If you do not have an active wallet extension connected to your web browser, then scaffold eth will automatically connect to a "burner wallet" that is randomly generated on the frontend and saved to the browser's local storage. When using the burner wallet, transactions will be instantly signed, which is convenient for quick iterative development.

To force the use of burner wallet, disable your browsers wallet extensions and refresh the page. Note that the burner wallet comes with 0 ETH to pay for gas so you will need to click the faucet button in top right corner. Also the mock tokens for the pool are minted to your deployer account set in `.env` so you will want to navigate to the "Debug Contracts" page to mint your burner wallet some mock tokens to use with the pool.

![Burner Wallet](https://github.com/Dev-Rel-as-a-Service/scaffold-balancer-v3/assets/73561520/0a1f3456-f22a-46b5-9e05-0ef5cd17cce7)

![Debug Tab Mint](https://github.com/Dev-Rel-as-a-Service/scaffold-balancer-v3/assets/73561520/fbb53772-8f6d-454d-a153-0e7a2925ef9f)

</details>

<details><summary><strong>👛 Browser Extension Wallet</strong></summary>
    
- To use your preferred browser extension wallet, ensure that the account you are using matches the PK you previously provided in the `foundry/.env` file
- You may need to add a local development network with rpc url `http://127.0.0.1:8545/` and chain id `31337`. Also, you may need to reset the nonce data for your wallet exension if it gets out of sync.

</details>

<details><summary><strong>🐛 Debug Contracts Page </strong></summary>

The [Debug Contracts Page](http://localhost:3000/debug) can be useful for viewing and interacting with all of the externally avaiable read and write functions of a contract. The page will automatically hot reload with contracts that are deployed via the `01_DeployConstantSumFactory.s.sol` script. We use this handy setup to mint `mockERC20` tokens to any connected wallet

</details>

<details><summary><strong>🌐 Changing The Frontend Network Connection</strong></summary>

- The network the frontend points at is set via `targetNetworks` in the `scaffold.config.ts` file using `chains` from viem.
- By default, the frontend runs on a local node at `http://127.0.0.1:8545`

```typescript
const scaffoldConfig = {
  targetNetworks: [chains.foundry],
```

</details>

<details><summary><strong>🍴 Changing The Forked Network</strong></summary>

- By default, the `yarn fork` command points at sepolia, but any of the network aliases from the `[rpc_endpoints]` of `foundry.toml` can be used to modify the `"fork"` alias in the `packages/foundry/package.json` file

```json
	"fork": "anvil --fork-url ${0:-sepolia} --chain-id 31337 --config-out localhost.json",
```

- To point the frontend at a different forked network, change the `targetFork` in `scaffold.config.ts`

```typescript
const scaffoldConfig = {
  // The networks the frontend can connect to
  targetNetworks: [chains.foundry],

  // If using chains.foundry as your targetNetwork, you must specify a network to fork
  targetFork: chains.sepolia,
```

</details>

## 1. Create a Custom Pool 🌊

Your journey begins with planning the custom computation logic for the pool

### 📖 1.1 Review the Docs

- [Create a custom AMM with a novel invariant](https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/create-custom-amm-with-novel-invariant.html)

### 🔑 1.2 Recall the Key Requirements

- Must inherit from `IBasePool` and `BalancerPoolToken`
- Must implement `onSwap`, `computeInvariant`, and `computeBalance`
- Must implement `getMaximumSwapFeePercentage` and `getMinimumSwapFeePercentage`

### 📝 1.3 Write a Custom Pool Contract

- To get started, edit the`ConstantSumPool.sol` contract directly or make a copy

## 2. Create a Pool Factory 🏭

After designing a pool contract, the next step is to prepare a factory contract because Balancer's off-chain infrastructure uses the factory address as a means to identify the type of pool, which is important for integration into the UI, SDK, and external aggregators

### 📖 2.1 Review the Docs

- Coming soon™️
- View the `FactoryWidePauseWindow` for full details about the `pauseWindowDuration` constructor param

### 🔑 2.2 Recall the Key Requirements

- A pool factory contract must inherit from [BasePoolFactory](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/vault/contracts/factories/BasePoolFactory.sol)
- Use the internal `_create` function to deploy a new pool
- Use the internal `_registerPoolWithVault` fuction to register a pool immediately after creation

### 📝 2.3 Write a Factory Contract

To get started, try editing the`ConstantSumFactory.sol` contract directly or make a copy

## 3. Create a Pool Hook 🪝

Next, consider further extending the functionality of the custom pool contract with a hooks contract or if your custom pool does not need a hooks contract, simply pass the zero address during registration via factory

### 📖 3.1 Review the Docs

- [Extend an Existing Pool Type Using Hooks](https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/extend-existing-pool-type-using-hooks.html)

### 🔑 3.2 Recall the Key Requirements

- A hook contract must inherit from [BasePoolHooks.sol](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/vault/contracts/BaseHooks.sol)
- Must implement `getHookFlags` to define which hooks are supported
- Must implement `onRegister` to determine if a pool is allowed to use the hook contract

### 📝 3.3 Write a Hook Contract

- To get started, try editing the`VeBALFeeDiscountHook.sol` contract directly or make a copy

## 4. Deploy a Pool Factory 🚢

Use the `DeployConstantSumFactory` script as a starting point. The

### 🕵️ 4.1 Examine the Deploy Script

- Deploys a factory contract using the pool contract creation code specified in `ConstantSumFactory`
- Deploys mock tokens used for the params of the hooks contract
- Deploys a hooks contract using the `vault` and `router` addresses set in `HelperConfig`

### 🛠️ 4.2 Adjust the Deploy Script

- The `pauseWindowDuration` for the factory is set in `HelperConfig`
- Option to change the mock token names
- Option to deploy a hook contract

### 📡 4.2 Broadcast the Transaction

To send the deployment transaction(s) to your local anvil fork

```bash
yarn deploy:factory
```

🛈 To send the deployment transactions to live sepolia testnet, add the `--network sepolia` flag

## 5. Deploy a Custom Pool ⛵

After the factory contract has been deployed, pools can be deployed and registered using the `DeployConstantSumPool1` and `DeployConstantSumPool2` scripts. Both scripts also handle initialization of the pool. The [Pools](http://localhost:3000/pools) page will automatically add a button above the search bar for any pools deployed using the latest factory contract

### 🕵️ 5.1 Examine the Deploy Scripts

- Both scripts deploy a pool using the most recently deployed factory contract
- Both scripts use `initializePool` helper function which handles the necessary Permit2 approval process before calling `router.intialize`
- `DeployConstantSumPool1` pulls **all** the registration and initialization configurations from `HelperConfig`
  - The default `HelperConfig` does not use a `poolHooksContract`
- `DeployConstantSumPool2` pulls **only some** of the registration and initialization configurations from `HelperConfig`
  - This script uses the most recently deployed `VeBALFeeDiscountHook` during pool registration

### 🛠️ 5.2 Adjust the Deploy Scripts

- Modify the pool registration config ( `name`, `symbol`, `tokenConfig`, ect. )
- Modify the pool initialization config ( `exactAmountsIn`, `minBptAmountOut`, `wethIsEth`)
- Avoid "stack too deep" errors by leveraging `HelperConfig` or passing values directly to `factory.create` and `initializePool`

### 📡 5.3 Broadcast the Transaction

To deploy the first pool to your local fork

```bash
yarn deploy:pool1
```

To deploy the second pool to your local fork

```bash
yarn deploy:pool2
```

🛈 To send the deployment transactions to live sepolia testnet, add the `--network sepolia` flag

## 6. Test the Contracts 🧪

⚠️ This guide is incomplete

Run the foundry tests with the `yarn test` command

Sample tests for the `ConstantSumPool` and `ConstantSumFactory` are provided as examples to help you get started writing your own tests.

### 👨‍🔬 6.1 Testing Factories

The `ConstantSumFactoryTest` roughly mirrors the [WeightedPool8020FactoryTest
](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/pool-weighted/test/foundry/WeightedPool8020Factory.t.sol) from the v3-monorepo

```
yarn test --match-contract ConstantSumFactoryTest
```

### 🏊 6.2 Testing Pool

The `ConstantSumPoolTest` roughly mirrors the [WeightedPoolTest](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/pool-weighted/test/foundry/WeightedPool.t.sol) from the v3-monorepo

```
yarn test --match-contract ConstantSumPoolTest
```

### 🎣 6.3 Testing Hooks

- Coming soon™️
