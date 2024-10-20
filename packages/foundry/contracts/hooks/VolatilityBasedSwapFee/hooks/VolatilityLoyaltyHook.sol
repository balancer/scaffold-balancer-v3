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

import { VolatilityOracle } from "../VolatilityOracle.sol";

import "forge-std/console.sol";

// only for 2 token pools
contract VolatilityLoyaltyHook is BaseHooks, VaultGuard {
    using FixedPoint for uint256;

    address public _tokenAddress; // making public for debugging purposes only
    address public _oracleAddress; // making public for debugging purposes only
    address public _factoryAddress; // allow only contant product factory
    uint256 public _variableFeeCap; // making public for debugging purposes only
    bool public _isLoyaltyDiscountEnabled; // making public for debugging purposes only
    bool public _isVolatilityFeeEnabled; // making public for debugging purposes only

    uint256 private constant _LOYALTY_REFRESH_WINDOW = 30 days;
    uint256 private constant _VOLATILITY_WINDOW = 10 seconds;
    uint256 private constant _LOYALTY_FEE_CAP = 0.01e18; // 1 %
    uint256 private constant _VOLATILITY_FEE_CAP = 0.04e18; // 4 %

    struct LoyaltyData {
        uint256 firstTransactionTimestamp; // first transaction in the _LOYALTY_INDEX_REFRESH_TIME window, the _LOYALTY_REFRESH_WINDOW value is same, but the start and end timestamps of the window is different for each user
        uint256 cumulativeLoyalty; // change name to loyalty index, its dimension/unit it token * seconds
        uint256 tokens;
        uint256 lastTimestamp; // make it lastTransactionTImestamp
    }

    mapping(address => LoyaltyData) public userLoyaltyData;

    // add checks :
    // only 2-token pools
    // froma registered factory
    constructor(IVault vault, address tokenAddress, uint256 variableFeeCap, address oracleAddress) VaultGuard(vault) {
        _tokenAddress = tokenAddress;
        _oracleAddress = oracleAddress;
        _variableFeeCap = variableFeeCap;
        _isLoyaltyDiscountEnabled = false;
        console.log("(getTokenBalanceOfUser) vault", address(vault));
    }

    // --------------------------------------------------------------------
    // ------------------------ Events & Errors ---------------------------
    // --------------------------------------------------------------------

    event PriceDataUpdated(uint256 tokenOutBalanceScaled18, uint256 tokenInBalanceScaled18, uint256 tokenPrice);

    // --------------------------------------------------------------------
    // ------------------------ Hook Stuff --------------------------------
    // --------------------------------------------------------------------

    // add checks :
    // only 2 token pools
    // from a registered factory
    function onRegister(
        address,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override returns (bool) {
        return true;
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
    ) public override returns (bool, uint256[] memory) {
        console.log("(onAfterRemoveLiquidity) executed now");
        address[] memory tokenAddresses = getAllTokenConfigs(_factoryAddress); // -> need to do this cuz we do not know that what index points to what token address
        VolatilityOracle volatilityOracle = VolatilityOracle(_oracleAddress);
        uint256 tokenIndex;

        if (tokenAddresses[0] == _tokenAddress) {
            tokenIndex = 0;
            // emit event
        } else if (tokenAddresses[1] == _tokenAddress) {
            tokenIndex = 1;
            // emit event
        } else {
            // revert with error
        }

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
    ) public override returns (bool, uint256[] memory) {
        console.log("(onAfterAddLiquidity) executed now");
        address[] memory tokenAddresses = getAllTokenConfigs(_factoryAddress); // -> need to do this cuz we do not know that what index points to what token address
        VolatilityOracle volatilityOracle = VolatilityOracle(_oracleAddress);
        uint256 tokenIndex;

        if (tokenAddresses[0] == _tokenAddress) {
            tokenIndex = 0;
            // emit event
        } else if (tokenAddresses[1] == _tokenAddress) {
            tokenIndex = 1;
            // emit event
        } else {
            // revert with error
        }

        volatilityOracle.updateOracle(balancesScaled18[1 - tokenIndex], balancesScaled18[tokenIndex]);

        return (true, amountsInRaw); // check if false works here
    }

    function onAfterSwap(AfterSwapParams calldata params) public override returns (bool, uint256) {
        console.log("(onAfterSwap) executed now");
        VolatilityOracle volatilityOracle = VolatilityOracle(_oracleAddress);
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

        LoyaltyData memory loyaltyData = userLoyaltyData[user];

        uint256 currentTimestamp = block.timestamp;

        console.log("(onAfterSwap) currentTimestamp", currentTimestamp);

        uint256 oldFirstTransactionTimestamp = loyaltyData.firstTransactionTimestamp;

        bool isLoyaltyWindowRefreshed = (currentTimestamp - oldFirstTransactionTimestamp) >= _LOYALTY_REFRESH_WINDOW;

        console.log(
            "(onAfterSwap) isLoyaltyWindowRefreshed, loyaltyData.tokens",
            isLoyaltyWindowRefreshed,
            uint256(loyaltyData.tokens)
        );

        // instead of old make it current
        uint256 oldTimestamp = loyaltyData.lastTimestamp;
        uint256 oldCumulativeLoyalty = isLoyaltyWindowRefreshed ? 0 : loyaltyData.cumulativeLoyalty;
        uint256 oldTokens = isLoyaltyWindowRefreshed ? 0 : loyaltyData.tokens;

        console.log("(onAfterSwap) userLoyaltyData[user] oldFirstTransactionTimestamp", oldFirstTransactionTimestamp);

        console.log(
            "(onAfterSwap) oldCumulativeLoyalty, oldTokens, oldTimestamp",
            uint256(oldCumulativeLoyalty),
            uint256(oldTokens),
            oldTimestamp
        );

        // cumulative loyalty and tokens should always be positive
        uint256 newCumulativeLoyalty = oldCumulativeLoyalty + (oldTokens * (currentTimestamp - oldTimestamp)); // remove this comment before submission, y = mx + c, y-> new cumulative loyalty, m -> tokens held, x -> time passed, c -> cumulative loyalty so far
        int256 additionalTokens = (address(params.tokenIn) == _tokenAddress)
            ? -1 * int256(params.amountInScaled18)
            : int256(params.amountOutScaled18);
        uint256 newTimestamp = currentTimestamp;
        uint256 newFirstTransactionTimestamp = isLoyaltyWindowRefreshed
            ? currentTimestamp
            : oldFirstTransactionTimestamp;

        uint256 newTokens = (uint256(additionalTokens) + oldTokens) > 0
            ? uint256(uint256(additionalTokens) + oldTokens)
            : 0; // loyalty and tokens can never be zero

        userLoyaltyData[user] = LoyaltyData(
            newFirstTransactionTimestamp,
            newCumulativeLoyalty,
            newTokens,
            newTimestamp
        );

        console.log(
            "(onAfterSwap) userLoyaltyData[user] firstTransactionTimestamp",
            userLoyaltyData[user].firstTransactionTimestamp
        );

        console.log(
            "(onAfterSwap) userLoyaltyData[user] newCumulativeLoyalty, newTokens, newTimestamp",
            uint256(userLoyaltyData[user].cumulativeLoyalty),
            uint256(userLoyaltyData[user].tokens),
            userLoyaltyData[user].lastTimestamp
        );

        return (true, params.amountCalculatedRaw);
    }

    // staticSwapFeePercentage -> split this between fixed and loyaltyFee
    // then add volatilityFee based on pool volatility
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address,
        uint256 staticSwapFeePercentage
    ) public view override onlyVault returns (bool, uint256) {
        address user = IRouterCommon(params.router).getSender();

        uint256 swapFeePercentWithLoyaltyDiscount = _isLoyaltyDiscountEnabled
            ? getSwapFeeWithLoyaltyDiscount(user, staticSwapFeePercentage)
            : staticSwapFeePercentage;

        console.log("(onComputeDynamicSwapFeePercentage) swapFeePercentWithLoyaltyDiscount", swapFeePercentWithLoyaltyDiscount);

        uint256 volatilityFeePercent = _isVolatilityFeeEnabled ? getVolatilityFeePercent() : 0;

        console.log("(onComputeDynamicSwapFeePercentage) volatilityFee", volatilityFeePercent);

        uint256 totalSwapFeePercent = swapFeePercentWithLoyaltyDiscount + volatilityFeePercent;

        console.log("(onComputeDynamicSwapFeePercentage) totalSwapFeePercent", totalSwapFeePercent);

        return (true, totalSwapFeePercent);
    }

    // --------------------------------------------------------------------
    // ------------------- External Functions -----------------------------
    // --------------------------------------------------------------------

    // this function only serves the demo, should not be there in production, variable fee cap should be set only once in constructor
    function setVariableFeeCap(uint256 variableFeeCap) public {
        _variableFeeCap = variableFeeCap;
    }

    function changeLoyaltyDiscountSetting() public {
        _isLoyaltyDiscountEnabled = !_isLoyaltyDiscountEnabled;
    }

    function changeVolatilityFeeSetting() public {
        _isVolatilityFeeEnabled = !_isVolatilityFeeEnabled;
    }

    // --------------------------------------------------------------------
    // ------------------------ internal functions ------------------------
    // --------------------------------------------------------------------

    function getSwapFeeWithLoyaltyDiscount(
        address user,
        uint256 staticSwapFeePercentage
    ) public view returns (uint256) {
        uint256 loyaltyIndex = getCurrentLoyaltyIndex(userLoyaltyData[user]);
        bool isStaticFeeGreaterThanLoyaltyFeeCap = staticSwapFeePercentage > 0.01e18;

        uint256 fixedFee = staticSwapFeePercentage;
        uint256 loyaltyFee = 0;
        uint256 variableFee = 0;

        uint256 loyaltyDiscount = getLoyaltyDiscount(uint256(loyaltyIndex));
        console.log(
            "(getSwapFeeWithLoyaltyDiscount) loyaltyIndex, loyaltyDiscount",
            uint256(loyaltyIndex),
            loyaltyDiscount
        );

        // idea is to first apply a flat fee of 1%, over and above that apply any loyalty discount but have a limit on it
        // fixedFee will be minimum 1%, anything extra goes into loyalty fee unless it reaches the cap of _LOYALTY_FEE_CAP, anything above goes into variable fee
        // so if staticSwapFeePercentage = 5 and _LOYALTY_FEE_CAP = 2, then fixedFee = 1%, loyaltyFee = 2% and variableFee = 3%, loyalty discount will be applied only on the 2% loyalty fee
        // so maximum loyalty discount anyone can achieve is 2%, at the same time no one is paying less than 1%, maybe more (in this case, 1 + 3 = 4%)

        if (isStaticFeeGreaterThanLoyaltyFeeCap) {
            fixedFee = 0.01e18; // 1% will be applied
            variableFee = staticSwapFeePercentage > fixedFee + _LOYALTY_FEE_CAP
                ? staticSwapFeePercentage - (fixedFee + _LOYALTY_FEE_CAP)
                : 0;

            loyaltyFee =
                ((staticSwapFeePercentage - (fixedFee + variableFee)) * (FixedPoint.ONE - loyaltyDiscount)) /
                FixedPoint.ONE;
        }

        uint256 totalFee = fixedFee + loyaltyFee + variableFee;

        console.log(
            "(getSwapFeeWithLoyaltyDiscount) fixedFee + loyaltyFee + variableFee",
            fixedFee,
            loyaltyFee,
            variableFee
        );

        console.log("(getSwapFeeWithLoyaltyDiscount) totalFee", totalFee);

        return totalFee;
    }

    function getAllTokenConfigs(address contractAddress) internal returns (address[] memory) {
        bytes memory data = abi.encodeWithSignature("tokenConfigs()");
        (bool success, bytes memory result) = contractAddress.call(data);
        require(success, "tokenConfigs call failed"); // change into revert
        address[] memory tokenAddresses = abi.decode(result, (address[]));
        console.log("tokenAddresses.length", tokenAddresses.length);

        return tokenAddresses;
    }

    function getCurrentLoyaltyIndex(LoyaltyData memory loyaltyData) public view returns (uint256) {
        uint256 currentTimestamp = block.timestamp;
        uint256 oldFirstTransactionTimestamp = loyaltyData.firstTransactionTimestamp;
        bool isLoyaltyWindowRefreshed = (currentTimestamp - oldFirstTransactionTimestamp) >= _LOYALTY_REFRESH_WINDOW;
        uint256 oldTimestamp = loyaltyData.lastTimestamp;
        uint256 oldCumulativeLoyalty = isLoyaltyWindowRefreshed ? 0 : loyaltyData.cumulativeLoyalty;
        uint256 oldTokens = isLoyaltyWindowRefreshed ? 0 : loyaltyData.tokens;
        uint256 newCumulativeLoyalty = oldCumulativeLoyalty + (oldTokens * (currentTimestamp - oldTimestamp));

        return newCumulativeLoyalty;
    }

    // a rough estimation of tiers
    // the thought behind the tiers is that how many tokens were bought at the beginning of the _LOYALTY_REFRESH_WINDOW and held till the end of the window
    // so 1000 tokens are minted initially and can be bought and held for _LOYALTY_REFRESH_WINDOW days, so max loyalty index is 1000 * _LOYALTY_REFRESH_WINDOW
    // so tier it in a way so that if someone has generated loyaltyIndex equivalent to buying at least 1% tokens and held it for the entire _LOYALTY_REFRESH_WINDOW  duration gets full discount
    function getLoyaltyDiscount(uint256 loyaltyIndex) public pure returns (uint256) {
        if (loyaltyIndex > 0 && loyaltyIndex <= 2 * _LOYALTY_REFRESH_WINDOW * FixedPoint.ONE) {
            return 0.1e18; // 10% discount
        } else if (
            loyaltyIndex > 2 * _LOYALTY_REFRESH_WINDOW * FixedPoint.ONE &&
            loyaltyIndex <= 5 * _LOYALTY_REFRESH_WINDOW * FixedPoint.ONE
        ) {
            return 0.3e18; // 30% discount
        } else if (
            loyaltyIndex > 5 * _LOYALTY_REFRESH_WINDOW * FixedPoint.ONE &&
            loyaltyIndex <= 10 * _LOYALTY_REFRESH_WINDOW * FixedPoint.ONE
        ) {
            return 0.5e18; // 50% discount
        } else if (loyaltyIndex > 10 * _LOYALTY_REFRESH_WINDOW * FixedPoint.ONE) {
            return 1e18; // 100% discount -> does not mean there won't be any fee, refer to onComputeDynamicSwapFeePercentage
        } else {
            return 0; // Default return value if loyaltyIndex does not fit any of the above conditions
        }
    }

    function getVolatilityFeePercent() public view returns (uint256) {
        VolatilityOracle volatilityOracle = VolatilityOracle(_oracleAddress);
        uint256 volatility = volatilityOracle.getVolatility(_VOLATILITY_WINDOW);
        console.log("(getVolatilityFee) volatility", volatility);
        uint256 volatilityFeePercent = getVolatilityFeePercentOnCap(volatility);
        console.log("(getVolatilityFee) volatilityFeePercent", volatilityFeePercent);
        uint256 volatilityFee = (_VOLATILITY_FEE_CAP * (volatilityFeePercent)) / FixedPoint.ONE;
        console.log("(getVolatilityFee) volatilityFee", volatilityFee);
        return volatilityFee;
    }

    // volatility -> percent change per second
    function getVolatilityFeePercentOnCap(uint256 volatility) public pure returns (uint256) {
        if (volatility > 0 && volatility <= 0.0001e18) { // less than 0.01 %/second
            return 0; // no fee
        } else if (volatility > 0.001e18 && volatility <= 0.005e18) { // less than 0.05 %/second
            return 0.1e18; // 10% of max fee
        } else if (volatility > 0.005e18 && volatility <= 0.015e18) { // less than 0.15 %/second
            return 0.2e18; // 20% of max fee
        } else if (volatility > 0.015e18 && volatility <= 0.02e18) { // less than 0.2 %/second
            return 0.3e18; // 30% of max fee
        } else if (volatility > 0.02e18 && volatility <= 0.05e18) { // less than 0.5 %/second
            return 0.5e18; // 50% of max fee
        } else if (volatility > 0.05e18 && volatility <= 0.1e18) { // less than 1 %/second
            return 0.7e18; // 70% of max fee
        } else if (volatility > 0.1e18 && volatility <= 0.2e18) { // less than 2 %/second
            return 0.9e18; // 90% of max fee
        } else if (volatility > 0.2e18) { // greater than 2%/second
            return 1e18; // 100% of max fee
        } else {
            return 0; // no fee
        }
    }
}
