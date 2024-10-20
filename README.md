# :bank: NFT ESCROW LP
A Balancer v3 hook to allow a liquidity pool to be backed by an NFT.  This is accomplished by staking it into this escrow hook which mints an ERC20 to represent it fractionally.  The hook also enables the depositor to settle the pool at the current market rate - in essence this is buying back all outstanding tokens by depositing the required amount of the counterpart token into the escrow hook contract which then releases the NFT.

Think of it is as a rug-proof pool that requires the current token value to be honored in the equivilent counterpart token and held in escrow to be redeemed.

It has been designed with RWA NFTs in mind.

***
## 📜 Table of Contents

- [Introduction](#bank-nft-escrow-lp)
- [Use Case](#house_with_garden-use-case)
- [User Flow](#bearded_person-user-flow)
- [Demo](#video_camera-demo)
- [Utilized Hooks](#hook-utilized-hooks)
- [Technical Notes](#orange_book-technical-notes)
- [Acknowledgments](#pray-acknowledgments)
- [Future Plans](#rocket-future)
- [Getting Started](#Getting-Started-with-Scaffold-Balancer-v3)

***
## :house_with_garden: Use Case 
A user has created an NFT that represents a real world asset, such as an AirBnB.  In order to sell parts of their AirBnB and see what the dynamic market value of their asset is they create a liquidity pool with 20% of the equity paired with 20% of a stable coin pegging the price to $100,000.  They stake their RWA NFT in order to assure the token holders that infact there is an NFT that represents the asset, and assure the potential buyers that it is not being used in any other financial instrument.

Swapping occurs as guests in the AirBnB are given the opportunity to invest.  The price increases 20% as supply is decreased in the pool.  In time the owner discovers a new financing defi product that also requires the NFT and desires to withdraw.  Since it would be nearly impossible to contact the existing token holders and purchase them back, he is given the ability to deposit the stable coin needed in order to cover the existing outstanding tokens.  If there are 10 tokens out of 100 that are not in the pool or in the depositor's wallet and with the asset price of $120,000 he must deposit $12,000 into the liquidity pool in order to withdraw his NFT.  Token holders may now redeem their 10 tokens, each one being worth $1,200.

***
## :bearded_person: User Flow
> Mint RWA NFT & Linked "RWAT" ERC20 Tokens
> Create Pool with RWAT & STABLE
> Stake NFT into hook
> Initialize Pool
> Swapping Occurs
> Settlement is initiated, transfering outstanding token balance in and NFT out
> Initial liquidity is withdrawn
> Oustanding tokens redeemed for STABLE from the hook contract

***
## :video_camera: Demo
[https://youtu.be/0zS-bFA9sNE](https://www.youtube.com/watch?v=0zS-bFA9sNE&feature=youtu.be)

***
## :hook: Utilized Hooks
<table>
<tr><th>onRegister</th></tr>
<tr><td>
Initial liquidity values are recorded to be referenced later to ensure the initial depositor does not withdraw more than their initial deposit
</td></tr>
<tr><th>onBeforeInitialize</th></tr>
<tr><td>
We require that the NFT is deposited and that one of the tokens in the pool is the cooresponding linked erc20 token
</td></tr>
<tr><th>onAfterRemoveLiquidity</th></tr>
<tr><td>
Checking to make sure that the depositor has not removed more tokens than they originally deposited.  This is our anti-rug pull check, locking in the liquidity until after the NFT has been withdrawn.
</td></tr>
<tr><th>onBeforeSwap</th></tr>
<tr><td>
Check if pool has been settled in order to halt trading if so.
</td></tr>
</table>

***
## :orange_book: Technical Notes
There are a few functions that we needed to add to the hook in order to make this work such as settle, redeem, getSettlementAmount, recordInitialLiquidity & setNft.  We could also add some additional functions to that allow for some advanced functionality, such as detaching the linked token upon settle and minting a new fresh one for the NFT upon withdrawl but figure that will be it's own process.  We also thought of combining the settle with liquidity withdrawl, but it was a more complex hook use case so kept it in two seperate operations. Ideally we will extend this hook to work with the weighted pool.  This will allow for smaller amount of capital to be used to peg an asset to a particular price but will need to take the ratio into account for the settlement amount. 

***
## :pray: Acknowledgments
Many thanks from elamore and Tony Nacu to `daniel | Beethoven X`, `matthu.eth`, `Tritium` and `burns` for answering the (often stupid) questions that we had. Without their help this project would not be possible.

***
## :rocket: Future
We'd like to continue developing this in order to fit into an entire ecosystem where a user can utilize the value of their asset, as determined via the pool, in for use in a loan product.  This would enable the LTV to be responsive to market price and could enable other novel hook use cases.  Also adding cross-chain multi-assest compatibility so that there is only one liquidity pool for an asset, but is accessible via any chain and any asset ie "zap in" would be usefull going forward.

***
# Getting Started with Scaffold Balancer v3

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
   [^1]: The `DEPLOYER_PRIVATE_KEY` must start with `0x` and must possess enough Sepolia ETH to deploy the contracts. The `SEPOLIA_RPC_URL` facilitates running a local fork and sending transactions to sepolia testnet. The `DEPLOYER_ADDRESS` is the address that matches the private key. The `TEST_USER_ADDRESS` is the address of a test user that demonstrates the use case.

```
DEPLOYER_PRIVATE_KEY=
DEPLOYER_ADDRESS=
TEST_USER_ADDRESS=
SEPOLIA_RPC_URL=
```

4. Start a local anvil fork of the Sepolia testnet

```bash
yarn fork
```

5. Deploy the mock tokens, pool factories, pool hooks, and custom pools contracts
   > By default, the anvil account #0 will be the deployer and recieve the mock tokens and BPT from pool initialization

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
- The `onlyVault` modifier should be applied to all hooks functions (i.e. `onRegister`, `onBeforeSwap`, `onAfterSwap` ect.)

### 3. Write a Hook Contract 📝

- To get started, edit the `VeBALFeeDiscountHook.sol` contract directly or make a copy

## 🚢 Deploy the Contracts

The deploy scripts are located in the [foundry/script/](https://github.com/balancer/scaffold-balancer-v3/tree/main/packages/foundry/script) directory. To better understand the lifecycle of deploying a pool that uses a hooks contract, see the diagram below

![pool-deploy-scripts](https://github.com/user-attachments/assets/bb906080-8f42-46c0-af90-ba01ba1754fc)

### 1. Modifying the Deploy Scripts 🛠️

For all the scaffold integrations to work properly, each deploy script must be imported into `Deploy.s.sol` and inherited by the `DeployScript` contract in `Deploy.s.sol`

### 2. Broadcast the Transactions 📡

#### Deploy to local fork

1. Run the following command

```bash
yarn deploy
```

#### Deploy to a live network

1. Add a `DEPLOYER_PRIVATE_KEY` to the `packages/foundry/.env` file

```
DEPLOYER_PRIVATE_KEY=0x...
SEPOLIA_RPC_URL=...
```

> The `DEPLOYER_PRIVATE_KEY` must start with `0x` and must hold enough Sepolia ETH to deploy the contracts. This account will receive the BPT from pool initialization

2. Run the following command

```
yarn deploy --network sepolia
```

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
