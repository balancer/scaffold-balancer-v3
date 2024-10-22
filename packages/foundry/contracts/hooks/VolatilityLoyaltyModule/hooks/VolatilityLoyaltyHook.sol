// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IPoolInfo } from "@balancer-labs/v3-interfaces/contracts/pool-utils/IPoolInfo.sol";

import {
    LiquidityManagement,
    AfterSwapParams,
    PoolSwapParams,
    SwapKind,
    TokenConfig,
    HookFlags,
    RemoveLiquidityKind,
    AddLiquidityKind
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";

import { IVolatilityOracle } from "../volatility-module/IVolatilityOracle.sol";
import { ILoyaltyDiscount } from "../loyalty-module/ILoyaltyDiscount.sol";
import { IVolatilityDiscount } from "../volatility-module/IVolatilityDiscount.sol";

import "forge-std/console.sol";

contract VolatilityLoyaltyHook is BaseHooks, VaultGuard, Ownable {
    using FixedPoint for uint256;

    address private _tokenAddress;
    address private _oracleAddress;
    address private _loyaltyModuleAddress;
    address private _volatilityModuleAddress;
    address private _allowedFactory;
    bool public isLoyaltyDiscountEnabled;
    bool public isVolatilityFeeEnabled;

    constructor(
        IVault vault,
        address tokenAddress,
        address oracleAddress,
        address loyaltyModuleAddress,
        address volatilityModuleAddress,
        address allowedFactory
    ) VaultGuard(vault) Ownable(msg.sender) {
        _tokenAddress = tokenAddress;
        _oracleAddress = oracleAddress;
        _loyaltyModuleAddress = loyaltyModuleAddress;
        _volatilityModuleAddress = volatilityModuleAddress;
        _allowedFactory = allowedFactory;
    }

    event PriceDataUpdated(uint256 tokenOutBalanceScaled18, uint256 tokenInBalanceScaled18, uint256 tokenPrice);

    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override onlyVault returns (bool) {
        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        hookFlags.enableHookAdjustedAmounts = false;
        hookFlags.shouldCallAfterSwap = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
        hookFlags.shouldCallAfterAddLiquidity = true;
        hookFlags.shouldCallComputeDynamicSwapFee = true;
        return hookFlags;
    }

    function onAfterRemoveLiquidity(
        address,
        address,
        RemoveLiquidityKind,
        uint256,
        uint256[] memory,
        uint256[] memory amountsOutRaw,
        uint256[] memory balancesScaled18,
        bytes memory
    ) public override onlyVault returns (bool, uint256[] memory) {
        IVolatilityOracle volatilityOracle = IVolatilityOracle(_oracleAddress);
        uint256 tokenIndex = 1; // 2 token pool, 2nd token is the token under consideration

        volatilityOracle.updateOracle(balancesScaled18[1 - tokenIndex], balancesScaled18[tokenIndex]);

        return (true, amountsOutRaw); // check if false works here
    }

    function onAfterAddLiquidity(
        address,
        address,
        AddLiquidityKind,
        uint256[] memory,
        uint256[] memory amountsInRaw,
        uint256,
        uint256[] memory balancesScaled18,
        bytes memory
    ) public override onlyVault returns (bool, uint256[] memory) {
        IVolatilityOracle volatilityOracle = IVolatilityOracle(_oracleAddress);
        uint256 tokenIndex = 1; // 2 token pool, 2nd token is the token under consideration

        volatilityOracle.updateOracle(balancesScaled18[1 - tokenIndex], balancesScaled18[tokenIndex]);

        return (true, amountsInRaw); // check if false works here
    }

    function onAfterSwap(AfterSwapParams calldata params) public override onlyVault returns (bool, uint256) {
        IVolatilityOracle volatilityOracle = IVolatilityOracle(_oracleAddress);
        if (address(params.tokenIn) == _tokenAddress) {
            volatilityOracle.updateOracle(params.tokenOutBalanceScaled18, params.tokenInBalanceScaled18);
            // emit event
        } else if (address(params.tokenOut) == _tokenAddress) {
            volatilityOracle.updateOracle(params.tokenInBalanceScaled18, params.tokenOutBalanceScaled18);
            // emit event
        } else {
            // revert with error
        }

        address user = IRouterCommon(params.router).getSender();

        ILoyaltyDiscount loyaltyModule = ILoyaltyDiscount(_loyaltyModuleAddress);

        loyaltyModule.updateLoyaltyDataForUser(
            user,
            _tokenAddress,
            params.tokenIn,
            params.amountInScaled18,
            params.amountOutScaled18
        );

        return (true, params.amountCalculatedRaw);
    }

    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address,
        uint256 staticSwapFeePercentage
    ) public view override onlyVault returns (bool, uint256) {
        address user = IRouterCommon(params.router).getSender();

        uint256 swapFeePercentWithLoyaltyDiscount = isLoyaltyDiscountEnabled
            ? getSwapFeeWithLoyaltyDiscount(user, staticSwapFeePercentage)
            : staticSwapFeePercentage;

        uint256 volatilityFeePercent = isVolatilityFeeEnabled ? getVolatilityFee() : 0;

        uint256 totalSwapFeePercent = swapFeePercentWithLoyaltyDiscount + volatilityFeePercent;

        return (true, totalSwapFeePercent);
    }

    function changeLoyaltyDiscountSetting() public onlyOwner {
        isLoyaltyDiscountEnabled = !isLoyaltyDiscountEnabled;
    }

    function changeVolatilityFeeSetting() public onlyOwner {
        isVolatilityFeeEnabled = !isVolatilityFeeEnabled;
    }

    function getSwapFeeWithLoyaltyDiscount(
        address user,
        uint256 staticSwapFeePercentage
    ) internal view returns (uint256) {
        ILoyaltyDiscount loyaltyModule = ILoyaltyDiscount(_loyaltyModuleAddress);
        return loyaltyModule.getSwapFeeWithLoyaltyDiscount(user, staticSwapFeePercentage);
    }

    function getVolatilityFee() internal view returns (uint256) {
        IVolatilityDiscount volatilityModule = IVolatilityDiscount(_volatilityModuleAddress);
        return volatilityModule.getVolatilityFeePercent(_oracleAddress);
    }
}
