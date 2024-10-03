
# TWAMM (Time-Weighted Automated Market Maker)

## Overview

TWAMM is a smart contract implementation designed to facilitate time-weighted automated market making on the [Ethereum blockchain](https://ethereum.org/en/developers/docs/smart-contracts/). It leverages the [Balancer V3 Vault](https://docs.balancer.fi) architecture to execute trades over a specified time interval, allowing users to create, execute, and manage orders in a decentralized manner.

## Features

- **Order Creation**: Users can create buy or sell orders specifying the amount and duration.
- **Order Execution**: Orders are executed automatically based on the specified time intervals.
- **Order Cancellation**: Users can cancel their orders before execution.
- **Swap Functionality**: Integrates with Balancer V3 Vault for token swaps.
- **Fund Withdrawal**: Users can withdraw remaining funds after the order execution period ends.

## Contract Details

- **TWAMM.sol**: The main contract implementing the TWAMM logic.
- **TWAMMTest.sol**: Contains test cases for the TWAMM contract using a mock vault and ERC20 tokens.

## Installation

To set up the project, clone the repository and install the necessary dependencies:

```bash
git clone <repository-url>
cd TWAMM
npm install
```

## Usage

### Deploying the Contract

Deploy the `TWAMM` contract on an Ethereum-compatible blockchain:

```solidity
IVault vault = IVault(address(new MockVault()));
IERC20 tokenA = IERC20(address(new MockERC20("TokenA", "TKA", 18)));
IERC20 tokenB = IERC20(address(new MockERC20("TokenB", "TKB", 18)));

TWAMM twamm = new TWAMM(
    vault,
    address(tokenA),
    address(tokenB),
    tokenA,
    tokenB,
    1000 ether,
    1000 ether,
    block.timestamp,
    block.timestamp + 1 weeks,
    1 hours
);
```

### Running Tests

To run the tests for the `TWAMM` contract, use the following command:

```bash
forge test
```

## Mock Contracts

- **MockVault**: A mock implementation of the Balancer V3 Vault interface for testing purposes.
- **MockERC20**: A simple [ERC20](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20) token implementation used in testing.

## License

This project is licensed under the [GPL-3.0-only License](https://www.gnu.org/licenses/gpl-faq.en.html).

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## Contact

For any questions or support, please contact the project maintainers.       


# 🏗︎ Scaffold Balancer v3

A starter kit for building on top of Balancer v3. Accelerate the process of creating custom pools and hooks contracts. Concentrate on mastering the core concepts within a swift and responsive environment augmented by a local fork and a frontend pool operations playground.


[![intro-to-scaffold-balancer](https://github.com/user-attachments/assets/f862091d-2fe9-4b4b-8d70-cb2fdc667384)](https://www.youtube.com/watch?v=m6q5M34ZdXw)

### 🔁 Development Life Cycle
1. Learn the core concepts for building on top of Balancer v3
2. Configure and deploy factories, pools, and hooks contracts to a local anvil fork of Sepolia
3. Interact with pools via a frontend that runs at [localhost:3000](http://localhost:3000/)


### 🪧 Table Of Contents

- [🧑‍💻 Environment Setup](#-environment-setup)
- [👩‍🏫 Learn Core Concepts](#-learn-core-concepts)
- [🕵️ Explore the Examples](#-explore-the-examples)
- [🌊 Create a Custom Pool](#-create-a-custom-pool)
- [🏭 Create a Pool Factory](#-create-a-pool-factory)
- [🪝 Create a Pool Hook](#-create-a-pool-hook)
- [🚢 Deploy the Contracts](#-deploy-the-contracts)
- [🧪 Test the Contracts](#-test-the-contracts)

## 🧑‍💻 Environment Setup

### 1. Requirements 📜

- [Node (>= v18.17)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)
- [Foundry](https://book.getfoundry.sh/getting-started/installation) (>= v0.2.0)

### 2. Quickstart 🏃

1. Ensure you have the latest version of foundry installed
```
foundryup
```

2. Clone this repo & install dependencies

```bash
git clone https://github.com/balancer/scaffold-balancer-v3.git
cd scaffold-balancer-v3
yarn install
```

3. Set the necessary environment variables in a `packages/foundry/.env` file [^1]
   [^1]: The `DEPLOYER_PRIVATE_KEY` must start with `0x` and must possess enough Sepolia ETH to deploy the contracts. The `SEPOLIA_RPC_URL` facilitates running a local fork and sending transactions to sepolia testnet

```
DEPLOYER_PRIVATE_KEY=0x...
SEPOLIA_RPC_URL=...
```

4. Start a local anvil fork of the Sepolia testnet

```bash
yarn fork
```

5. Deploy the mock tokens, pool factories, pool hooks, and custom pools contracts [^2]
   [^2]: The `DEPLOYER_PRIVATE_KEY` wallet receives the mock tokens and resulting BPT from pool initialization

```bash
yarn deploy
```

6. Start the nextjs frontend

```bash
yarn start
```

7. Explore the frontend

- Navigate to http://localhost:3000 to see the home page
- Visit the [Pools Page](http://localhost:3000/pools) to search by address or select using the pool buttons
- Vist the [Debug Page](http://localhost:3000/debug) to see the mock tokens, factory, and hooks contracts

8. Run the Foundry tests

```
yarn test
```

### 3. Scaffold ETH 2 Tips 🏗️

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

## 👩‍🏫 Learn Core Concepts

- [Contract Architecture](https://docs-v3.balancer.fi/concepts/core-concepts/architecture.html)
- [Balancer Pool Tokens](https://docs-v3.balancer.fi/concepts/core-concepts/balancer-pool-tokens.html)
- [Balancer Pool Types](https://docs-v3.balancer.fi/concepts/explore-available-balancer-pools/)
- [Building Custom AMMs](https://docs-v3.balancer.fi/build-a-custom-amm/)
- [Exploring Hooks and Custom Routers](https://pitchandrolls.com/2024/08/30/unlocking-the-power-of-balancer-v3-exploring-hooks-and-custom-routers/)
- [Hook Development Tips](https://medium.com/@johngrant/unlocking-the-power-of-balancer-v3-hook-development-made-simple-831391a68296)

![v3-components](https://github.com/user-attachments/assets/ccda9323-790f-4276-b092-c867fd80bf9e)


## 🕵️ Explore the Examples
Each of the following examples have turn key deploy scripts that can be found in the [foundry/script/](https://github.com/balancer/scaffold-balancer-v3/tree/main/packages/foundry/script) directory

### 1. Constant Sum Pool with Dynamic Swap Fee Hook
The swap fee percentage is altered by the hook contract before the pool calculates the amount for the swap

![dynamic-fee-hook](https://github.com/user-attachments/assets/5ba69ea3-6894-4eeb-befa-ed87cfeb6b13)

### 2. Constant Product Pool with Lottery Hook
An after swap hook makes a request to an oracle contract for a random number

![after-swap-hook](https://github.com/user-attachments/assets/594ce1ac-2edc-4d16-9631-14feb2d085f8)

### 3. Weighted Pool with Exit Fee Hook
An after remove liquidity hook adjusts the amounts before the vault transfers tokens to the user 

![after-remove-liquidity-hook](https://github.com/user-attachments/assets/2e8f4a5c-f168-4021-b316-28a79472c8d1)


## 🌊 Create a Custom Pool

[![custom-amm-video](https://github.com/user-attachments/assets/e6069a51-f1b5-4f98-a2a9-3a2098696f96)](https://www.youtube.com/watch?v=kXynS3jAu0M)


### 1. Review the Docs 📖

- [Create a custom AMM with a novel invariant](https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/create-custom-amm-with-novel-invariant.html)

### 2. Recall the Key Requirements 🔑

- Must inherit from `IBasePool` and `BalancerPoolToken`
- Must implement `onSwap`, `computeInvariant`, and `computeBalance`
- Must implement `getMaximumSwapFeePercentage` and `getMinimumSwapFeePercentage`

### 3. Write a Custom Pool Contract 📝

- To get started, edit the`ConstantSumPool.sol` contract directly or make a copy

## 🏭 Create a Pool Factory

After designing a pool contract, the next step is to prepare a factory contract because Balancer's off-chain infrastructure uses the factory address as a means to identify the type of pool, which is important for integration into the UI, SDK, and external aggregators

### 1. Review the Docs 📖

- [Deploy a Custom AMM Using a Factory](https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/deploy-custom-amm-using-factory.html)

### 2. Recall the Key Requirements 🔑

- A pool factory contract must inherit from [BasePoolFactory](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/vault/contracts/factories/BasePoolFactory.sol)
- Use the internal `_create` function to deploy a new pool
- Use the internal `_registerPoolWithVault` fuction to register a pool immediately after creation

### 3. Write a Factory Contract 📝

- To get started, edit the`ConstantSumFactory.sol` contract directly or make a copy

## 🪝 Create a Pool Hook

[![hook-video](https://github.com/user-attachments/assets/96e12c29-53c2-4a52-9437-e477f6d992d1)](https://www.youtube.com/watch?v=kaz6duliRPA)

### 1. Review the Docs 📖

- [Extend an Existing Pool Type Using Hooks](https://docs-v3.balancer.fi/build-a-custom-amm/build-an-amm/extend-existing-pool-type-using-hooks.html)

### 2. Recall the Key Requirements 🔑

- A hooks contract must inherit from [BasePoolHooks.sol](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/vault/contracts/BaseHooks.sol)
- A hooks contract should also inherit from [VaultGuard.sol](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/vault/contracts/VaultGuard.sol)
- Must implement `onRegister` to determine if a pool is allowed to use the hook contract
- Must implement `getHookFlags` to define which hooks are supported
- The `onlyVault`  modifier should be applied to all hooks functions (i.e. `onRegister`, `onBeforeSwap`, `onAfterSwap` ect.)

### 3. Write a Hook Contract 📝

- To get started, edit the `VeBALFeeDiscountHook.sol` contract directly or make a copy

## 🚢 Deploy the Contracts

The deploy scripts are located in the [foundry/script/](https://github.com/balancer/scaffold-balancer-v3/tree/main/packages/foundry/script) directory. To better understand the lifecycle of deploying a pool that uses a hooks contract, see the diagram below

![pool-deploy-scripts](https://github.com/user-attachments/assets/bb906080-8f42-46c0-af90-ba01ba1754fc)


### 1. Modifying the Deploy Scripts 🛠️

For all the scaffold integrations to work properly, each deploy script must be imported into `Deploy.s.sol` and inherited by the `DeployScript` contract in `Deploy.s.sol` 

### 2. Broadcast the Transactions 📡

To run all the deploy scripts

```bash
yarn deploy
```

🛈 To deploy to the live sepolia testnet, add the `--network sepolia` flag

## 🧪 Test the Contracts

The [balancer-v3-monorepo](https://github.com/balancer/balancer-v3-monorepo) provides testing utility contracts like [BasePoolTest](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/vault/test/foundry/utils/BasePoolTest.sol) and [BaseVaultTest](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/vault/test/foundry/utils/BaseVaultTest.sol). Therefore, the best way to begin writing tests for custom factories, pools, and hooks contracts is to leverage the examples established by the source code.

### 1. Testing Factories 👨‍🔬

The `ConstantSumFactoryTest` roughly mirrors the [WeightedPool8020FactoryTest
](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/pool-weighted/test/foundry/WeightedPool8020Factory.t.sol)

```
yarn test --match-contract ConstantSumFactoryTest
```

### 2. Testing Pools 🏊

The `ConstantSumPoolTest` roughly mirrors the [WeightedPoolTest](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/pool-weighted/test/foundry/WeightedPool.t.sol)

```
yarn test --match-contract ConstantSumPoolTest
```

### 3. Testing Hooks 🎣

The `VeBALFeeDiscountHookExampleTest` mirrors the [VeBALFeeDiscountHookExampleTest](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/pool-hooks/test/foundry/VeBALFeeDiscountHookExample.t.sol)

```
yarn test --match-contract VeBALFeeDiscountHookExampleTest
```
