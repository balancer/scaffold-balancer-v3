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

import "forge-std/console.sol";

// only for 2 token pools
contract VolatilityBasedSwapFeeHook is BaseHooks, VaultGuard {
    using FixedPoint for uint256;
    uint256 internal constant ONE = 1e18; // 18 decimal places

    address public tokenAddress; // making public for debugging purposes only
    address public factoryAddress;
    uint256 public variableFeeCap; // making public for debugging purposes only

    struct PriceData {
        uint256 epochTimestamp;
        uint256 tokenPrice; // multiplied by 1e18
    }

    struct VolatilityStdDev {
        uint256 volatility;
        uint256 netTokenBought;
        uint256 dataLength;
    }

    PriceData[] public priceDataArray; // should not be stored on chain on production, should be indexed and stored in the something like moralis or theGraph

    VolatilityStdDev[24] public last24HourPriceDataRingBuffer; // aggregated data -> 24 entries for every hour
    VolatilityStdDev[12] public last1HourPriceDataRingBuffer; // aggregated data - > 12 entries for every 5 minute interval
    PriceData[24] public prev5MinPriceDataArray;
    PriceData[12] public curr5MinPriceDataArray;

    // add checks :
    // only 2 token pools
    // froma registered factory
    constructor(IVault vault, address _tokenAddress, uint256 _variableFeeCap) VaultGuard(vault) {
        tokenAddress = _tokenAddress;
        variableFeeCap = _variableFeeCap;
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
        hookFlags.shouldCallComputeDynamicSwapFee = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
        hookFlags.shouldCallAfterAddLiquidity = true;
        return hookFlags;
    }

    function onAfterRemoveLiquidity(
        address,
        address,
        RemoveLiquidityKind,
        uint256,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory balancesScaled18,
        bytes memory
    ) public override returns (bool, uint256[] memory) {
        console.log("(onAfterRemoveLiquidity) executed now");
        address[] memory tokenAddresses = getAllTokenConfigs(factoryAddress); // -> need to do this cuz we do not know that what index points to what token address
        uint256 tokenPrice;

        if (tokenAddresses[0] == tokenAddress) {
            tokenPrice = balancesScaled18[1].divUp(balancesScaled18[0]);
            // emit event
        } else if (tokenAddresses[1] == tokenAddress) {
            tokenPrice = balancesScaled18[0].divUp(balancesScaled18[1]);
            // emit event
        } else {
            // revert with error
        }

        console.log(
            "(onAfterRemoveLiquidity) balancesScaled18[0], balancesScaled18[1], tokenPrice",
            balancesScaled18[0],
            balancesScaled18[1],
            tokenPrice
        );

        priceDataArray.push(PriceData(block.timestamp, tokenPrice));
    }

    function onAfterAddLiquidity(
        address,
        address,
        AddLiquidityKind,
        uint256[] memory,
        uint256[] memory,
        uint256,
        uint256[] memory balancesScaled18,
        bytes memory
    ) public override returns (bool, uint256[] memory) {
        console.log("(onAfterAddLiquidity) executed now");
        address[] memory tokenAddresses = getAllTokenConfigs(factoryAddress); // -> need to do this cuz we do not know that what index points to what token address
        uint256 tokenPrice;

        if (tokenAddresses[0] == tokenAddress) {
            tokenPrice = balancesScaled18[1].divUp(balancesScaled18[0]);
            // emit event
        } else if (tokenAddresses[1] == tokenAddress) {
            tokenPrice = balancesScaled18[0].divUp(balancesScaled18[1]);
            // emit event
        } else {
            // revert with error
        }

        console.log(
            "(onAfterAddLiquidity) balancesScaled18[0], balancesScaled18[1], tokenPrice",
            balancesScaled18[0],
            balancesScaled18[1],
            tokenPrice
        );

        priceDataArray.push(PriceData(block.timestamp, tokenPrice));
    }

    function onAfterSwap(AfterSwapParams calldata params) public override returns (bool, uint256) {
        console.log("(onAfterSwap) executed now");
        uint256 tokenPrice;
        if (address(params.tokenIn) == tokenAddress) {
            tokenPrice = params.tokenOutBalanceScaled18.divUp(params.tokenInBalanceScaled18);
            // emit event
        } else if (address(params.tokenOut) == tokenAddress) {
            tokenPrice = params.tokenInBalanceScaled18.divUp(params.tokenOutBalanceScaled18);
            // emit event
        } else {
            // revert with error
        }

        console.log(
            "(onAfterSwap) params.tokenOutBalanceScaled18, params.tokenInBalanceScaled18, tokenPrice",
            params.tokenOutBalanceScaled18,
            params.tokenInBalanceScaled18,
            tokenPrice
        );

        priceDataArray.push(PriceData(block.timestamp, tokenPrice));

        return (true, 1e18);
    }

    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address,
        uint256 staticSwapFeePercentage
    ) public view override onlyVault returns (bool, uint256) {
        console.log("(onComputeDynamicSwapFeePercentage) executed now");
        // swap fee = C + UL × ( 1 − e^−volatility × ( 1 − e^−tokens ))
        uint256 e = 2; // approximating the euler's number (2.71) to be 2, treat this as a hyperparameter that should be tuned instead of a constant
        uint256 tokenBalanceOfUser = getTokenBalanceOfUser(params);
        uint256 totalSupplyOfToken = IERC20(tokenAddress).totalSupply();
        uint256 proportionOfTokenPossession = tokenBalanceOfUser.divUp(totalSupplyOfToken);
        uint256 volatility = getCurrentVolatilityOverUnitTime();
        uint256 fixedFee = staticSwapFeePercentage;
        uint256 scaleUpAndDownBy = ONE; // anything above 1000 will give a decent answer
        uint256 ePowUp = e ** (volatility);
        uint256 variableFeeVolatility = (variableFeeCap * (scaleUpAndDownBy - scaleUpAndDownBy / ePowUp)) /
            scaleUpAndDownBy;
        uint256 variableFeeTokenPosession = ((variableFeeVolatility) * (ONE - proportionOfTokenPossession)) / ONE;

        uint256 variableFeeTotal = variableFeeTokenPosession;
        uint256 swapFee = fixedFee + variableFeeTotal;

        console.log(
            "(onComputeDynamicSwapFeePercentage) tokenBalanceOfUser, totalSupplyOfToken, proportionOfTokenPossession ",
            tokenBalanceOfUser,
            totalSupplyOfToken,
            proportionOfTokenPossession
        );
        console.log(
            "(onComputeDynamicSwapFeePercentage) volatility, fixedFee, scaleUpAndDownBy ",
            volatility,
            fixedFee,
            scaleUpAndDownBy
        );
        console.log(
            "(onComputeDynamicSwapFeePercentage) variableFeeVolatility, variableFeeTokenPosession, variableFeeTotal ",
            variableFeeVolatility,
            variableFeeTokenPosession,
            variableFeeTotal
        );
        console.log("(onComputeDynamicSwapFeePercentage) swapFee ", swapFee);

        return (true, swapFee);
    }

    // --------------------------------------------------------------------
    // ------------------- External Functions -----------------------------
    // --------------------------------------------------------------------

    // this function only serves the demo, should not be there in production, variable fee cap should be set only once in constructor
    function setVariableFeeCap(uint256 _variableFeeCap) public {
        variableFeeCap = _variableFeeCap;
    }

    function getCurrentVolatilityOverUnitTime() public view returns (uint256) {
        if (priceDataArray.length < 2) {
            return 0;
        }
        uint256 timeDifference = 1;

        uint256 priceDifference = absDifference(
            priceDataArray[priceDataArray.length - 1].tokenPrice,
            priceDataArray[priceDataArray.length - 2].tokenPrice
        );
        console.log(
            "(getCurrentVolatilityOverUnitTime) priceDataArray[priceDataArray.length - 1].tokenPrice ",
            priceDataArray[priceDataArray.length - 1].tokenPrice
        );
        uint256 volatility = (priceDifference / timeDifference) / ONE;
        console.log("(getCurrentVolatilityOverUnitTime) volatility", volatility);
        return volatility;
    }

    function getPriceDataArrayLength() public view returns (uint256) {
        return priceDataArray.length;
    }

    function getTokenBalanceOfUser(PoolSwapParams calldata params) public view returns (uint256 tokenBal) {
        address user = IRouterCommon(params.router).getSender();
        IERC20 token = IERC20(tokenAddress);
        tokenBal = token.balanceOf(user);

        return tokenBal;
    }

    // time-weighted standard deviation for volatility
    function getPrevious5MinutesVolatility() public view returns (uint256 volatility) {
        PriceData[] memory priceDataSeries = new PriceData[](
            prev5MinPriceDataArray.length + curr5MinPriceDataArray.length
        );
        for (uint256 i = 0; i < prev5MinPriceDataArray.length; i++) {
            priceDataSeries[i] = prev5MinPriceDataArray[i];
        }
        for (uint256 i = 0; i < curr5MinPriceDataArray.length; i++) {
            priceDataSeries[prev5MinPriceDataArray.length + i] = curr5MinPriceDataArray[i];
        }
        uint256 lastMinute = block.timestamp - (block.timestamp % 60);
        uint256 indexToRemove = 0;
        while (indexToRemove < priceDataSeries.length && priceDataSeries[indexToRemove].epochTimestamp < lastMinute) {
            indexToRemove++;
        }
        PriceData[] memory filteredPriceDataSeries = new PriceData[](priceDataSeries.length - indexToRemove);
        for (uint256 i = indexToRemove; i < priceDataSeries.length; i++) {
            filteredPriceDataSeries[i - indexToRemove] = priceDataSeries[i];
        }
        priceDataSeries = filteredPriceDataSeries;
        uint256 sum = 0;
        for (uint256 i = 1; i < priceDataSeries.length; i++) {
            uint256 priceChange = priceDataSeries[i].tokenPrice - priceDataSeries[i - 1].tokenPrice;
            uint256 timeInterval = priceDataSeries[i].epochTimestamp - priceDataSeries[i - 1].epochTimestamp;
            uint256 meanPrice = (priceDataSeries[i].tokenPrice + priceDataSeries[i - 1].tokenPrice) / 2;
            uint256 fractionalReturn = (priceChange * priceChange) / meanPrice;
            sum += fractionalReturn * timeInterval;
        }
        volatility = customSqrt(sum / 5); // span the dispersion over 5 minutes
        return volatility;
    }

    function getPreviousHourVolatility() public pure returns (uint256 volatility) {
        
    }

    // --------------------------------------------------------------------
    // ------------------------ internal functions ------------------------
    // --------------------------------------------------------------------

    function absDifference(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? (a - b) : (b - a);
    }

    function standardDeviation(uint256[] memory dataArray) internal pure returns (uint256) {
        uint256 sum = 0;
        uint256 mean = 0;
        uint256[] memory squaredDifferences = new uint256[](dataArray.length);

        for (uint256 i = 0; i < dataArray.length; i++) {
            sum += dataArray[i];
        }

        mean = sum / dataArray.length;

        for (uint256 i = 0; i < dataArray.length; i++) {
            squaredDifferences[i] = (dataArray[i] - mean) * (dataArray[i] - mean);
        }

        sum = 0;

        for (uint256 i = 0; i < squaredDifferences.length; i++) {
            sum += squaredDifferences[i];
        }

        uint256 variance = sum / (squaredDifferences.length - 1);
        uint256 standardDev = customSqrt(variance);

        return standardDev;
    }

    function customSqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function getAllTokenConfigs(address contractAddress) internal returns (address[] memory) {
        bytes memory data = abi.encodeWithSignature("tokenConfigs()");
        (bool success, bytes memory result) = contractAddress.call(data);
        require(success, "tokenConfigs call failed"); // change into revert
        address[] memory tokenAddresses = abi.decode(result, (address[]));
        console.log("tokenAddresses.length", tokenAddresses.length);

        return tokenAddresses;
    }
}
