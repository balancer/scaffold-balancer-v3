// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AddLiquidityKind,
    AddLiquidityParams,
    LiquidityManagement,
    RemoveLiquidityKind,
    TokenConfig,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";

import { PredictionMarketLib } from './lib/PredictionMarketLib.sol';
import { PredictionMarketStorage } from './lib/PredictionMarketStorage.sol';
import { PositionStorage } from './lib/PositionStorage.sol';
import { 
    PredictionMarket,
    Position,
    Side 
} from './Types.sol';

import {console} from "forge-std/console.sol";

/**
 * @notice Host prediction markets using balancer pools as price oracles. Fees collected from the markets are distributed to LPs
 * @dev  This hook creates asset price prediction markets on top of balancer pools. Participants are charged
 * fees on entry and when they make modifications to their positions. Fees are donated back to pool (effectively increasing the value
 * of BPT shares for all users).
 *
 * Since the only way to deposit fee tokens back into the pool balance (without minting new BPT) is through
 * the special "donation" add liquidity type, this hook also requires that the pool support donation.
 */
contract PredictionMarketHook is BaseHooks, VaultGuard, Ownable {
    using SafeCast for uint256;
    using FixedPoint for uint256;
    using SafeERC20 for IERC20;
    using PredictionMarketLib for PredictionMarket;
    using PredictionMarketStorage for mapping(bytes32 => PredictionMarket);
    using PositionStorage for mapping(bytes32 => mapping(address => Position));

    /// @notice fee charged by hook to prediction market participants
    uint256 public constant FEE = 10000; // 1%

    /// @notice waiting period after a swap occurs in a pool and when a market can be settled
    uint256 public constant SETTLEMENT_WAITING_PERIOD = 10;

    /**
     * @notice  The factory allowed to create pools with the PredictionMarketHook
     * @dev Hook registration will fail if the pool is not created from the factory
     */ 
    address public immutable factory;
    
    /**
     * @notice Mapping between prediction market id and the corresponding markets
     * @dev mapping(marketId => PredictionMarket)
     * marketId = keccak256(abi.encodePacked(pool, [sorted token0], [sorted token1], closedAtTimestamp));
     */
    mapping(bytes32 => PredictionMarket) public markets;

    /**
     * @notice Mapping of user positions to corresponding markets
     * @dev mapping(marketId => mapping(userAddress => Position))
     */
    mapping(bytes32 => mapping(address => Position)) public positions;

    /// @notice Lookup of pools registered with the hook
    mapping(address => bool) private _isPoolRegistered;
    
    /**
     * @notice Lookup of the last swap block by pool
     * @dev Market settlement will fail if the last pool swap was done within the configured SETTLEMENT_WAITING_PERIOD.
     * This is to mitigate price manipulation possibilities by allowing arbitrage to bring the pool back into balance
     * if it has been brought out of balance by a malicious actor
     */ 
    mapping(address => uint256) private _lastSwapBlockByPool;
    

    /**
     * @notice A new `PredictionMarketHook` contract has been registered successfully for a given factory and pool.
     * @dev If the registration fails the call will revert, so there will be no event.
     * @param hooksContract This contract
     * @param pool The pool on which the hook was registered
     */
    event PredictionMarketHookRegistered(address indexed hooksContract, address indexed pool);

    /// @notice The pool does not support adding liquidity through donation.
    error PoolDoesNotSupportDonation();

    /// @notice The pool is not registered with the hook
    error PoolNotFound();

    /// @notice The pool token pair does not exist
    error InvalidTokenPair();

    /// @notice Time provided timestamp is in the past
    error TimestampIsInPast();

    /// @notice Market is not initalized and cannot be closed
    error MarketIsNotInitalized();

    /// @notice Market is still active and cannot be closed
    error MarketIsActive();

    /// @notice Settlement cannot occur too soon after the last pool swap
    error SettlementTooSoonAfterSwap();

    
 
    constructor(
        IVault vault,
        address allowedFactory
    ) VaultGuard(vault) Ownable(msg.sender) {
        factory = allowedFactory;
    }

    /// @inheritdoc IHooks
    function onRegister(
        address poolFactory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata liquidityManagement
    ) public override onlyVault returns (bool) {
        // This hook requires donation support to work. Fees collected from prediction markets are donated back to LPs
        if (liquidityManagement.enableDonation == false) {
            revert PoolDoesNotSupportDonation();
        }

        _isPoolRegistered[pool] = true;

        emit PredictionMarketHookRegistered(address(this), pool);

        return poolFactory == factory  && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory) {
        HookFlags memory hookFlags;

        hookFlags.shouldCallBeforeSwap = true;
        hookFlags.shouldCallAfterSwap = true;
        hookFlags.shouldCallComputeDynamicSwapFee = true;
        
        return hookFlags;
    }

    // Prediction Market Methods    

    /**
     * @notice Get the market id from the given market params
     * @dev Useful for external callers
     *
     * @param pool Pool hosting the prediction market
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @param closedAtTimestamp Timestamp for when the market closes
     * @return marketId hashed market id
     */
    function getMarketId(
        address pool,
        address tokenA,
        address tokenB,
        uint256 closedAtTimestamp
    ) public pure returns (bytes32 marketId) {
        return PredictionMarketStorage.getMarketId(pool, tokenA, tokenB, closedAtTimestamp);
    }

    /**
     * @notice Get a market given it's id
     * @param id The market id
     * @return market The resolved prediction market
     */
    function getMarketById(
        bytes32 id
    ) public view returns (PredictionMarket memory) {
        return markets[id];
    }

    /**
     * @notice Add liquidity to a given prediction market
     * @dev The deposit token taken from the user balance will be the token0 of the given market, which is the 
     * first token in the sorted pair
     *
     * User positions will be credited based on the current balance of "bets" between bull/bear outcomes. If the 
     * market is uninitalized then the user will receive equal amounts of bull/bear units, representing a 50/50 
     * probability of each outcome.
     *
     * The total value of a market at any given time is equal of the deposited liquidity. This is the amount that 
     * will be split between the assets when the market is settled. For example, a market with 100 USDC deposited 
     * and a 80/20 balance split between bull / bear would imply a bull price/probability of ($.8) and a bear 
     * price/probability of ($.2). If this ratio continued to settlement then each bull unit would be worth $1.25 
     * while each bear unit is worth $0
     *
     * One can think of this style of prediction market as an implementation of on-chain binary options 
     *
     * @param pool Pool hosting the prediction market
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @param closedAtTimestamp Timestamp for when the market closes
     * @param amount Deposit amount
     * @param side Side to add liquidity to, optionally choose both to add proportionally
     * @return position Resulting user liquidity position after deposit
     */
    function addLiquidity(
        address pool,
        address tokenA,
        address tokenB,
        uint256 closedAtTimestamp,
        uint256 amount,
        Side side
    ) public returns (Position memory position) {
        // only create prediction markets for pools registered with the hook
        if(!_isPoolRegistered[pool]) {
            revert PoolNotFound();
        }

        // do not addLiquidity or create new markets when the closed timestamp is in the past
        if(closedAtTimestamp <= block.timestamp) {
            revert TimestampIsInPast();
        }

        // prediction markets cannot be priced when tokens in the pair are equal or the pool does not contain the requested
        // tokens. Revert if ether case is true
        if(!_canCreateMarketFromPoolAndTokens(pool, tokenA, tokenB)){
            revert InvalidTokenPair();
        }
        
        // transfer deposit funds from the user account to the hook contract. The user position will be updated for bull 
        // and bear units corresponding to the current market prices after fees. 
        IERC20(market.token0).safeTransferFrom(msg.sender, address(this), amount);

        // add liquidity to the corresponding prediction market to the user request. If one is not found, one will be created
        (uint256 bullAmount, uint256 bearAmount) = markets.addLiquidity(pool, tokenA, tokenB, closedAtTimestamp, _vault, side, amount, FEE);

        // Apply user position deltas and store the updated market. Add liquidity deltas are always positive uint256, so we 
        // need to convert them to int256() prior to calling applyPositionDelta(int256, int256).
        Position memory updatedPosition = positions.applyPositionDelta(market.id, msg.sender, bullAmount.toInt256(), bearAmount.toInt256());

        return updatedPosition;
    }

    /**
     * @notice settle the given market
     * @dev after markets are settled, participants can claim their payouts
     *
     * market must be past their end time into order to be claimed
     * @param marketId the market to settle
     * @return market the settled prediction market
     *
     */
    function settle(bytes32 marketId) public returns (PredictionMarket memory market) {
        address pool = markets[marketId].pool;
        uint256 lastSwapBlock = _lastSwapBlockByPool[pool];

        PredictionMarket memory settledMarket = markets.settle(marketId, lastSwapBlock, SETTLEMENT_WAITING_PERIOD);

        _donate(settledMarket.pool, settledMarket.fees, settledMarket.token0);

        return settledMarket;
    }

    /**
     * @notice claim payouts from a settled market
     * @dev the market must be settled in order to claim AND the sender must have a winning final position
     * @param marketId the market to claim winnings from
     * @return winnings the amount claimed to the msg.sender
     */
    function collect(bytes32 marketId) public returns (uint256 winnings){
        PredictionMarket memory market = markets[id];

        if(!market.settled){
            settle(marketId);
        }

        uint256 userClaimAmount = positions.claim(market);

        SafeERC20(market.token0).transfer(msg.sender, userClaimAmount);

        return userClaimAmount;
    }

    /**
     * @notice swap a position holdings between sides 
     * @dev bull -> bear or bear -> bull
     *
     * Fees are charged for each swap and maintained on the market for processing during settlement
     * @param marketId Identifier of the market to swap
     * @param from Side to swap from
     * @param amountIn Amount to swap
     * @return position Updated user position after the swap
     */
    function swap(
        bytes32 marketId,
        Side from,
        uint245 amountIn
    ) public returns (Position memory position) {
        // get output amount from the market and prepare amount deltas
        uint256 amountOut = markets.swap(marketId, from, amountIn, FEE);

        int256 amountInDelta = amountIn.toInt256()*-1;
        int256 amountOutdelta = amountOut.toInt256();

        (int256 bullAmountDelta, int256 bearAmountDelta) = from == Side.Bull ? 
            (amountInDelta, amountOutdelta) :
            (amountOutdelta, amountInDelta)

        // update the position with the amount deltas
        Position memory updatedPosition = positions.applyPositionDelta(marketId, msg.sender, bullAmountDelta, bearAmountDelta);

        return updatedPosition;
    }

    /**
     * @notice Determines whether a given pool and token combination is valid
     * @dev pool must contain both tokens in the pair to be valid. Otherwise we will not be able to price markets and 
     * determine outcomes
     * @param pool Pool hosting the prediction market
     * @param tokenA First token in the pair
     * @param tokenB Second token in the pair
     * @return canCreateMarket True if the market can be created from the given pool and token
     */
    function _canCreateMarketFromPoolAndTokens(
        address pool,
        address tokenA,
        address tokenB
    ) private view returns (bool canCreateMarket) {
        // cannot create markets with the same token
        if(tokenA == tokenB) {
            return false;
        }

        // get the pool tokens from the vault and return true if both tokens in the pair are contained in the pool
        IERC20[] memory tokens = _vault.getPoolTokens(pool);
        bool hasTokenA;
        bool hasTokenB;

        for(uint256 i=0; i<tokens.length;++i){
            address token = address(tokens[i]);

            if(token == tokenA){
                hasTokenA = true;
            }

            if(token == tokenB) {
                hasTokenB = true;
            }
        }

        return hasTokenA && hasTokenB;
    }

    /**
     * @notice Dontate fees back to pool LPs
     * @param pool Pool to donate fees to
     * @param token Fee denomination token
     * @param amount Amount to donate
     */
    function _donate(
        address pool,
        address token,
        uint256 amount
    ) private {
        IERC20[] memory tokens = _vault.getPoolTokens(pool);
        uint256[] memory feeAmounts = new uint256[](tokens.length);

        for(uint256 i=0; i<tokens.length;i++){
            feeAmounts[i] = address(tokens[i]) == token ? amount : 0;
        }

        // Donates accrued fees back to LPs
        _vault.addLiquidity(
            AddLiquidityParams({
                pool: pool,
                to: address(this), // It would mint BPTs to hook, but it's a donation so no BPT is minted
                maxAmountsIn: feeAmounts, // Donate all accrued fees back to the pool (i.e. to the LPs)
                minBptAmountOut: 0, // Donation does not return BPTs, any number above 0 will revert
                kind: AddLiquidityKind.DONATION,
                userData: bytes("") // User data is not used by donation, so we can set it to an empty string
            })
        );
    }

    


}