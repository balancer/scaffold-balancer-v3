# 🏗 Scaffold-Balancer

⚖️ Balancer is a decentralized automated market maker (AMM) protocol built on Ethereum that represents a flexible building block for programmable liquidity.

🛠️ This repo is a series of guides and a prototyping tools for creating custom pools that integrate with Balancer v3.

It uses example contracts for a custom pool, custom pool factory, test files, and deployment scripts. The core idea is to help educate developers with creating custom pools and integrating with BalancerV3, and to provide a starting point for developers to create their own custom pools and factories.

When users clone this repo "off-the-shelf" they simply have to follow the environment setup instructions, run a few commands, and then they will have an example custom pool factory, and custom pools that they can interact with in a local front end. This README walks a user through the ins and outs of these example custom pool contracts. Once a user has gone through these example contracts, they can then use them as starting templates to create their own custom pool factories and pools.

The ability to interact with your own custom pool in a local front end is powerful as the front end is based on the same SDK and APIs / Subgraphs that Balancer as a protocol uses.

To expand on this, let's outline what this repo provides in more detail:

1. A README to walk a dev through using the different functionalities of the repo.
2. A front-end prototyping tool, example smart contracts and scripts, to help showcase simple integrations with Balancer's core architecture.
3. Use of the same front-end framework with your own custom pools, and walking you through how to do so using the example smart contracts and scripts to start.

✏️ The agenda of this README is listed below:

0. **Checkpoint 0** - 📚 Setup of the environment.
1. **Checkpoint 1** - 🌊 Creating a custom pool smart contract.
2. **Checkpoint 2** - 🔧 Creating a custom pool factory, deploying it, and generating said pool from it that you can interact with using the front end in your local host.
3. **Checkpoint 3** - 🧪 Writing Typical Unit and Fuzz Tests for Custom Pool Example
4. **Checkpoint 4** - 🎨 Creating Your Own Custom Pool with the Template Files
5. **Checkpoint 5** - 📡 Integrate pool with the Balancer v3 Subgraph
6. **Checkpoint 6** - 🧭 Integrate pool with the Smart Order Router (SOR)

In general, all smart contracts sections of this repo will already have `Example` smart contracts. These smart contract examples will be explained within this README.

## 🚨🚨 Checkpoint 0: 📦 Environment 📚

### 0.1 Requirements

Before you begin, you need to install the following tools:

- [Node (>= v18.17)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### 0.2 Quickstart

Speedrun deploying your first custom pool to get acquainted with our pool explorer

#### 0.2.0 Clone Repo

```bash
git clone git@github.com:MattPereira/scaffold-balancer-v3.git
```

#### 0.2.1 Install Dependencies

```bash
yarn install
```

#### 0.2.3 Set Environment Variables

Set a `DEPLOYER_PRIVATE_KEY`, `ALCHEMY_API_KEY`, and `ETHERSCAN_API_KEY` at the path `packagages/foundry/.env`

```
DEPLOYER_PRIVATE_KEY=0x...
ETHERSCAN_API_KEY=...
ALCHEMY_API_KEY=...
```

#### 0.2.4 Start Local Anvil Fork

```bash
yarn fork
```

#### 0.2.5 Deploy Contracts

The following command runs the script from `Deploy.s.sol`

1. A pool factory is deployed
2. Test tokens are deployed and sent to the `.env` PK
3. New pool is created using the pool factory and the test tokens
4. New pool is initialized using test tokens and BPT is sent to the `.env` PK

```bash
yarn deploy --reset
```

#### 0.2.6 Start Frontend

```bash
yarn start
```

#### 0.2.7 Select Your Pool

Navigate to http://localhost:3000/pools and click the dropdown to select the custom pool you just deployed to your local anvil node

TODO @matt: GIF GOES HERE

#### 0.2.8 Use Your Pool

Start splashing around in your pool with swaps, joins, and exits!

TODO @matt - Showcase the front end at a high level (showing, with a pool address input already, the possible interactions you can do with it).

### 0.3 Scaffold ETH 2 Tips

#### 0.3.1 Changing The Frontend Network Connection

- The network the frontend points at is set via `targetNetworks` in the `scaffold.config.ts` file
- To point the frontend at your local fork, use `chains.foundry`

```typescript
	targetNetworks: [chains.foundry],
```

#### 0.3.1 Changing The Forked Network

- Modify the "fork" alias in the `packages/foundry/package.json` file, but do not change the chain id

```json
	"fork": "anvil --fork-url ${0:-sepolia} --chain-id 31337 --config-out localhost.json",
```

- `foundry.toml` comes preconfigured with a variety of `rpc_endpoints`

## 🚨🚨 Checkpoint 1: 🌊 Create A Custom Pool

Ultimately, this repo can be used to create custom pool factories, custom pools from said factory, and register and initialize them so the pools can be interacted with using this repo's front end, all in a local environment. Before jumping into all of that, it is key that developers understand the general make-up of a custom pool.

Therefore, this checkpoint focuses on writing the smart contract for a custom pool (without a factory). We will walk through the `ConstantPricePoolExample.sol` found within `packages/hardhat/contracts/ConstantPricePoolExample.sol`.

### 1.1 Write a Custom Pool Contract

- All custom pool contracts must inherit from `IBasePool` and `BalancerPoolToken` and implement the three required functions: `onSwap`, `computeInvariant`, and `computeBalance`

- Begin your journey by reading the [docs on creating a custom pool](https://docs-v3.balancer.fi/concepts/guides/create-custom-amm-with-novel-invariant.html#build-your-custom-amm).

- TODO --> input more details

Let's walk through each function in `ConstantPricePoolExample.sol`

#### 1.1.1 `onSwap()` Implementation - TODO

- Looking at monorepo, one sees that `onSwap()` is ultimately called to return a value that ...

- In the case of the Constant Price Pool example, you can see that the amountCalculatedScaled18 is simply the amountGivenScaled18.

> **Recall the architecture of BalancerV3, and how each custom pool function is called throughout the typical transactions carried out within the protocol.**

---

<details markdown='1'><summary>👩🏽‍🏫 Solution Code for `onSwap` functions </summary>
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

---

#### 🥅 ** `onSwap()` Goals / Checks**

- [ ] ❓ Can you describe how `onSwap()` works within the Balancer V3 monorepo architecture and thus how custom pools must accomodate said architecture?

---

#### 1.1.2 `computeInvariant()` Implementation TODO

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

#### 1.1.2 `computeBalance()` Implementation TODO

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

## 🚨🚨 Checkpoint 2: 🔧 Create a custom pool factory && Interact with Resultant Custom Pools

Now that you have created a custom pool, it is time to deploy the associated custom pool factory. For this repo, we've created a custom pool factory example and associated script to deploy it, and create a new pool using said factory.

The example factory continues off of the previous section and uses `ConstantPricePool.sol` as the Custom Pool type.

The concept is that once the custom pool factory is deployed, anyone can come along and deploy more of that specific custom pool type, with varying pool parameters. Within the script the first pool from said factory is deployed, registered, and initialized, so you can interact with it right away. Another script is created so you can create more pools and enter in the param details via your favorite code editor too.

This section will walk you through:

- Creating and Deploying the custom pool factory example.
- Running the script to deploy more pools from said custom pool factory.
- Interacting with the pool factory within the ScaffoldBalancer UI with the Debug Tab.

## Checkpoint 2.1: Creating the Custom Pool Factory

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

### 2.1.1 `create()` Function

The `create()` function, in this simple example pool factory, simply calls the `_create()` function within the `BasePoolFactory.sol`. The `_create()` function uses `CREATE3`, similar to `CREATE2` to deploy a pool that has a pre-determined address based on its salt, and encoded creation code & args.

Here is the `_create()` internal function for reference:

```
function _create(bytes memory constructorArgs, bytes32 salt) internal returns (address) {
        return CREATE3.deploy(salt, abi.encodePacked(_creationCode, constructorArgs), 0);
    }
```

Within the function `create()` we call `_create()` with appropriate params, which will be touched on later within our scripts. For now, we move onto the next aspect of the `create()` call, which is to `registerPool()` with the BalancerV3 vault.

### 2.1.2 Calling `registerPool()`

New pools need to be registered to the BalancerV3 vault to operate within the BalancerV3 architecture.

TODO - reference `IVaultExtension.sol` for details.

TODO - Finally, the `create()` function ends by calling `_registerPoolWithFactory(newPool)` which registers the new pool with the respective factory. This is done for accounting purposes, amongst other reasons.

> NOTE: like all other contracts and scripts within this repo, one must adjust aspects within this smart contract when creating their own type of custom pool.

## Checkpoint 2.2: Deploying the Custom Pool Factory

Now that we have created the `CustomPoolFactoryExample.sol` contract, it is time to write the deployment scripts. We've provided example deployment scripts to reference as you create your own, and will walk through key gotcha's when writing your own deployment scripts. As always, test on your own before deploying!

`DeployCustomPoolFactoryAndNewPoolExample.s.sol` is the file that we will use as a template.

For sake of simplicity, we will outline the core function of the script, and then explain specific gotchas with the script. The main one being the params involved with initialization.

### Core Script Function

The script, using the `.env` specified deployer wallet, deploys the custom pool factory (currently the constant price custom pool), creates a new pool with it, registers the new pool with the BalancerV3 Vault on sepolia, and initializes it. It does all of this so it is ready to use with the ScaffoldBalancer front end tool. The variables defined when calling Balancer functions, like `Router.intiialize()` are specific to the constant price custom pool setup, whereas if you are working with a more complicated pool setup you may want to adjust these params as necessary.

### Key Gotchas

- Specific to this repo, the script inherits `TestAddresses` and `HelperFunctions`.
- Balancer integration with `initialize()` has a couple of arrays that must match in terms of token ERC20 we are using, and the amounts of said token.
- Section incased in `/// Custom Pool Variables Subject to Change START ///` and `/// Custom Pool Variables Subject to Change END ///` are variables to be changed if you are changing the type of the custom pool being created.

> It is key to understand that the script is calling `Router.initialize()` ultimately, and so understanding this function call and its params is crucial. See the BalancerV3 monorepo for more info. We touch on some of these params below, but the nat spec is also a great resource.

- Some variables have comments on them to assist, such as the custom pool factory
- This script uses FakeTestERC20 contracts to instantly mint 1000 of each test token to deployer wallet.
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

## Checkpoint 2.3: Interacting with the Testnet Custom Pool Factory via Scripts

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

## TODO - Checkpoint 2.4: Interacting with the Testnet Custom Pool Factory via Debug Tab - @matt, I think we may need to delete this one for milestone 1, seeing as it is more imperative that pools are created via a script. I think having the debug tab show the factory contract still is cool, but the `create()` function sounds like it will be tricky to work with. wdyt?

At this point, the factory has been deployed, and you have deployed at least one more pool from the factory using the scripts within this repo.

<!-- TODO - assess if this section is needed anymore since we are going with scripts.

Pools can also be created using the Debug Tab, theoretically. Currently SE-2 has some trouble with structs within the debug tab, and as such it is recommended to use scripts to work with any input params involving structs.

That said, this section outlines how one would use the debug tab to create a pool using a factory contract.

  -->

### TODO - 2.5 Interact with your custom pool

- On the `localhost:3000/pools` page, select your custom pool from the dropdown
- Review the pool details and composition post pool initialization
- Try out executing a swap, join, and exit with your custom pool

---

## 🚨🚨 Checkpoint 3: Writing Typical Unit and Fuzz Tests for Custom Pool Example

<!-- STEVE THIS IS WHERE YOU LEFT OFF -->

At this point we've gone through how to make a simple custom pool and custom pool factory, and to simulate and/or deploy them on a testnet. Testing is of course needed, amongst many other security measures such as audits, for a custom pool implementation.

We will now walk through the testing contract, provided as foundry tests, and typescript files. These testing files can be used as a testing template, similar to how the smart contracts and scripts so far could be used as references or templates for your own custom pool implementation.

### `ConstantPricePoolTest.t.sol`

<!-- TODO -->

## 🚨🚨 Checkpoint 4: Creating Your Own Custom Pool with the Template Files

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

## 🚨🚨 Checkpoint 5: 🧭 Integrate pool with the Smart Order Router (SOR)

TBD

## 🚨🚨 Checkpoint 6: 📡 Integrate pool with the Balancer v3 Subgraph

TBD
