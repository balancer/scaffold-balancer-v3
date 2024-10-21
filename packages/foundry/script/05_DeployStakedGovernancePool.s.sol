// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    TokenConfig,
    TokenType,
    LiquidityManagement,
    PoolRoleAccounts
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IRateProvider } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import { InputHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { PoolHelpers, CustomPoolConfig, InitializationConfig } from "./PoolHelpers.sol";
import { ScaffoldHelpers, console } from "./ScaffoldHelpers.sol";
import { ConstantSumFactory } from "../contracts/factories/ConstantSumFactory.sol";
import { StakedGovernanceHook } from "../contracts/hooks/StakedGovernanceHook.sol";
import { IGovernanceToken } from "../contracts/hooks/StakedGovernanceHook.sol";

contract DeployStakedGovernancePool is PoolHelpers, ScaffoldHelpers {
    function deployStakedGovernancePool(address stableToken, address pairedToken, address governanceToken) internal {
        CustomPoolConfig memory poolConfig = getStakedGovernancePoolConfig(stableToken, pairedToken);
        InitializationConfig memory initConfig = getStakedGovernancePoolInitConfig(stableToken, pairedToken);

        uint256 deployerPrivateKey = getDeployerPrivateKey();
        vm.startBroadcast(deployerPrivateKey);

        // Deploy a factory
        ConstantSumFactory factory = new ConstantSumFactory(vault, 365 days);
        console.log("Constant Sum Factory deployed at: %s", address(factory));

        // Deploy the StakedGovernanceHook
        StakedGovernanceHook stakedGovernanceHook = new StakedGovernanceHook(
            vault,
            IGovernanceToken(governanceToken),
            IERC20(stableToken)
        );
        console.log("StakedGovernanceHook deployed at: %s", address(stakedGovernanceHook));

        // Deploy a pool and register it with the vault
        address pool = factory.create(
            poolConfig.name,
            poolConfig.symbol,
            poolConfig.salt,
            poolConfig.tokenConfigs,
            poolConfig.swapFeePercentage,
            poolConfig.protocolFeeExempt,
            poolConfig.roleAccounts,
            address(stakedGovernanceHook),
            poolConfig.liquidityManagement
        );
        console.log("Staked Governance Pool deployed at: %s", pool);

        // Approve the router to spend tokens for pool initialization
        approveRouterWithPermit2(initConfig.tokens);

        // Seed the pool with initial liquidity
        router.initialize(
            pool,
            initConfig.tokens,
            initConfig.exactAmountsIn,
            initConfig.minBptAmountOut,
            initConfig.wethIsEth,
            initConfig.userData
        );
        console.log("Staked Governance Pool initialized successfully!");
        vm.stopBroadcast();
    }

    function getStakedGovernancePoolConfig(address stableToken, address pairedToken) internal view returns (CustomPoolConfig memory config) {
        string memory name = "Staked Governance Pool";
        string memory symbol = "SGP";
        bytes32 salt = keccak256(abi.encode(block.number));
        uint256 swapFeePercentage = 0.003e18; // 0.3%
        bool protocolFeeExempt = false;

        TokenConfig[] memory tokenConfigs = new TokenConfig[](2);
        tokenConfigs[0] = TokenConfig({
            token: IERC20(stableToken),
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            paysYieldFees: false
        });
        tokenConfigs[1] = TokenConfig({
            token: IERC20(pairedToken),
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            paysYieldFees: false
        });

        PoolRoleAccounts memory roleAccounts = PoolRoleAccounts({
            pauseManager: address(0),
            swapFeeManager: address(0),
            poolCreator: address(0)
        });

        LiquidityManagement memory liquidityManagement = LiquidityManagement({
            disableUnbalancedLiquidity: false,
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false,
            enableDonation: false
        });

        config = CustomPoolConfig({
            name: name,
            symbol: symbol,
            salt: salt,
            tokenConfigs: sortTokenConfig(tokenConfigs),
            swapFeePercentage: swapFeePercentage,
            protocolFeeExempt: protocolFeeExempt,
            roleAccounts: roleAccounts,
            poolHooksContract: address(0), // We'll set this to the StakedGovernanceHook address later
            liquidityManagement: liquidityManagement
        });
    }

    function getStakedGovernancePoolInitConfig(address stableToken, address pairedToken) internal pure returns (InitializationConfig memory config) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = IERC20(stableToken);
        tokens[1] = IERC20(pairedToken);

        uint256[] memory exactAmountsIn = new uint256[](2);
        exactAmountsIn[0] = 1000e18; // Initial liquidity of 1000 stable tokens
        exactAmountsIn[1] = 1000e18; // Initial liquidity of 1000 paired tokens (adjust as needed)

        uint256 minBptAmountOut = 1999e18; // Expect to receive at least 1999 BPT
        bool wethIsEth = false;
        bytes memory userData = "";

        config = InitializationConfig({
            tokens: InputHelpers.sortTokens(tokens),
            exactAmountsIn: exactAmountsIn,
            minBptAmountOut: minBptAmountOut,
            wethIsEth: wethIsEth,
            userData: userData
        });
    }
}