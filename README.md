# 🏗 Scaffold-Balancer

A series of guides and a prototyping tools for creating custom pools that integrate with Balancer v3

## Decision Records

- Using SE-2 hardhat with added `hardhat-foundry` plugin
  - devs can choose preference of deploying / testing with hardhat or foundry
  - balancer will release npm packages for their v3 contracts

## Requirements

Before you begin, you need to install the following tools:

- [Node (>= v18.17)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

## Quickstart

1. Clone the repo (with SSH since private for now)

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

1. Set a `DEPLOYER_PRIVATE_KEY` in a `.env` at path `packagages/hardhat/.env`. Only do this with a develpment specific wallet that has only testnet funds. **NEVER PUT REAL FUNDS AT RISK WITH A PLAIN TEXT PRIVATE KEY**

2. Run the deploy script. Note that whenever you deploy new contract the frontend will automatically be updated to point at the newly deployed contract

```
yarn deploy --network sepolia
```
