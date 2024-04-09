# 🏗 Scaffold-Balancer

⚖️ Balancer is a decentralized automated market maker (AMM) protocol built on Ethereum that represents a flexible building block for programmable liquidity.

🛠️ This repo is a series of guides and a prototyping tools for creating custom pools that integrate with Balancer v3. 

It uses example contracts for a custom pool, custom pool factory, test files, and deployment scripts. The core idea is to help educate developers with creating custom pools and integrating with BalancerV3, and to provide a starting point for developers to create their own custom pools and factories.

✏️ The agenda of this README is listed below:

0. **Checkpoint 0** - 📚 Setup of the environment.
1. **Checkpoint 1** - 🌊 Creating a custom pool, registering, initializing it with balancerV3 vault, and interacting with it.
2. **Checkpoint 2** - 🔧 Creating a custom pool factory, deploying it, and generating a pool from it that you can interact with.
3. **Checkpoint 3** - 🧪 Writing Typical Unit and Fuzz Tests for Custom Pool Example
4. **Checkpoint 4** - 🎨 Creating Your Own Custom Pool with the Template Files
5. **Checkpoint 5** - 📡 Integrate pool with the Balancer v3 Subgraph
6. **Checkpoint 6** - 🧭 Integrate pool with the Smart Order Router (SOR)

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

This checkpoint is all about creating a custom pool, registering it with the BalancerV3 Vault, and initializing it. It is focused on giving you as a dev a scaffolding kit to play with your custom pool.

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

#### 1.4.1 Using Hardhat

Before a pool can be initialized, it must be registered with the Vault. This is the step where the pool declares what tokens it will manage, which hooks the pool supports, and other configuration.

1. Modify the `registerPool.ts` script and `helper.config.ts` file with your desired `registerPool` args
   - [👀 docs on `VaultExtension.registerPool`](https://docs-v3.balancer.fi/concepts/vault/onchain-api.html#registerpool)
2. From the terminal, move into the `packages/hardhat` directory.
3. Execute the script

```
yarn hardhat run scripts/registerPool.ts --network sepolia
```

### 1.4.2 Using Foundry
<!-- 3. Install any submodules. If you have not installed the submodules, probably because you ran `git clone <repo link>`, you may run into errors when running `forge build` since it is looking for the dependencies for the project. `git submodule update --init --recursive` can be used if you clone the repo without installing the submodules. -->


1. While still in the same directory, install forge on your machine if you have not already: `forge install`


  > NOTE: If you need to download the latest version of foundry, just run `foundryup`

2. Run the following CLI command (assuming `.env` is populated appropriately) to simulate registering the pool in question with the vault.

`source .env && forge script scripts/RegisterPool.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY`

3. Run the following CLI command to deploy the script.

`source .env && forge script scripts/RegisterPool.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --slow --broadcast`

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

## Checkpoint 2: 🔧 Create a custom pool factory

Now that you have created a custom pool, it is time to deploy the associated custom pool factory. For this repo, we've created a custom pool factory example and associated script to deploy it.

The example factory uses the `ConstantPricePool.sol` as the Custom Pool type.

The concept is that once the custom pool factory is deployed, anyone can come along and deploy more of that specific custom pool type, with varying pool parameters.

This section will walk you through:
- Deployment of the custom pool factory example.
- Interacting with the pool factory within the ScaffoldBalancer UI by generating new pools from it on the testnet.

1. Run the following CLI command (assuming `.env` is populated appropriately) to simulate deployment of the pool factory.

`source .env && forge script scripts/DeployCustomPoolFactoryExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY`

2. Run the following CLI command to deploy the script.

`source .env && forge script scripts/DeployCustomPoolFactoryExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --slow --broadcast`

## Checkpoint 3: Writing Typical Unit and Fuzz Tests for Custom Pool Example

TODO

## Checkpoint 4: Creating Your Own Custom Pool with the Template Files

This is just a guide, so please use your own due diligence with your project before deploying any actual smart contracts of course.

1. Rename custom pool and reconfigure it as needed for your own needs.
2. Update dependencies and details within solidity scripts found [here](packages/hardhat/scripts).
3. Deploy, Register, and Initialize your custom pool using said scripts in #2. Interact with it to ensure it is functioning as you desire.
4. Simulate the deployment of your own custom pool factory, and interact with it to ensure it is functioning as you desire.
5. TODO - details regarding integration with SOR and Subgraph

Now you should have a custom pool and custom pool factory of your own, and have a better understanding of integrating with the new BalancerV3 tech stack.

The next step is to reach out, if you haven't already, to the Balancer ecosystem via:

1. [Discord](TODO - get the right link)
2. [Balancer Grants](TODO - get the right link) if you've got an idea for a custom pool that you'd like to apply for a grant with.
3. [BD team](TODO - Link to BD team)

## Checkpoint 5: 🧭 Integrate pool with the Smart Order Router (SOR)

TBD

## Checkpoint 6: 📡 Integrate pool with the Balancer v3 Subgraph

TBD