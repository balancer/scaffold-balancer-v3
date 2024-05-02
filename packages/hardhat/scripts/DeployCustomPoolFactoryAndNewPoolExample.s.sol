// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "../contracts/interfaces/IVaultExtension.sol";
import {LiquidityManagement, IRateProvider, PoolHooks, TokenConfig, TokenType} from "../contracts/interfaces/VaultTypes.sol";
import {TestAddresses} from "../test/utils/TestAddresses.sol";
import {CustomPoolFactoryExample} from "../contracts/CustomPoolFactoryExample.sol";
import {FakeTestERC20} from "../contracts/FakeTestERC20.sol";
import {HelperFunctions} from "../test/utils/HelperFunctions.sol";
import {IRouter} from "../contracts/interfaces/IRouter.sol";

/**
 * @title DeployCustomPoolFactoryAndNewPoolExample Script
 * @author BUIDL GUIDL (placeholder)
 * @notice The script, using the `.env` specified deployer wallet, deploys the custom pool factory (currently the constant price custom pool), creates a new pool with it, registers the new pool with the BalancerV3 Vault on sepolia, and initializes it. It does all of this so it is ready to use with the ScaffoldBalancer front end tool.
 * @dev to run sim for script, run the following CLI command: `source .env && forge script scripts/DeployCustomPoolFactoryAndNewPoolExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY`
 * @dev to run the actual script on Sepolia network, run the following CLI command: `source .env && forge script scripts/DeployCustomPoolFactoryAndNewPoolExample.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --slow --broadcast`
 */
contract DeployCustomPoolFactoryAndNewPoolExample is
    TestAddresses,
    HelperFunctions,
    Script
{
    /// Vars stated here to avoid stack too deep errors
    uint256 pauseWindowDuration = 365 days; // NOTE: placeholder pauseWindowDuration var
    address newPool;
    IERC20[] tokens = new IERC20[](2); // Tokens used to seed the pool (must match the registered tokens)
    uint256[] exactAmountsIn = new uint256[](2); // Tokens used to seed the pool (must match the registered tokens)
    uint256 internal minBptAmountOut;
    bytes userData;

    function runDeployCustomPoolFactoryAndNewPoolExample() internal {
        /// Custom Pool Variables Subject to Change START ///
        CustomPoolFactoryExample customPoolFactory = new CustomPoolFactoryExample(
                vault,
                pauseWindowDuration
            ); // TODO - replace with your own custom pool factory and respective constructor params.

        FakeTestERC20 scUSD = new FakeTestERC20(
            "Scaffold Balancer Test Token #1",
            "scUSD"
        ); // This script uses FakeTestERC20 contracts to instantly mint 1000 of each test token to deployer wallet.
        FakeTestERC20 scDAI = new FakeTestERC20(
            "Scaffold Balancer Test Token #2",
            "scDAI"
        );

        TokenConfig[] memory tokenConfig = new TokenConfig[](2); // An array of descriptors for the tokens the pool will manage.

        // make sure to have proper token order (alphanumeric)
        tokenConfig[1] = TokenConfig({
            token: IERC20(address(scDAI)),
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            yieldFeeExempt: false
        });
        tokenConfig[0] = TokenConfig({
            token: IERC20(address(scUSD)),
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            yieldFeeExempt: false
        });

        string memory name = "Example Custom Constant Price Pool #1";
        string memory symbol = "cBPT1";
        bytes32 salt = convertNameToBytes32(name);

        newPool = customPoolFactory.create(name, symbol, tokenConfig, salt);

        tokens[0] = tokenConfig[0].token;
        tokens[1] = tokenConfig[1].token;

        exactAmountsIn[0] = 1 ether; // assume that scUSD and scDAI are pegged / same price (1 USD).
        exactAmountsIn[1] = 1 ether;
        minBptAmountOut = 1 ether;
        userData = bytes("");

        /// Custom Pool Variables Subject to Change END ///

        {
            approveForSender();
            approveForPool(IERC20(newPool));

            router.initialize(
                newPool,
                tokens,
                exactAmountsIn,
                minBptAmountOut,
                false,
                userData
            ); // Initializes a registered pool by adding liquidity; mints BPT tokens for the first time in exchange.
        }

        console.log("Factory Address: %s", address(customPoolFactory)); // address generated to be used within `DeployCustomPoolFromFactoryExample.s.sol`
        console.log("Pool Address: %s", address(newPool)); // search this address on frontend of scaffold balancer on the "Pools" explorer page
    }

    function approveForSender() internal {
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(address(router), type(uint256).max);
            tokens[i].approve(address(vault), type(uint256).max);
        }
    }

    function approveForPool(IERC20 bpt) internal {
        bpt.approve(address(router), type(uint256).max);
        bpt.approve(address(vault), type(uint256).max);
    }
}
