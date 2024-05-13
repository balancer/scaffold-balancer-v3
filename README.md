# 🏗 Scaffold-Balancer

⚖️ Balancer is a decentralized automated market maker (AMM) protocol built on Ethereum that represents a flexible building block for programmable liquidity.

🛠️ This repo is a series of guides and internal prototyping tools for creating custom pools that integrate with Balancer v3. 

📚📖 PRE-REQs: It is highly recommended to read through the (BalancerV3 docs](TODO GET LINK) before using this repo. Custom pools are built upon the architecture outlined within these docs. If you cannot find what you are looking for in the docs, and it is not in this README, please refer to the (BalancerV3 monorepo](TODO GET LINK) and/or reachout on the (Balancer Discord](TODO GET LINK).

It walks through example contracts for a custom pool, custom pool factory, test files, and deployment scripts. These files are used to deploy an example BalancerV3 custom pool that can be interacted with using a test, local front-end, on a test network (by default it is a foundry fork of Sepolia). The repo also provides a starting point for developers to create their own custom pools and factories.

> When users clone this repo "off-the-shelf" they simply have to follow the environment setup instructions, run a few commands, and then they will have an example custom pool factory, and custom pools that they can interact with in a local front end. 

Let's outline what this repo provides in more detail:

1. A README to walk a dev through using the different functionalities of the repo. 
2. A front-end prototyping tool, example smart contracts and scripts, to help showcase simple integrations with Balancer's core architecture.
3. Use of the same front-end framework with your own custom pools, and walking you through how to do so using the example smart contracts and scripts to start.

## Demo

Here's a video showcasing the front end tool with this repo, and how one can explore pool actions (Swaps, joins, exits, etc.) with the pool explorer off-the-shelf.

<!-- TODO - MATT ADD IN VIDEO HERE -->

## Table of Contents

✏️ The Table of Contents of this README is listed below. Links are provided below in case you would like to jump to a certain topic.

0. **[Checkpoint 0](#🚨🚨-checkpoint-0-📦-environment-📚)** - 📚 Setup of the environment
1. **[Checkpoint 1](#🚨🚨-checkpoint-1-🏊🏻‍♀️-showcase-of-the-pool-explorer-with-se-2-tech-stack)** - 📚 Showcase of the front end actions w/ the repo off-the-shelf
1. **[Checkpoint 2](#🚨🚨-checkpoint-2-🌊-create-a-custom-pool)** - 🌊 Creating a custom pool smart contract.
2. **[Checkpoint 3](#🚨🚨-checkpoint-3-🔧-create-a-custom-pool-factory--interact-with-resultant-custom-pools)** - 🔧 Creating a custom pool factory, deploying it, and generating said pool from it that you can interact with using the front end in your local host.
3. **[Checkpoint 3](#🚨🚨-checkpoint-4-writing-typical-unit-and-fuzz-tests-for-custom-pool-example)** - 🧪 An Example of Writing Typical Unit and Fuzz Tests for a Custom Pool and Custom Pool Factory
4. **[Checkpoint 4](#🚨🚨-checkpoint-5-creating-your-own-custom-pool-with-the-template-files)** - 🎨 Creating Your Own Custom Pool with the Template Files
5. **[Checkpoint 5](#🚨🚨-checkpoint-6-🧭-integrate-pool-with-the-smart-order-router-sor)** - 📡 Integrate pool with the Balancer v3 Subgraph
6. **[Checkpoint 6](#🚨🚨-checkpoint-7-📡-integrate-pool-with-the-balancer-v3-subgraph)** - 🧭 Integrate pool with the Smart Order Router (SOR)

In general, all smart contracts sections of this repo will already have `Example` smart contracts. These smart contract examples will be explained within this README.

## 🚨🚨 Checkpoint 0: 📦 Environment 📚

This section walks you through the set up of the repo environment so that you have a local front end with a foundry test fork off of Sepolia. The test fork will have deployed contracts to showcase how you can interact with custom pools in a test environment using the local pool explorer tab.

### 0.1 Requirements

Before you begin, you need to install the following tools:

- [Node (>= v18.17)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### 0.2 Quickstart

Next, we will run the following bash commands in your terminal to clone the repo and set up the repo accordingly.

#### 0.2.0 Clone Repo

```bash
git clone https://github.com/Dev-Rel-as-a-Service/scaffold-balancer-v3.git
```

#### 0.2.1 Install Dependencies

```bash
yarn install
```

#### 0.2.2 Set Environment Variables

Set a `DEPLOYER_PRIVATE_KEY`, referred to as 'DEPLOYER' throughout this README, `ALCHEMY_API_KEY`, and `ETHERSCAN_API_KEY` at the path `packagages/foundry/.env`

```
DEPLOYER_PRIVATE_KEY=0x...
ETHERSCAN_API_KEY=...
ALCHEMY_API_KEY=...
```

#### 0.2.3 Start Local Fork

```bash
yarn fork
```

#### 0.2.4 Deploy Contracts

The following command runs the script from `DeployFactoryAndPool.s.sol` which deploys a pool factory, deploys mock tokens, deploys a new pool using the factory, and finally initializes the pool using the mock tokens. This is all done from the DEPLOYER wallet associated to the `DEPLOYER_PRIVATE_KEY` specified in the `.env`. It receives mock tokens, deploys the pool factory, and initializes the newly created pool with the some mock tokens. It carries these deployments out on an anvil local fork of the Sepolia test network.

```bash
yarn deploy:all
```

#### 0.2.5 Start Frontend

Execute the following command and then navigate to http://localhost:3000/pools

```bash
yarn start
```

You now should have a local, testnet fork with newly deployed smart contracts and a local front end communicating with said smart contracts. You can start interacting with the newly deployed pools and other smart contracts, but first let's talk about wallets and this tool.

### 0.3 Wallet Connection Options, and Key Gotchas with Scaffold ETH 2

#### 0.3.1 Understand Wallet Connection Options

This repo has a number of wallet configurations to help a developer.

##### Burner Wallet (Preferred)

If you do not have a wallet already connected to your web browser and thus your local host, then you will automatically use a burner wallet. First, what is a burner wallet?

When connecting to a local node, SE-2 frontend randomly generates a burner wallet and saves the PK to your browser's local storage. When using the burner wallet, transactions will be instantly signed. This is useful for quick iterative development.

To force the use of burner wallet, disable your browsers wallet extensions and refresh the page. Note that the burner wallet comes with 0 ETH to pay for gas so you will need to click the faucet button in top right corner. Also the mock tokens for the pool are minted to your deployer account set in `.env` so you will want to navigate to the "Debug Contracts" page to mint your burner wallet some mock tokens to use with the pool.

<!-- TODO - Matt show screenshot/gif of debug tab doing the mint -->

##### Browser Extension Wallet

To use your preferred browser extension wallet, ensure that the account you are using matches the PK you previously provided in the `foundry/.env` file. As a convenience, the foundry deploy scripts max approve the vault contract to spend tokens.

⚠️ You may need to add a local development network with rpc url `http://127.0.0.1:8545/` and chain id `31337`. Also, you may need to reset the nonce data for your wallet exension if it gets out of sync.

<!-- TODO - ENHANCEMENT: add in screenshots of this troubleshooting -->

With the wallet configurations understood and setup, we will touch on some SE-2 details before fully exploring the newly deployed local-test pool smart contracts.

#### 0.3.2 Deployment

> SE-2 is setup to hot reload the frontend with contracts that are directly deployed via the `DeployFactoryAndPool.s.sol` script. This means our frontend captures the pool factory and mock token contracts, but not the pool contract because it is deployed by calling a method on the factory.

This command runs `DeployFactoryAndPool.s.sol` which deploys a pool factory, deploys mock tokens, deploys a pool, and initializes the pool. The factory contract and mock tokens will show on the "Debug" page. The pool contract address will print in the terminal, but can also be selected from the dropdown on the "Pools" page. All deployment configuration options are specified in `HelperConfig.s.sol`

```bash
yarn deploy:all
```

This command runs `DeployPool.s.sol` using the last pool factory you deployed. You can copy and paste the address from terminal or refresh the pool explorer page and select it from the dropdown. All deployment configuration options are specified in `HelperConfig.s.sol`

```bash
yarn deploy:pool
```

#### 0.3.3 Changing The Frontend Network Connection

The network the frontend points at is set via `targetNetworks` in the `scaffold.config.ts` file

#### 0.3.4 Changing The Forked Network

Modify the "fork" alias in the `packages/foundry/package.json` file, but do not change the chain id

```json
	"fork": "anvil --fork-url ${0:-sepolia} --chain-id 31337 --config-out localhost.json",
```

🧠 Tip: `foundry.toml` comes preconfigured with a variety of aliases for `rpc_endpoints`

** 😮‍💨PHEW, with the quick start deployments done, we can get into the fun stuff and show what can be done with this tool!**

## 🚨🚨 Checkpoint 1: 🏊🏻‍♀️ Showcase of the Pool Explorer with SE-2 Tech Stack

You now should have a local front end started and test contracts deployed on a foundry test fork of the Sepolia network. This section simply highlights some of the actions you can take with the local front end.

<!-- TODO @matt - Showcase the front end at a high level (showing, with a pool address input already, the possible interactions you can do with it). -->

### 1.1 Select Your Pool

On the "Pools" page, click the dropdown to select the custom pool you just deployed to your local anvil node.

<details><summary> 👀 See Demo GIF</summary>
	
https://github.com/Dev-Rel-as-a-Service/scaffold-balancer-v3/assets/73561520/cc358227-3bf6-4b02-8dc5-36577c0cbdcd

</details>

### 1.2 Use Your Pool

Connect the account you specified in the `.env` file using your favorite wallet extension and start splashing around in your pool with swaps, joins, and exits!

<!-- TODO - Matt showcase with screenshots and gifs here all the things that can be done with pool explorer -->

### 1.3 Troubleshoot with the Debug Tab

Using the SE-2 toolkit, developers can troubleshoot with their smart contracts using the "Debug Tab" where they can see getter and setter functions in a local front end UI. As you saw earlier, we use this handy setup to mint `mockERC20` tokens to any connected wallet to our local host (it could be a foundry wallet, a burner wallet, your `.env` wallet, etc.). 

<!-- TODO - Matt show screenshot/gif of debug tab doing the mint again -->

At this point, you have now seen the capabilities of this repo and how it helps a developer (or team) onboard in building custom pools in BalancerV3. The local front end environment helps developers test interactions in a way that is similar (but not the same) as the interactions with the BalancerV3 front end. 🎉🎉

<!-- TODO - Steve, not sure about last bit in the above line re: the BalancerV3 front end. -->

🏎 Let's look under the hood, where we will start with understanding the example custom pool used within this repo., the `ConstantPricePool`.

## 🚨🚨 Checkpoint 2: 🌊 Create A Custom Pool

Ultimately, this repo can be used to create custom pool factories, custom pools from said factory, and register and initialize them so the pools can be interacted with using this repo's front end, all in a local environment. Before jumping into all of that, it is key that developers understand the general make-up of a custom pool.

Therefore, this checkpoint focuses on writing the smart contract for a custom pool (without a factory). We will walk through the `ConstantPricePoolExample.sol` found within `packages/hardhat/contracts/ConstantPricePoolExample.sol`.

### 2.1 Write a Custom Pool Contract

As a refresher, make sure to check out the [docs on creating custom pools as well](https://docs-v3.balancer.fi/concepts/guides/create-custom-amm-with-novel-invariant.html#build-your-custom-amm).

All custom pool contracts must inherit from `IBasePool` and `BalancerPoolToken` and implement the three required functions: `onSwap`, `computeInvariant`, and `computeBalance`.

Let's walk through each function in `ConstantPricePoolExample.sol`

#### 2.1.1 `onSwap()` Implementation - TODO

Looking at monorepo, one sees that `onSwap()` is ultimately called within a `swap()` call in the [`Vault.sol`](https://github.com/balancer/balancer-v3-monorepo/blob/9bc5618d7717dfbafd3cfbf025e7d3317ad7cacb/pkg/vault/contracts/Vault.sol#L327).

Essentially, the `onSwap()` call carries the custom pool logic that the vault queries to understand how much of the requested token the swap should return. 

This step can vary between custom pool variations. To paint a contrast, a simple implementation can be seen within this `ConstantPricePool` example, where the amount swapped in is simply the amount swapped out (see toggle below).

<details markdown='1'><summary>👩🏽‍🏫 Code for `onSwap` functions </summary>
Inside `ConstantPricePoolExample.sol`

```
   /**
	 * @notice Execute a swap in the pool.
	 * @param params Swap parameters
	 * @return amountCalculatedScaled18 Calculated amount for the swap
	 */
	function onSwap(
		SwapParams calldata params
	) external pure returns (uint256 amountCalculatedScaled18) {
		amountCalculatedScaled18 = params.amountGivenScaled18;
	}

```

</details>

Whereas you can begin to see the endless possibilities that exist when you take a look at the [WeightedPool implementation](https://github.com/balancer/balancer-v3-monorepo/blob/main/pkg/pool-weighted/contracts/WeightedPool.sol#L100-L126).

There you can see that the return value is dependent on the `SwapKind` and ultimately uses the `WeightedMath` functions to respect the invariant and other details for WeightedPools.

---

#### 🥅 ** `onSwap()` Goals / Checks**

- [ ] ❓ Can you describe how `onSwap()` works within the Balancer V3 monorepo architecture and thus how custom pools must accomodate said architecture?

---

#### 2.1.2 `computeInvariant()` Implementation TODO - steve where you left off

- Looking at monorepo, one sees that `computeInvariant()` is ultimately called to return the new invariant resulting from the specific details influencing the respective pool.
- In this case, it is constant sum invariant that we simply need to create.

> **Recall the architecture of BalancerV3, and how each custom pool function is called throughout the typical treansactions carried out within the protocol.**

---

<details markdown='1'><summary>👩🏽‍🏫 Solution Code for `computeInvariant()` function </summary>
Inside `ConstantPricePoolExample.sol`

```
  /**
	 * @notice Computes and returns the pool's invariant.
	 * @dev This function computes the invariant based on current balances
	 * @param balancesLiveScaled18 Array of current pool balances for each token in the pool, scaled to 18 decimals
	 * @return invariant The calculated invariant of the pool, represented as a uint256
	 */
	function computeInvariant(
		uint256[] memory balancesLiveScaled18
	) public pure returns (uint256 invariant) {
		invariant = balancesLiveScaled18[0] + balancesLiveScaled18[1];
	}

```

</details>

---

#### 🥅 ** `computeInvariant()` Goals / Checks**

- [ ] ❓ Can you describe how `computeInvariant()` works within the Balancer V3 monorepo architecture and thus how custom pools must accomodate said architecture?

---

#### 2.1.3 `computeBalance()` Implementation TODO

- Looking at monorepo, one sees that `computeBalance()` is ultimately called to return the new balance of a token after an operation, given the invariant growth ratio and all other balances.
- In this case, it is constant sum invariant that we simply need to create.

> **Recall the architecture of BalancerV3, and how each custom pool function is called throughout the typical transactions carried out within the protocol.**

---

<details markdown='1'><summary>👩🏽‍🏫 Solution Code for `computeBalance()` function </summary>
Inside `ConstantPricePoolExample.sol`

```
  /**
	 * @dev Computes the new balance of a token after an operation, given the invariant growth ratio and all other
	 * balances.
	 * @param balancesLiveScaled18 Current live balances (adjusted for decimals, rates, etc.)
	 * @param tokenInIndex The index of the token we're computing the balance for, in token registration order
	 * @param invariantRatio The ratio of the new invariant (after an operation) to the old
	 * @return newBalance The new balance of the selected token, after the operation
	 */
	function computeBalance(
		uint256[] memory balancesLiveScaled18,
		uint256 tokenInIndex,
		uint256 invariantRatio
	) external pure returns (uint256 newBalance) {
		uint256 invariant = computeInvariant(balancesLiveScaled18);

		newBalance =
			(balancesLiveScaled18[tokenInIndex] +
				invariant *
				(invariantRatio)) -
			invariant;
	}

```

</details>

---

#### 🥅 ** `computeBalance()` Goals / Checks**

- [ ] ❓ Can you describe how `computeBalance()` works within the Balancer V3 monorepo architecture and thus how custom pools must accomodate said architecture?

---

💡 Now we have walked through a basic custom pool construction, let's get into how the custom pool factory contracts work.

## 🚨🚨 Checkpoint 3: 🔧 Create a custom pool factory && Interact with Resultant Custom Pools

Now that you have created a custom pool, it is time to deploy the associated custom pool factory. For this repo, we've created a custom pool factory example and associated script to deploy it, and create a new pool using said factory.

The example factory continues off of the previous section and uses `ConstantPricePool.sol` as the Custom Pool type.

The concept is that once the custom pool factory is deployed, anyone can come along and deploy more of that specific custom pool type, with varying pool parameters. Within the script the first pool from said factory is deployed, registered, and initialized, so you can interact with it right away. Another script is created so you can create more pools and enter in the param details via your favorite code editor too.

This section will walk you through:

- Creating and Deploying the custom pool factory example.
- Running the script to deploy more pools from said custom pool factory.
- Interacting with the pool factory within the ScaffoldBalancer UI with the Debug Tab.

## 3.1: Creating the Custom Pool Factory

Balancer architecture pushes for pool creation from a pool factory for a number of reasons, one including being picked up by the Balancer subgraph easily.

The `CustomPoolFactoryExample.sol` contract is used to deploy the `ConstantPricePool.sol` example custom pool we walked through earlier. It inherits the `BasePoolFactory.sol` from BalancerV3's monorepo.

First we need to make the appropriate constructor function. We'll go through the following constructor params for `BasePoolFactory.sol`.

1. `IVault vault` - The BalancerV3 vault on the respective network.
2. `uint256 pauseWindowDuration` - The pause window that will be used for all pools created from this factory. It is the timeframe that a newly created pool can be paused before its buffer endtime. Once a pool is paused, it will remain paused til the end of the pause window, and subsequently will wait til the vault's buffer period ends. When the buffer period expires, it will unpause automatically, and remain permissionless forever after.
3. `bytes memory creationCode` - The creation code that is used within the `_create()` internal function call when creating new pools. This is associated to the respective custom pool that you are looking to create.

Thus, with the above background, we will write the constructor as follows:

```
constructor(
        IVault vault,
        uint256 pauseWindowDuration
    ) BasePoolFactory(vault, pauseWindowDuration, type(ConstantPricePool).creationCode) {
        // solhint-disable-previous-line no-empty-blocks
    }
```

> NOTE: more implementation can be input for the constructor for your own custom pool of course, but for this example we are keeping things simple.

Moving on to the next part, the `create()` function is used to create new pools from the custom pool factory, adhering to the specific type of pools for said factory. In this case, that's the `ConstantPricePool`.

### 3.1.1 `create()` Function

The `create()` function, in this simple example pool factory, simply calls the `_create()` function within the `BasePoolFactory.sol`. The `_create()` function uses `CREATE3`, similar to `CREATE2` to deploy a pool that has a pre-determined address based on its salt, and encoded creation code & args.

Here is the `_create()` internal function for reference:

```
function _create(bytes memory constructorArgs, bytes32 salt) internal returns (address) {
        return CREATE3.deploy(salt, abi.encodePacked(_creationCode, constructorArgs), 0);
    }
```

Within the function `create()` we call `_create()` with appropriate params, which will be touched on later within our scripts. For now, we move onto the next aspect of the `create()` call, which is to `registerPool()` with the BalancerV3 vault.

### 3.1.2 Calling `registerPool()`

New pools need to be registered to the BalancerV3 vault to operate within the BalancerV3 architecture.

TODO - reference `IVaultExtension.sol` for details.

TODO - Finally, the `create()` function ends by calling `_registerPoolWithFactory(newPool)` which registers the new pool with the respective factory. This is done for accounting purposes, amongst other reasons.

> NOTE: like all other contracts and scripts within this repo, one must adjust aspects within this smart contract when creating their own type of custom pool.

## 3.2: Deploying the Custom Pool Factory

Now that we have created the `CustomPoolFactoryExample.sol` contract, it is time to write the deployment scripts. We've provided example deployment scripts to reference as you create your own, and will walk through key gotcha's when writing your own deployment scripts. As always, test on your own before deploying!

`DeployCustomPoolFactoryAndNewPoolExample.s.sol` is the file that we will use as a template.

For sake of simplicity, we will outline the core function of the script, and then explain specific gotchas with the script. The main one being the params involved with initialization.

### 3.2.1 Core Script Function

The script, using the `.env` specified deployer wallet, deploys the custom pool factory (currently the constant price custom pool), creates a new pool with it, registers the new pool with the BalancerV3 Vault on sepolia, and initializes it. It does all of this so it is ready to use with the ScaffoldBalancer front end tool. The variables defined when calling Balancer functions, like `Router.intiialize()` are specific to the constant price custom pool setup, whereas if you are working with a more complicated pool setup you may want to adjust these params as necessary.

### 3.2.2 Key Gotchas

- Specific to this repo, the script inherits `TestAddresses` and `HelperFunctions`.
- Balancer integration with `initialize()` has a couple of arrays that must match in terms of token ERC20 we are using, and the amounts of said token.
- Section incased in `/// Custom Pool Variables Subject to Change START ///` and `/// Custom Pool Variables Subject to Change END ///` are variables to be changed if you are changing the type of the custom pool being created.

> It is key to understand that the script is calling `Router.initialize()` ultimately, and so understanding this function call and its params is crucial. See the BalancerV3 monorepo for more info. We touch on some of these params below, but the nat spec is also a great resource.

- Some variables have comments on them to assist, such as the custom pool factory
- This script uses MockToken contracts to instantly mint 1000 of each test token to deployer wallet.
- The TokenConfig struct is defined within `VaultTypes.sol` in the v3 monorepo. It has a few gotchas:
  - `TokenConfig.tokenType` is an enum: `STANDARD` OR `WITH_RATE`
  - `TokenConfig.token` is the token address
  - `TokenConfig.rateProvider` is the rate provider for the respective token. Rate Providers are not needed for `STANDARD` tokenTypes. These also are not yield bearing.
  - `TokenConfig.payYieldFees` is a flag marking whether yield fees are charged on this token. As per BalancerV2, all yield bearing tokens had to have a yieldFee.
- Salt is typically the name of the respective pool. This way deployment of said pool can be the same across other networks too as per typical use of `CREATE2` and `CREATE3`.
- `exactAmountsIn[]` are subject to the details of TokenConfig, specifically the `tokenType` and `rateProvider`
- `userData` is for additional (optional) data required for adding initial liquidity.
- Sender must approve transferrance/handling of its tokens with the router and vault
- New pool must approve transferrance/handling of these specific tokens via router and vault.
- New Custom Pool Factory address is console logged to be used with `DeployCustomPoolFromFactoryExample.s.sol`
- As per the high-level BalancerV3 architecture, the `Router` is the main integration entrypoint to the Balancer system. Thus, `Router.initialize()` is called to subsequently call the vault to initialize a new pool within the system.

Cool, now we have these gotcha's understood with the script. We can move on to simulating and deploying!

**Simulating and Deploying the Script Finally!**

Run the following CLI command (assuming `.env` is populated appropriately) to simulate deployment of the pool factory.

`source .env && forge script scripts/DeployCustomPoolFactoryExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY`

You should see that the simulation was completed and the factory contract was successfully deployed in it.

Next, we will actually deploy it so we can interact with it. Run the following CLI command to run the script to deploy a constant price custom pool factory.

`source .env && forge script scripts/DeployCustomPoolFactoryExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --slow --broadcast`

## 3.3: Interacting with the Testnet Custom Pool Factory via Scripts

Now the pool factory has been deployed to the respective network (default is the testnet Sepolia). Once you click the transaction details (as shown within the screenshots below), you will see that a pool was deployed as well. You can also find this information within the deployment script return values.

<!-- TODO - add screenshots for getting the factory address and inputting it into the appropriate script. -->

Copy and paste this new pool address and input it into the ScaffoldBalancer front end tool. You can now interact with it exactly like in section 1!

The beauty of the factory contract is that it inherits and abides by the Balancer Factory architecture. This means that pools created from a properly constructed factory contract will adhere to much easier integration for things like the BalancerV3 Subgraph.

We will now run the script to simulate calling `create()` from the new custom pool factory contract that you just deployed. This script will also register and initialize the pool.

> NOTE: You will need the address of the new custom pool factory that you have deployed on the respective network and input it into the appropriate variable seen in DeployCustomPoolFromFactoryExample.s.sol.

```
source .env && forge script scripts/DeployCustomPoolFromFactoryExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY
```

Next, we will actually deploy it so we can interact with it. Run the following CLI command to run the script to deploy a constant price custom pool factory.

```
source .env && forge script scripts/DeployCustomPoolFromFactoryExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --slow -broadcast
```

Copy and paste this new pool address and input it into the ScaffoldBalancer front end tool. You can now interact with it like the other pools!

## TODO 3.4: Interacting with the Testnet Custom Pool Factory via Debug Tab - @matt, I think we may need to delete this one for milestone 1, seeing as it is more imperative that pools are created via a script. I think having the debug tab show the factory contract still is cool, but the `create()` function sounds like it will be tricky to work with. wdyt?

At this point, the factory has been deployed, and you have deployed at least one more pool from the factory using the scripts within this repo.

<!-- TODO - assess if this section is needed anymore since we are going with scripts.

Pools can also be created using the Debug Tab, theoretically. Currently SE-2 has some trouble with structs within the debug tab, and as such it is recommended to use scripts to work with any input params involving structs.

That said, this section outlines how one would use the debug tab to create a pool using a factory contract.

  -->

### TODO - 3.5 Interact with your custom pool

- On the `localhost:3000/pools` page, select your custom pool from the dropdown
- Review the pool details and composition post pool initialization
- Try out executing a swap, join, and exit with your custom pool

---

## 🚨🚨 Checkpoint 44: Writing Typical Unit and Fuzz Tests for Custom Pool Example

<!-- STEVE THIS IS WHERE YOU LEFT OFF -->

At this point we've gone through how to make a simple custom pool and custom pool factory, and to simulate and/or deploy them on a testnet. Testing is of course needed, amongst many other security measures such as audits, for a custom pool implementation.

We will now walk through the testing contract, provided as foundry test files. These testing files can be used as a testing template, similar to how the smart contracts and scripts so far could be used as references or templates for your own custom pool implementation.

### 4.1 `CustomPoolTemplate.t.sol`

#### 4.1.1 Inherited Context for `CustomPoolTemplate.t.sol` (`BaseVaultTest.sol` & `BaseTest.sol`)

The v3 monorepo has pool tests inheriting a base setup implemented within `BaseVaultTest.sol` & `BaseTest.sol`.

`BaseTest.sol` (Inherited by `BaseVaultTest.sol`)

- Creates test ERC20s (DAI, USDC, WETH, wstETH), test users (`admin`, `lp`, `alice`, `bob`, `hacker`, `broke`)
- Users created are dealt 1 million of each test ERC20
- Each test ERC20 has 18 decimals (compared to actual implementations such as USDC with 6 decimals)

`BaseVaultTest.sol`:

- Creates core architecture in a test environment: vault, vaultExtension, router, authorizer, pool, rateProvider
- Creates a mock pool with the vault
- Initializes pool with user `lp`

#### 4.1.2 Walking Through the `CustomPoolTemplate.t.sol`

Now that we understand the base `BaseVaultTest.setUp()` call made within the `CustomPoolTemplate.t.sol`, we can get into the actual template files.

Each test has comments added to them to help guide the developer with this starter test template. There are "TODO" comments added on several lines to assist users in creating their own custom pool tests for their own custom pool types they are working on. Of course, one has to update dependencies and other aspects as needed for their purposes.

### 4.2 `CustomPoolFactoryTemplate.t.sol`

Unlike the `CustomPoolTemplate.t.sol`, the `CustomPoolFactoryTemplate.t.sol` has a simpler setup where a mock vault, a custom pool factory (specific to the one that is being tested), and two test tokens are deployed.

Similar to the `CustomPoolTemplate.t.sol` file, the `CustomPoolFactoryTemplate.t.sol` file has "TODOs" to guide users in creating their own appropriate tests once they have a custom pool factory type of their own that they need to test.

## 🚨🚨 Checkpoint 5: Creating Your Own Custom Pool with the Template Files

This is just a guide, so please use your own due diligence with your project before deploying any actual smart contracts of course. This section will walk you through key areas to look at updating if you are creating your own custom pool. Again, this is not the full extent that you should take to create your own custom pool, it is up to you and your team to carry out everything necessary (including but not limited to: testing, audits, etc.).

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

## 🚨🚨 Checkpoint 6: 🧭 Integrate pool with the Smart Order Router (SOR)

TBD

## 🚨🚨 Checkpoint 7: 📡 Integrate pool with the Balancer v3 Subgraph

TBD
