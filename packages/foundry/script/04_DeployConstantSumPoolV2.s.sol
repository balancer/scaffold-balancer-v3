//SPDX-License-Identifier: MIT
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
import { ConstantSumFactoryV2 } from "../contracts/factories/ConstantSumFactoryV2.sol";
import { TimeBasedDiscountHook } from "../contracts/hooks/TimeBasedDiscountHook.sol";

contract DeployConstantSumPoolV2 is PoolHelpers, ScaffoldHelpers {
    /**
     * @notice Deploys a Constant Sum Pool V2 with the given tokens and veBAL address.
     * @param token1 The address of the first token.
     * @param token2 The address of the second token.
     * @param veBAL The address of the veBAL token.
     */
    function deployConstantSumPoolV2(address token1, address token2, address veBAL) internal {
        CustomPoolConfig memory poolConfig = getSumPoolConfigV2(token1, token2);
        InitializationConfig memory initConfig = getSumPoolInitConfigV2(token1, token2);

        uint256 deployerPrivateKey = getDeployerPrivateKey();
        vm.startBroadcast(deployerPrivateKey);

        ConstantSumFactoryV2 factory = new ConstantSumFactoryV2(vault, 365 days);
        console.log("Constant Sum Factory deployed at: %s", address(factory));

        address timeBasedDiscountHook = address(
            new TimeBasedDiscountHook(vault, address(factory), address(router), veBAL, 9, 4, 40)
        );
        console.log("TimeBasedDiscountHook deployed at address: %s", timeBasedDiscountHook);

        address pool = factory.create(
            poolConfig.name,
            poolConfig.symbol,
            poolConfig.salt,
            poolConfig.tokenConfigs,
            poolConfig.swapFeePercentage,
            poolConfig.protocolFeeExempt,
            poolConfig.roleAccounts,
            timeBasedDiscountHook,
            poolConfig.liquidityManagement
        );
        console.log("Constant Sum Pool V2 deployed at: %s", pool);

        approveRouterWithPermit2(initConfig.tokens);

        router.initialize(
            pool,
            initConfig.tokens,
            initConfig.exactAmountsIn,
            initConfig.minBptAmountOut,
            initConfig.wethIsEth,
            initConfig.userData
        );
        console.log("Constant Sum Pool V2 initialized successfully!");
        vm.stopBroadcast();
    }

    /**
     * @notice Returns the configuration for the Constant Sum Pool V2.
     * @param token1 The address of the first token.
     * @param token2 The address of the second token.
     * @return config The configuration for the Constant Sum Pool V2.
     */
    function getSumPoolConfigV2(address token1, address token2) internal view returns (CustomPoolConfig memory config) {
        string memory name = "Constant Sum Pool V2";
        string memory symbol = "CSP";
        bytes32 salt = keccak256(abi.encode(block.number));
        uint256 swapFeePercentage = 0.01e18;
        bool protocolFeeExempt = true;
        address poolHooksContract = address(0);

        TokenConfig[] memory tokenConfigs = new TokenConfig[](2);
        tokenConfigs[0] = TokenConfig({
            token: IERC20(token1),
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            paysYieldFees: false
        });
        tokenConfigs[1] = TokenConfig({
            token: IERC20(token2),
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
            poolHooksContract: poolHooksContract,
            liquidityManagement: liquidityManagement
        });
    }

    /**
     * @notice Returns the initialization configuration for the Constant Sum Pool V2.
     * @param token1 The address of the first token.
     * @param token2 The address of the second token.
     * @return config The initialization configuration for the Constant Sum Pool V2.
     */
    function getSumPoolInitConfigV2(
        address token1,
        address token2
    ) internal pure returns (InitializationConfig memory config) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = IERC20(token1);
        tokens[1] = IERC20(token2);
        uint256[] memory exactAmountsIn = new uint256[](2);
        exactAmountsIn[0] = 50e18;
        exactAmountsIn[1] = 50e18;
        uint256 minBptAmountOut = 99e18;
        bool wethIsEth = false;
        bytes memory userData = bytes("");

        config = InitializationConfig({
            tokens: InputHelpers.sortTokens(tokens),
            exactAmountsIn: exactAmountsIn,
            minBptAmountOut: minBptAmountOut,
            wethIsEth: wethIsEth,
            userData: userData
        });
    }
}
