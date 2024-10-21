// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IPermit2 } from "permit2/src/interfaces/IPermit2.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";

import { WeightedMath } from "@balancer-labs/v3-solidity-utils/contracts/math/WeightedMath.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { BasePoolMath } from "@balancer-labs/v3-vault/contracts/BasePoolMath.sol";

import { IRouter } from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import {
    IWeightedPool,
    WeightedPoolImmutableData,
    WeightedPoolDynamicData
} from "@balancer-labs/v3-interfaces/contracts/pool-weighted/IWeightedPool.sol";
import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IWETH } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import {
    TokenConfig,
    LiquidityManagement,
    HookFlags,
    AddLiquidityKind,
    RemoveLiquidityKind,
    AddLiquidityParams,
    RemoveLiquidityParams,
    PoolRoleAccounts,
    AfterSwapParams,
    SwapKind,
    PoolSwapParams
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { MinimalRouterWithSwap } from "./MinimalRouterWithSwap.sol";
import { IOracle, TokenData } from "./interfaces/IOracle.sol";

contract ReBalancerHook is Ownable, MinimalRouterWithSwap, BaseHooks {
    using FixedPoint for uint256;
    using SafeCast for *;
    using Address for address payable;

    ///@dev price feeds give the data in 1e8 precision
    uint256 constant PRICE_PRECISION = 1e8;

    /**
     *
     * @param minRatio is the min price ration for rebalance required for token this is in 1e18 precision.
     * Thus for 1% change it is 1e16
     * @param rebalanceRequired is the flag that is enabled to indicate rebalancing
     */
    struct RebalanceData {
        uint256 minRatio;
        bool rebalanceRequired;
    }
    ///@dev A map to the address of pool and the rebalancing data for tokens of that pool
    mapping(address => RebalanceData[]) rebalanceData;

    ///@dev I could not find a way to get all the LPs of the pool
    ///@dev I used many variable to cut down the for loops
    mapping(address => address[]) public liquidityProviders;
    mapping(address => mapping(address => uint256[])) public amountTokens;
    mapping(address => mapping(address => bool)) public isStillLp;

    ///@dev This is private as only owner of the hook contract can change the address
    address private weightedPoolFactory;

    ///@dev address of the oracle
    address private oracle;
    /**
     * Emmited when the hook is registered successfully for the given pool
     * @param hooksContract The address of this contract
     * @param pool  The address of the pool that the hook is used for
     */
    event RebalancerHookRegistered(address indexed hooksContract, address indexed pool);

    /**
     * emitted whenever liquidity is added to the pool
     * @param pool address of the pool
     * @param lp the address of liquidity provider
     */
    event LiquidtyProviderAdded(address indexed pool, address indexed lp);

    /**
     * Emmited when the rebalance is triggered for the pool
     * @param pool The address of the pool
     */
    event RebalanceStarted(address indexed pool);

    /**
     * @notice The hook only supports weighted pools
     * @dev The math is written for weighted pools only though it can be extended to other pools
     * but the math will be simpler for CPP or CSP.
     */
    error OnlyWeightedPoolsAllowed();

    /**
     * @notice only pool creator can change rebalancing metrics for pools
     */
    error OnlyCreatorCanChangeRebalanceData(address pool);

    /**
     * @notice The rebalance data is not set for the pool which triggers the rebalancing
     */
    error RebalanceDataNotSet(address pool);

    /**
     * @notice The error given anywhere we encounter dissimilar array lengths
     * @dev The param indicates various places the error has accoured
     * example: "PW_N_PT" is Pool weights do not match pool tokens
     */
    error InvalidArrayLenghts(string message);

    /**
     * @notice Hooks functions called from an external router.
     * @dev This contract inherits both `MinimalRouter` and `BaseHooks`, and functions as is its own router.
     * @param router The address of the Router
     */
    error CannotUseExternalRouter(address router);

    constructor(
        IVault vault,
        IPermit2 permi2,
        IWETH weth,
        address _weightedPoolFactory,
        address _oracle
    ) MinimalRouterWithSwap(vault, weth, permi2) Ownable(msg.sender) {
        weightedPoolFactory = _weightedPoolFactory;
        oracle = _oracle;
    }

    modifier onlySelfRouter(address router) {
        _ensureSelfRouter(router);
        _;
    }
    ///@dev prevent race conditions when rebalancing
    bool private isRebalancing;

    modifier nonReentrantRebalance() {
        require(!isRebalancing, "Rebalance in progress");
        isRebalancing = true;
        _;
        isRebalancing = false;
    }

    /***************************************************************************
                                  Router Functions
    ***************************************************************************/
    function addLiquidityProportional(
        address pool,
        uint256[] memory maxAmountsIn,
        uint256 exactBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender returns (uint256[] memory amountsIn) {
        // Do addLiquidity operation - BPT is minted to this contract.
        amountsIn = _addLiquidityProportional(
            pool,
            msg.sender,
            address(this),
            maxAmountsIn,
            exactBptAmountOut,
            wethIsEth,
            userData
        );
        address[] storage lps = liquidityProviders[pool];
        lps.push(msg.sender);
        uint256[] storage amounts = amountTokens[pool][msg.sender];
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] += amountsIn[i];
        }
        isStillLp[pool][msg.sender] = true;
        emit LiquidtyProviderAdded(pool, msg.sender);
    }

    function removeLiquidityProportional(
        uint256 tokenId,
        address pool,
        uint256 exactBptAmountIn,
        uint256[] memory minAmountsOut,
        bool wethIsEth
    ) external payable saveSender returns (uint256[] memory amountsOut) {
        // Do removeLiquidity operation - tokens sent to msg.sender.
        amountsOut = _removeLiquidityProportional(
            pool,
            msg.sender,
            msg.sender,
            exactBptAmountIn,
            minAmountsOut,
            wethIsEth,
            ""
        );
        uint256[] memory lpBptAmount = amountTokens[pool][msg.sender];

        uint256 length = amountsOut.length;
        for (uint256 i = 0; i < length; i++) {
            lpBptAmount[i] -= amountsOut[i];
        }

        bool hasRemovedAll = true;

        for (uint256 i = 0; i < length; i++) {
            if (lpBptAmount[i] != 0) {
                hasRemovedAll = false;
            }
        }

        isStillLp[pool][msg.sender] = hasRemovedAll;
    }

    /***************************************************************************
                                  Hook Functions
    ***************************************************************************/
    ///@inheritdoc IHooks
    function onRegister(
        address,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override onlyVault returns (bool) {
        ///@dev removing for testing
        // if (!IBasePoolFactory(weightedPoolFactory).isPoolFromFactory(pool)) {
        //     revert OnlyWeightedPoolsAllowed();
        // }

        emit RebalancerHookRegistered(address(this), pool);

        return true;
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory) {
        HookFlags memory hookFlags;
        hookFlags.shouldCallBeforeAddLiquidity = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
        hookFlags.shouldCallComputeDynamicSwapFee = true;
        hookFlags.shouldCallAfterSwap = true;
        return hookFlags;
    }

    /// @inheritdoc BaseHooks
    function onBeforeAddLiquidity(
        address router,
        address,
        AddLiquidityKind,
        uint256[] memory,
        uint256,
        uint256[] memory,
        bytes memory
    ) public view override onlySelfRouter(router) returns (bool) {
        // We only allow addLiquidity via the Router/Hook itself
        return true;
    }

    /// @inheritdoc BaseHooks
    function onAfterRemoveLiquidity(
        address router,
        address pool,
        RemoveLiquidityKind,
        uint256,
        uint256[] memory,
        uint256[] memory amountsOutRaw,
        uint256[] memory,
        bytes memory userData
    ) public override onlySelfRouter(router) returns (bool, uint256[] memory hookAdjustedAmountsOutRaw) {
        return (true, amountsOutRaw);
    }

    /// @inheritdoc IHooks
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public override onlyVault returns (bool success, uint256 hookAdjustedAmountCalculatedRaw) {
        address pool = params.pool;
        if (rebalanceData[pool].length == 0) {
            revert RebalanceDataNotSet(pool);
        }

        (bool rebalanceRequired, uint256[] memory priceActionRatio) = isRebalanceRequired(pool);
        if (rebalanceRequired) {
            emit RebalanceStarted(pool);
            rebalance(pool, priceActionRatio);
        }

        return (true, params.amountCalculatedRaw);
    }

    /// @inheritdoc IHooks
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address pool,
        uint256 staticSwapFeePercentage
    ) public view override onlyVault returns (bool, uint256) {
        // uint256 dynamicFee = IOracle(oracle).getFee(pool);

        return (true, staticSwapFeePercentage);
    }

    /***************************************************************************
                                  Setter Functions
    ***************************************************************************/
    function setWeightedPoolFactoryAddress(address newWeightedPoolFactory) external onlyOwner {
        ///@dev I am a little confused that whether to check if the factory is disable or not would love
        /// reason to check why cause I am thinking the pool can be created from a disabled factory
        /// and still work fine? Let's keep it like this for now while I study about balancer governance
        /// more
        weightedPoolFactory = newWeightedPoolFactory;
    }

    function setRebalanceData(address pool, RebalanceData[] memory _rebalanceData) external {
        PoolRoleAccounts memory roleAccounts = _vault.getPoolRoleAccounts(pool);

        if (msg.sender != roleAccounts.poolCreator) {
            revert OnlyCreatorCanChangeRebalanceData(pool);
        }

        RebalanceData[] storage poolRebalanceData = rebalanceData[pool];

        if (poolRebalanceData.length > 0) {
            delete rebalanceData[pool];
        }

        for (uint256 i = 0; i < _rebalanceData.length; i++) {
            poolRebalanceData.push(_rebalanceData[i]);
        }
    }

    function setOracle(address newOracle) external onlyOwner {
        oracle = newOracle;
    }

    /***************************************************************************
                                  internal Functions
    ***************************************************************************/
    event Debug();

    event tokens(uint256[] tokens);
    function rebalance(address pool, uint256[] memory priceActionRatio) internal {
        RebalanceData[] memory poolRebalanceData = rebalanceData[pool];
        WeightedPoolDynamicData memory poolData = IWeightedPool(pool).getWeightedPoolDynamicData();
        uint256[] memory currentBalances = poolData.balancesLiveScaled18;
        uint256[] memory normalizedWeights = IWeightedPool(pool).getNormalizedWeights();
        emit Debug();
        (uint256[] memory tokenDeltas, bool[] memory remove) = _calculateAmounts(
            poolRebalanceData,
            currentBalances,
            priceActionRatio,
            normalizedWeights
        );
        emit tokens(tokenDeltas);
        _changeLiqudity(pool, tokenDeltas, remove, currentBalances, true);
    }

    function isRebalanceRequired(address pool) internal returns (bool, uint256[] memory) {
        TokenData[] memory tokenData = IOracle(oracle).getPoolTokensData(pool);
        RebalanceData[] storage poolRebalanceData = rebalanceData[pool];
        bool didPriceChange = false;
        uint256[] memory priceActionRatioArr = new uint256[](tokenData.length);
        for (uint i = 0; i < tokenData.length; i++) {
            if (tokenData[i].predictedPrice != 0) {
                uint256 priceActionRatio = (tokenData[i].predictedPrice.mulUp(FixedPoint.ONE)).divUp(
                    tokenData[i].latestRoundPrice
                );
                if (priceActionRatio > poolRebalanceData[i].minRatio) {
                    didPriceChange = true;
                    poolRebalanceData[i].rebalanceRequired = true;
                    priceActionRatioArr[i] = priceActionRatio;
                } else {
                    priceActionRatioArr[i] = FixedPoint.ONE;
                }
            }
        }
        return (didPriceChange, priceActionRatioArr);
    }


    /**
     * @param pool The address of pool
     * @param tokenDeltas The token balance changes
     * @param remove The array whether to remove or add liquidity
     */
    function _changeLiqudity(
        address pool,
        uint256[] memory tokenDeltas,
        bool[] memory remove,
        uint256[] memory currentBalances,
        bool wethIsEth
    ) internal {
        uint256 length = tokenDeltas.length;
        uint256[] memory addTokens = new uint256[](length);
        uint256[] memory removeTokens = new uint256[](length);
        address[] memory activeLiquidityProviders = _getActiveLiquidityProviders(pool);

        ///@dev This is not for production but I take an assumption that every Lp has enough funds to handle
        /// distribute between top 2 for dev
        uint256 numberOfLps = activeLiquidityProviders.length >= 2 ? 2 : activeLiquidityProviders.length;
        /**
         * @dev So here What I do is to use directly the _addLiquidity and _removeLiquidity programs. I spilt the two
         * arrays into the addTokens for which i increase the current tokenbalance and if the token balance decrease
         * I do not change in the addTokens. Thus the result by calling _distributeFunds on the addTokens should leave
         * removeTokens unchanged
         */
        for (uint256 tokenIndex = 0; tokenIndex < length; tokenIndex++) {
            if (tokenDeltas[tokenIndex] > 0) {
                if (remove[tokenIndex]) {
                    removeTokens[tokenIndex] = currentBalances[tokenIndex] - tokenDeltas[tokenIndex];
                    addTokens[tokenIndex] = currentBalances[tokenIndex];
                } else {
                    addTokens[tokenIndex] = currentBalances[tokenIndex] + tokenDeltas[tokenIndex];
                    removeTokens[tokenIndex] = currentBalances[tokenIndex];
                }
            }
        }
        if (numberOfLps == 1) {
            _distributeLiquidity(pool, activeLiquidityProviders[0], addTokens, false, wethIsEth);
            _distributeLiquidity(pool, activeLiquidityProviders[0], removeTokens, true, wethIsEth);
        } else {
            (LPTokens memory lpOneTokens, LPTokens memory lpTwoTokens) = _getTwoLpsTokens(addTokens, removeTokens);
            _distributeLiquidity(pool, activeLiquidityProviders[0], lpOneTokens.addTokens, false, wethIsEth);
            _distributeLiquidity(pool, activeLiquidityProviders[0], lpOneTokens.removeTokens, false, wethIsEth);
            _distributeLiquidity(pool, activeLiquidityProviders[1], lpTwoTokens.addTokens, false, wethIsEth);
            _distributeLiquidity(pool, activeLiquidityProviders[1], lpOneTokens.removeTokens, false, wethIsEth);
        }
    }

    /// @dev The following is a hack as the computaion is toon if I also calculate the exacptBptAmont
    uint256 constant MIN_BPT_AMOUNT_OUT = 0;
    uint256 constant MAX_BPT_AMOUNT_IN = type(uint256).max;

    /**
     * @param pool address of the pool
     * @param liquidityProvider The liquidity Providers for which we have to distribute the liquidity
     * @param tokenAmounts The amount of tokens out / in
     * @param remove The flag to remove or add liquidity for the particular token
     */
    function _distributeLiquidity(
        address pool,
        address liquidityProvider,
        uint256[] memory tokenAmounts,
        bool remove,
        bool wethIsEth
    ) internal {
        if (!remove) {
            (uint256[] memory amountsIn, , ) = _vault.addLiquidity(
                AddLiquidityParams({
                    pool: pool,
                    to: liquidityProvider,
                    maxAmountsIn: tokenAmounts,
                    minBptAmountOut: MIN_BPT_AMOUNT_OUT,
                    kind: AddLiquidityKind.PROPORTIONAL,
                    userData: ""
                })
            );

            // maxAmountsIn length is checked against tokens length at the vault.
            IERC20[] memory tokens = _vault.getPoolTokens(pool);

            for (uint256 i = 0; i < tokens.length; ++i) {
                IERC20 token = tokens[i];
                uint256 amountIn = amountsIn[i];

                // There can be only one WETH token in the pool.
                if (wethIsEth && address(token) == address(_weth)) {
                    if (address(this).balance < amountIn) {
                        revert InsufficientEth();
                    }

                    _weth.deposit{ value: amountIn }();
                    _weth.transfer(address(_vault), amountIn);
                    _vault.settle(_weth, amountIn);
                } else {
                    // Any value over MAX_UINT128 would revert above in `addLiquidity`, so this SafeCast shouldn't be
                    // necessary. Done out of an abundance of caution.
                    _permit2.transferFrom(liquidityProvider, address(_vault), amountIn.toUint160(), address(token));
                    _vault.settle(token, amountIn);
                }
            }

            // Send remaining ETH to the user.
            _returnEth(liquidityProvider);
        } else {
        (,uint256[] memory amountsOut, ) = _vault.removeLiquidity(
            RemoveLiquidityParams({
                pool: pool,
                from: liquidityProvider,
                maxBptAmountIn: MAX_BPT_AMOUNT_IN,
                minAmountsOut: tokenAmounts,
                kind: RemoveLiquidityKind.PROPORTIONAL,
                userData: ""
            })
        );

        // minAmountsOut length is checked against tokens length at the vault.
        IERC20[] memory tokens = _vault.getPoolTokens(pool);

        uint256 ethAmountOut = 0;
        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 amountOut = amountsOut[i];
            IERC20 token = tokens[i];

            // There can be only one WETH token in the pool.
            if (wethIsEth && address(token) == address(_weth)) {
                // Send WETH here and unwrap to native ETH.
                _vault.sendTo(_weth, address(this), amountOut);
                _weth.withdraw(amountOut);
                ethAmountOut = amountOut;
            } else {
                // Transfer the token to the receiver (amountOut).
                _vault.sendTo(token, liquidityProvider, amountOut);
            }
        }

        if (ethAmountOut > 0) {
            // Send ETH to receiver.
            payable(liquidityProvider).sendValue(ethAmountOut);
        }
        }
    }


    /**
     * This function  calculates the newTokenBalances based on the currentTokenBalances and priceRations
     * @param poolRebalanceData The rebalancing config for pool
     * @param currentLiveTokenBalancesScaled18 are the live token balances from
     * @param priceActionRatio The price action is just the ratio of updatePrice/lastPrice the precision is 1e18 so 1% change is 1e16
     * @param normalizedWeights The noramlized weights of toknes
     *
     * @return tokenDeltas Is the delta for token change
     * @return remove this is true if we have to remove the liqudity
     */
    function _calculateAmounts(
        RebalanceData[] memory poolRebalanceData,
        uint256[] memory currentLiveTokenBalancesScaled18,
        uint256[] memory priceActionRatio,
        uint256[] memory normalizedWeights
    ) internal returns (uint256[] memory, bool[] memory) {
        uint256 length = poolRebalanceData.length;
        uint256[] memory tokenDeltas = new uint256[](length);
        bool[] memory remove = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            if (poolRebalanceData[i].rebalanceRequired) {
                uint256 innerProduct = FixedPoint.ONE;
                for (uint256 j = 0; j < length; j++) {
                    uint256 exponent = normalizedWeights[j].divUp(length * FixedPoint.ONE);
                    uint256 power = priceActionRatio[j].powUp(exponent);
                    innerProduct = innerProduct.mulUp(power); // This is in 1e18
                }
                // This is now not in scale
                // As 5e18/e16 => 5e2
                uint256 balanceFactor = currentLiveTokenBalancesScaled18[i].divUp(priceActionRatio[i]);

                // This is again in scale
                uint256 newBalance = balanceFactor.mulUp(innerProduct);
                remove[i] = newBalance < currentLiveTokenBalancesScaled18[i] ? true : false;
                tokenDeltas[i] = _getDiff(newBalance, currentLiveTokenBalancesScaled18[i]);
            } else {
                tokenDeltas[i] = 0;
                remove[i] = false;
            }
        }
        return (tokenDeltas, remove);
    }

    function _ensureSelfRouter(address router) private view {
        if (router != address(this)) {
            revert CannotUseExternalRouter(router);
        }
    }

    ///@dev always get the positive diff
    function _getDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    /**
     * This returns the active lp address
     * @param pool The address of the pool
     * @return The list of active liquidity providers for the pool
     */
    function _getActiveLiquidityProviders(address pool) internal view returns (address[] memory) {
        address[] memory poolLiquidityProviders = liquidityProviders[pool];
        uint256 activeCount = 0;

        // First, count the number of active liquidity providers
        for (uint256 i = 0; i < poolLiquidityProviders.length; i++) {
            if (isStillLp[pool][poolLiquidityProviders[i]]) {
                activeCount++;
            }
        }

        // Initialize the activeLp array with the correct length
        address[] memory activeLp = new address[](activeCount);
        uint256 index = 0;

        // Populate the activeLp array
        for (uint256 i = 0; i < poolLiquidityProviders.length; i++) {
            if (isStillLp[pool][poolLiquidityProviders[i]]) {
                activeLp[index] = poolLiquidityProviders[i];
                index++;
            }
        }

        return activeLp;
    }

    struct LPTokens {
        uint256[] addTokens;
        uint256[] removeTokens;
    }

    function _getTwoLpsTokens(
        uint256[] memory addTokens,
        uint256[] memory removeTokens
    ) internal pure returns (LPTokens memory lp1, LPTokens memory lp2) {
        uint256 length = addTokens.length;
        lp1.addTokens = new uint256[](length);
        lp1.removeTokens = new uint256[](length);
        lp2.addTokens = new uint256[](length);
        lp2.removeTokens = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            lp1.addTokens[i] = addTokens[i] / 2;
            lp1.removeTokens[i] = removeTokens[i] / 2;
            lp2.addTokens[i] = addTokens[i] - lp1.addTokens[i];
            lp2.removeTokens[i] = removeTokens[i] - lp1.removeTokens[i];
        }
    }
}
