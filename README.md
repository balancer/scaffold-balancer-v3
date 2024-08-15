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

- [🧑‍💻 Environment Setup](#0-environment-setup-)
- [🌊 Create a Custom Pool](#1-create-a-custom-pool-)
- [🏭 Create a Pool Factory](#2-create-a-pool-factory-)
- [🪝 Create a Pool Hook](#3-create-a-pool-hook-)
- [🚢 Deploy the Contracts](#4-deploy-the-contracts-)
- [🧪 Test the Contracts](#5-test-the-contracts-)

## 🧑‍💻 Environment Setup

<!-- TODO: Record Updated Video -->
<!-- [![image](https://github.com/user-attachments/assets/2d0d5c6d-647d-4782-8d7a-9076b39319b9)](https://www.youtube.com/watch?v=2lInvpCt2o4) -->

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

2. Set the necessary environment variables in a `packages/foundry/.env` file [^1]
   [^1]: The `DEPLOYER_PRIVATE_KEY` must start with `0x` and must possess enough Sepolia ETH to deploy the contracts. The `SEPOLIA_RPC_URL` facilitates running a local fork and sending transactions to sepolia testnet

```
DEPLOYER_PRIVATE_KEY=0x...
SEPOLIA_RPC_URL=...
```

3. Start a local anvil fork of the Sepolia testnet

```bash
yarn fork
```

4. Deploy the mock tokens, pool factories, pool hooks, and custom pools contracts [^2]
   [^2]: The `DEPLOYER_PRIVATE_KEY` wallet receives the mock tokens and resulting BPT from pool initialization

```bash
yarn deploy
```

5. Start the nextjs frontend

```bash
yarn start
```

6. Explore the frontend

- Navigate to http://localhost:3000 to see the home page
- Visit the [Pools Page](http://localhost:3000/pools) to search by address or select using the pool buttons
- Vist the [Debug Page](http://localhost:3000/debug) to see the mock tokens, factory, and hooks contracts

7. Run the Foundry tests

```
yarn test
```

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

## 🌊 Create a Custom Pool

Your journey begins with planning the custom computation logic for the pool, which defines how an AMM exchanges one asset for another.

### 📖 Review the Docs

- [Create a custom AMM with a novel invariant](https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/create-custom-amm-with-novel-invariant.html)

### 🔑 Recall the Key Requirements

- Must inherit from `IBasePool` and `BalancerPoolToken`
- Must implement `onSwap`, `computeInvariant`, and `computeBalance`
- Must implement `getMaximumSwapFeePercentage` and `getMinimumSwapFeePercentage`

### 📝 Write a Custom Pool Contract

- To get started, edit the`ConstantSumPool.sol` contract directly or make a copy

## 🏭 Create a Pool Factory

After designing a pool contract, the next step is to prepare a factory contract because Balancer's off-chain infrastructure uses the factory address as a means to identify the type of pool, which is important for integration into the UI, SDK, and external aggregators

### 📖 Review the Docs

- [Deploy a Custom AMM Using a Factory](https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/deploy-custom-amm-using-factory.html)

### 🔑 Recall the Key Requirements

- A pool factory contract must inherit from [BasePoolFactory](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/vault/contracts/factories/BasePoolFactory.sol)
- Use the internal `_create` function to deploy a new pool
- Use the internal `_registerPoolWithVault` fuction to register a pool immediately after creation

### 📝 Write a Factory Contract

- To get started, edit the`ConstantSumFactory.sol` contract directly or make a copy

## 🪝 Create a Pool Hook

Next, consider further extending the functionality of the custom pool contract with a hooks contract. If your custom pool does not need a hooks contract, use the zero address during pool registration

### 📖 Review the Docs

- [Extend an Existing Pool Type Using Hooks](https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/extend-existing-pool-type-using-hooks.html)

### 🔑 Recall the Key Requirements

- A hooks contract must inherit from [BasePoolHooks.sol](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/vault/contracts/BaseHooks.sol)
- Must implement `getHookFlags` to define which hooks are supported
- Must implement `onRegister` to determine if a pool is allowed to use the hook contract

### 📝 Write a Hook Contract

- To get started, edit the `VeBALFeeDiscountHook.sol` contract directly or make a copy

## 🚢 Deploy the Contracts

The deploy scripts are all located in the [foundry/script/](https://github.com/balancer/scaffold-balancer-v3/tree/main/packages/foundry/script) directory. All deploy scripts should be run inside of `Deploy.s.sol` so that the `export` modifier can automate the transfer of deployed contract info to `nextjs/contracts/depoloyedContracts.ts`

### 👯 Follow the Pattern

To add a new deploy script, import it into `Deploy.s.sol`, create a new instance of it, and run it

```
function run() external virtual export {
        DeployYourContract deployYourContract = new DeployYourContract();
        deployYourContract.run();
}
```

### 🛠️ Examine the Example Deploy Scripts

#### `00_DeployMockTokens.s.sol`

1. Deploys mock tokens that are used to register and initialize pools
2. Deploys a mock token used for the example `VeBALFeeDiscountHook` contract

#### `01_DeployConstantSum.s.sol`

1. Deploys a `ConstantSumFactory`
2. Deploys and registers a `ConstantSumPool`
3. Initializes the `ConstantSumPool` using mock tokens

#### `02_DeployConstantProduct.s.sol`

1. Deploys a `ConstantProductFactory`
2. Deploys and registers a `ConstantProductPool`
3. Initializes the `ConstantProductPool` using mock tokens

### 📡 Broadcast the Transactions

To run all the deploy scripts

```bash
yarn deploy
```

🛈 To deploy to the live sepolia testnet, add the `--network sepolia` flag

## 🧪 Test the Contracts

The [balancer-v3-monorepo](https://github.com/balancer/balancer-v3-monorepo) provides testing utility contracts like [BaseVaultTest](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/vault/test/foundry/utils/BaseVaultTest.sol). Therefore, the best way to begin writing tests for custom factory, pool, and hook contracts is to utilize the patterns and methods established by the source code.

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

The `VeBALFeeDiscountHookTest` mirrors the [VeBALFeeDiscountHookExampleTest](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/pool-hooks/test/foundry/VeBALFeeDiscountHookExample.t.sol)

```
yarn test --match-contract VeBALFeeDiscountHookTest
```
