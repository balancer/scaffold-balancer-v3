# 🏗 Scaffold-Balancer

A series of guides and a prototyping tools for creating custom pools that integrate with Balancer v3

## Requirements

Before you begin, you need to install the following tools:

- [Node (>= v18.17)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

## Quickstart

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

## Deploying Contracts

1. Set a `DEPLOYER_PRIVATE_KEY` in a `.env` at path `packagages/hardhat/.env`

2. Run the deploy script\*

```
yarn deploy --network sepolia
```

\*Whenever you deploy new contract the frontend will automatically update to point at the newly deployed contract

## How To Create Custom Pool

1. Deploy a contract that inherits from `IBasePool` and `BalancerPoolToken` and impliments the three required functions: `onSwap`, `computeInvariant`, and `computeBalance`
   - [See docs on creating custom pool](https://docs-v3.balancer.fi/concepts/guides/create-custom-amm-with-novel-invariant.html#build-your-custom-amm)
2. Register the pool with the `Vault` by calling `VaultExtension.registerPool` with the necessary arguments
3. Initialize the pool with the `Vault` by calling `Router.initialize` with the necessary arguments
   - [See docs on`Router.initialize`](https://docs-v3.balancer.fi/concepts/router/overview.html#initialize)

## How To Interact With A Custom Pool

- The `Router` is the recommended entrypoint for all user operations
  - [See Router Technical Description](https://docs-v3.balancer.fi/concepts/router/technical.html)
- The `Router` provides functions for querying and executing `swap`, `add`, and `remove`
  - [See Router API](https://docs-v3.balancer.fi/concepts/router/overview.html)
