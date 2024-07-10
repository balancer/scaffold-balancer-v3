# 🏗️ Scaffold Balancer v3

A full stack prototyping tool for building on top of Balancer v3. Accelerate the process of designing and deploying custom pools and hooks contracts. Concentrate on mastering the core concepts within a swift and responsive environment augmented by a local fork and a frontend pool operations playground.

### 🛠️ Tech Stack

| [Balancer SDK](https://github.com/balancer/b-sdk) | [Scaffold ETH 2](https://scaffold-eth-2-docs.vercel.app/) | [Balancer v3 Monorepo](https://github.com/balancer/balancer-v3-monorepo) |
| ------------------------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------ |

### 📚 Prerequisites

- Basic understanding of [Solidity](https://docs.soliditylang.org/) and [Foundry](https://book.getfoundry.sh/)
- Basic understanding of [liquidity pools](https://www.youtube.com/watch?v=cizLhxSKrAc) and [AMMs](https://chain.link/education-hub/what-is-an-automated-market-maker-amm)
- Basic understanding of [Balancer v3](https://docs-v3.balancer.fi/concepts/core-concepts/introduction.html)

### 🪧 Table Of Contents

0. [Environment Setup 🧑‍💻](#0-environment-setup-)
1. [Create a Custom Pool 🌊](#1-create-a-custom-pool-)
2. [Create a Pool Factory 🏭](#2-create-a-pool-factory-)
3. [Create a Pool Hook 🪝](#3-create-a-pool-hook-)
4. [Deploy the Contracts 🚢](#4-deploy-a-pool-factory-)
5. [Test the Contracts 🧪](#5-test-the-contracts-)

## 0. Environment Setup 🧑‍💻

### 📜 Requirements

- [Node (>= v18.17)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### 🏃 Quickstart

1. Clone this repo & install dependencies

```bash
git clone https://github.com/balancer/scaffold-balancer-v3.git
cd scaffold-balancer-v3
yarn install
```

2. Set the necessary environment variables in a `packages/foundry/.env` file

```
DEPLOYER_PRIVATE_KEY=0x...
SEPOLIA_RPC_URL=...
```

- The `DEPLOYER_PRIVATE_KEY` must start with `0x` and must possess enough Sepolia ETH to deploy the contracts
- The `SEPOLIA_RPC_URL` facilitates running a local fork and sending transactions to sepolia testnet

3. Start a local anvil fork of the Sepolia testnet

```bash
yarn fork
```

4. Deploy the mock tokens, pool factories, pool hooks, and custom pools contracts

```bash
yarn deploy
```

- The `DEPLOYER_PRIVATE_KEY` wallet receives the mock tokens and resulting BPT from pool initialization

5. Start the Frontend

```bash
yarn start
```

6. Explore the Frontend

- Navigate to http://localhost:3000 to see the home page
- Visit the [Pools Page](http://localhost:3000/pools) to search by address or select using the pool buttons
- Vist the [Debug Page](http://localhost:3000/debug) to see the mock tokens, factory, and hooks contracts

### 🏗️ Scaffold ETH 2 Tips

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

Your journey begins with planning the custom computation logic for the pool, which defines how an AMM exchanges one asset for another.

### 📖 Review the Docs

- [Create a custom AMM with a novel invariant](https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/create-custom-amm-with-novel-invariant.html)

### 🔑 Recall the Key Requirements

- Must inherit from `IBasePool` and `BalancerPoolToken`
- Must implement `onSwap`, `computeInvariant`, and `computeBalance`
- Must implement `getMaximumSwapFeePercentage` and `getMinimumSwapFeePercentage`

### 📝 Write a Custom Pool Contract

- To get started, edit the`ConstantSumPool.sol` contract directly or make a copy

## 2. Create a Pool Factory 🏭

After designing a pool contract, the next step is to prepare a factory contract because Balancer's off-chain infrastructure uses the factory address as a means to identify the type of pool, which is important for integration into the UI, SDK, and external aggregators

### 📖 Review the Docs

- [Deploy a Custom AMM Using a Factory](https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/deploy-custom-amm-using-factory.html)

### 🔑 Recall the Key Requirements

- A pool factory contract must inherit from [BasePoolFactory](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/vault/contracts/factories/BasePoolFactory.sol)
- Use the internal `_create` function to deploy a new pool
- Use the internal `_registerPoolWithVault` fuction to register a pool immediately after creation

### 📝 Write a Factory Contract

- To get started, edit the`ConstantSumFactory.sol` contract directly or make a copy

## 3. Create a Pool Hook 🪝

Next, consider further extending the functionality of the custom pool contract with a hooks contract. If your custom pool does not need a hooks contract, use the zero address during pool registration

### 📖 Review the Docs

- [Extend an Existing Pool Type Using Hooks](https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/extend-existing-pool-type-using-hooks.html)

### 🔑 Recall the Key Requirements

- A hooks contract must inherit from [BasePoolHooks.sol](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/vault/contracts/BaseHooks.sol)
- Must implement `getHookFlags` to define which hooks are supported
- Must implement `onRegister` to determine if a pool is allowed to use the hook contract

### 📝 Write a Hook Contract

- To get started, edit the `VeBALFeeDiscountHook.sol` contract directly or make a copy

## 4. Deploy the Contracts 🚢

The deploy scripts are all located in the [foundry/script/](https://github.com/balancer/scaffold-balancer-v3/tree/main/packages/foundry/script) directory and are prefixed with a number based on the order the order they're intended to be run. The mock tokens, factories, and hooks contracts must be deployed before the pools. On the frontend, the [Pools](http://localhost:3000/pools) page will automatically add a button above the search bar for any pools deployed using the latest factory contract

### 🛠️ Adjust the Deploy Scripts

#### `00_DeploySetup.s.sol`

Deploys mock tokens, factory contracts, and hooks contracts to be used by pools

- Set the `pauseWindowDuration` for the factory contracts
- Set the mock token names, symbols, and supply
- Set any hooks contracts constructor args

#### `01_DeployConstantSumPool.s.sol`

Deploys, registers, and initializes a Constant Sum Pool

- Set the pool registration config in the `getRegistrationConfig()` function
- Set the pool initialization config in the `getInitializationConfig()` function

#### `02_DeployConstantProductPool.s.sol`

Deploys, registers, and initializes a Constant Product Pool

- Set the pool registration config in the `getRegistrationConfig()` function
- Set the pool initialization config in the `getInitializationConfig()` function

### 📡 Broadcast the Transactions

To run all the deploy scripts

```bash
yarn deploy
```

To run only the `DeploySetup` script

```bash
yarn deploy:setup
```

To run only the `DeployConstantSumPool` script

```bash
yarn deploy:sum
```

To run only the `DeployConstantProductPool` script

```bash
yarn deploy:product
```

🛈 To deploy to the live sepolia testnet, add the `--network sepolia` flag
🛈 To modify the yarn commands, edit the "scripts" section of the [/foundry/package.json](https://github.com/balancer/scaffold-balancer-v3/blob/main/packages/foundry/package.json)

## 5. Test the Contracts 🧪

Sample tests for the `ConstantSumPool` and `ConstantSumFactory` are provided as examples to help you get started writing your own tests.

### 👨‍🔬 Testing Factories

The `ConstantSumFactoryTest` roughly mirrors the [WeightedPool8020FactoryTest
](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/pool-weighted/test/foundry/WeightedPool8020Factory.t.sol)

```
yarn test --match-contract ConstantSumFactoryTest
```

### 🏊 Testing Pools

The `ConstantSumPoolTest` roughly mirrors the [WeightedPoolTest](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/pool-weighted/test/foundry/WeightedPool.t.sol)

```
yarn test --match-contract ConstantSumPoolTest
```

### 🎣 Testing Hooks

- Coming soon™️ after update to 6th testnet deployment of v3
