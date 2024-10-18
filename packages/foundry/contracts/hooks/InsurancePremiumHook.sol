// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AddLiquidityKind,
    LiquidityManagement,
    RemoveLiquidityKind,
    AfterSwapParams,
    SwapKind,
    TokenConfig,
    HookFlags,
    AddLiquidityParams
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { IOutflowProcessor } from "./interfaces/IOutflowProcessor.sol";
import { IPoolImpl } from "./interfaces/IPoolImpl.sol";

/**
 * @notice A hook that takes a fee on add/remove liquidity.
 * @dev This hook extracts fees on all operations liquidity related (add and remove liquidity), adds the fee back as liquidity, then sends
 * the bpt to an atomica pool and the shares of the atomica pool are sent to the user.
 *
 * Since the Vault always takes fees on the calculated amounts, and only supports taking fees in tokens, this hook
 * must be restricted to pools that require proportional liquidity operations. For example, the calculated amount
 * for EXACT_OUT withdrawals would be in BPT, and charging fees on BPT is unsupported.
 *
 * Since the fee must be taken *after* the `amountOut` is calculated - and the actual `amountOut` returned to the Vault
 * must be modified in order to charge the fee - `enableHookAdjustedAmounts` must also be set to true in the
 * pool configuration. Otherwise, the Vault would ignore the adjusted values, and not recognize the fee.
 */
contract InsurancePremiumHook is BaseHooks, VaultGuard, Ownable {
    using FixedPoint for uint256;
    using SafeERC20 for IERC20;
    // Only pools from a specific factory are able to register and use this hook.
    address private immutable _allowedFactory;
    // Only trusted routers are allowed to call this hook, because the hook relies on the `getSender` implementation
    // implementation to work properly.
    address private immutable _trustedRouter;

    //here a struct could be used to enclose all of this variables

    mapping(address => mapping(uint256 => uint256)) public bptPaid;
    mapping(address => mapping(uint256 => uint256)) public timestamp;
    mapping(address => uint256) public depositID;

    /*
    * The outflow processor is an atomica contract that allows withdrawals, this hook is the only authorized approver for withdrawals
    */
    IOutflowProcessor _wrappedOutflow;
    IPoolImpl _wrappedPool;

    // Percentages are represented as 18-decimal FP numbers, which have a maximum value of FixedPoint.ONE (100%),
    // so 60 bits are sufficient.
    uint64 public addLiquidityHookFeePercentage;
    uint64 public removeLiquidityHookFeePercentage;

    /**
     * @notice A new `InsurancePremiumHook` contract has been registered successfully for a given factory and pool.
     * @dev If the registration fails the call will revert, so there will be no event.
     * @param hooksContract This contract
     * @param pool The pool on which the hook was registered
     */
    event InsurancePremiumHookRegistered(address indexed hooksContract, address indexed pool);

    /**
     * @notice The hooks contract has charged a fee.
     * @param btpPaid btp contributed to the premium
     * @param depositID nonce of the deposit
     * @param sender original sender of the transaction
     */
    event HookFeeCharged(uint256 btpPaid, uint256 depositID, address sender);

    /**
     * @notice The add liquidity hook fee percentage has been changed.
     * @dev Note that the initial fee will be zero, and no event is emitted on deployment.
     * @param hooksContract The hooks contract charging the fee
     * @param hookFeePercentage The new hook swap fee percentage
     */
    event HookAddLiquidityFeePercentageChanged(address indexed hooksContract, uint256 hookFeePercentage);

    /**
     * @notice The remove liquidity hook fee percentage has been changed.
     * @dev Note that the initial fee will be zero, and no event is emitted on deployment.
     * @param hooksContract The hooks contract charging the fee
     * @param hookFeePercentage The new hook swap fee percentage
     */
    event HookRemoveLiquidityFeePercentageChanged(address indexed hooksContract, uint256 hookFeePercentage);

    /**
     * @notice The hooks contract owner has withdrawn tokens.
     * @param depositID the id of the deposit
     * @param outflowRequestID_ the ID of the outflow request
     * @param approved a flag indicating if the request has been denied or approved
     * @param amount the amount requested
     * @param timestamp at which the request has taken place
     */
    event ApproveOutflowInsurance(
        uint256 depositID, 
        uint256 outflowRequestID_, 
        bool approved, 
        uint256 amount, 
        uint256 timestamp);

    constructor(
        IVault vault, 
        address allowedFactory, 
        address trustedRouter, 
        address wrappedOutflow, 
        address wrappedPool
        ) VaultGuard(vault) Ownable(msg.sender) {
        require(
        allowedFactory != address(0x0) && 
        trustedRouter != address(0x0) && 
        wrappedOutflow != address(0x0) && 
        wrappedPool != address(0x0),
        "Addresses cannot be 0");
        _allowedFactory = allowedFactory;
        _trustedRouter = trustedRouter;
        _wrappedOutflow = IOutflowProcessor(wrappedOutflow);
        _wrappedPool = IPoolImpl(wrappedPool);
    }

    /// @inheritdoc IHooks
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override onlyVault returns (bool) {
        // This hook implements a restrictive approach, where we check if the factory is an allowed factory and if
        // the pool was created by the allowed factory.

        emit InsurancePremiumHookRegistered(address(this), pool);

        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory) {
        HookFlags memory hookFlags;
        // `enableHookAdjustedAmounts` must be true for all contracts that modify the `amountCalculated`
        // in after hooks. Otherwise, the Vault will ignore any "hookAdjusted" amounts, and the transaction
        // might not settle. (It should be false if the after hooks do something else.)
        hookFlags.enableHookAdjustedAmounts = true;
        hookFlags.shouldCallAfterAddLiquidity = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
        return hookFlags;
    }

    /// @inheritdoc IHooks
    function onAfterAddLiquidity(
        address router,
        address pool,
        AddLiquidityKind kind,
        uint256[] memory,
        uint256[] memory amountsInRaw,
        uint256,
        uint256[] memory,
        bytes memory
    ) public override onlyVault returns (bool success, uint256[] memory hookAdjustedAmountsInRaw) {

        if (router != _trustedRouter) {
            return (false, amountsInRaw);
        }
        
        if (kind != AddLiquidityKind.PROPORTIONAL) {
            // Returning false will make the transaction revert, so the second argument does not matter.
            return (false, amountsInRaw);
        }

        address sender = IRouterCommon(router).getSender();
        hookAdjustedAmountsInRaw = amountsInRaw;

        if (addLiquidityHookFeePercentage > 0) {
            IERC20[] memory tokens = _vault.getPoolTokens(pool);
            uint256[] memory accruedFees = new uint256[](tokens.length);
            // Charge fees proportional to amounts in of each token.
            for (uint256 i = 0; i < amountsInRaw.length; i++) {
                uint256 hookFee = amountsInRaw[i].mulDown(addLiquidityHookFeePercentage);
                accruedFees[i] = hookFee;
                hookAdjustedAmountsInRaw[i] += hookFee;
                _vault.sendTo(tokens[i], address(this), hookFee);
            }
            
            // Sends the hook fee to the hook and registers the debt in the Vault.
            (,uint256 tokensOut,) = _vault.addLiquidity(
                AddLiquidityParams({
                pool: pool,
                to: address(this), 
                maxAmountsIn: accruedFees, 
                minBptAmountOut: 0, 
                kind: AddLiquidityKind.PROPORTIONAL,
                userData: bytes("") 
                })
            );
            
            uint256 shares = _wrappedPool.deposit(tokensOut, sender, 0);
            bptPaid[sender][depositID[sender]] = shares;
            timestamp[sender][depositID[sender]] = block.timestamp;

            emit HookFeeCharged(shares, depositID[sender], sender);
            depositID[sender] += 1;
        }
        return (true, hookAdjustedAmountsInRaw);
    }

    /// @inheritdoc IHooks
    function onAfterRemoveLiquidity(
        address router,
        address pool,
        RemoveLiquidityKind kind,
        uint256 ,
        uint256[] memory,
        uint256[] memory amountsOutRaw,
        uint256[] memory,
        bytes memory
    ) public override onlyVault returns (bool, uint256[] memory hookAdjustedAmountsOutRaw) {
        if (router != _trustedRouter) {
            return (false, amountsOutRaw);
        }
        
        if (kind != RemoveLiquidityKind.PROPORTIONAL) {
            // Returning false will make the transaction revert, so the second argument does not matter.
            return (false, amountsOutRaw);
        }

        address sender = IRouterCommon(router).getSender();
        hookAdjustedAmountsOutRaw = amountsOutRaw;

        if (removeLiquidityHookFeePercentage > 0) {
            IERC20[] memory tokens = _vault.getPoolTokens(pool);
            uint256[] memory accruedFees = new uint256[](tokens.length);
            // Charge fees proportional to amounts in of each token.
            for (uint256 i = 0; i < amountsOutRaw.length; i++) {
                uint256 hookFee = amountsOutRaw[i].mulDown(addLiquidityHookFeePercentage);
                accruedFees[i] = hookFee;
                hookAdjustedAmountsOutRaw[i] -= hookFee;
                _vault.sendTo(tokens[i], address(this), hookFee);
            }
        
            // Sends the hook fee to the hook and registers the debt in the Vault.
            (,uint256 tokensOut,) = _vault.addLiquidity(
                AddLiquidityParams({
                pool: pool,
                to: address(this), 
                maxAmountsIn: accruedFees, 
                minBptAmountOut: 0, 
                kind: AddLiquidityKind.PROPORTIONAL,
                userData: bytes("") 
                })
            );

            uint256 shares = _wrappedPool.deposit(tokensOut, sender, 0);
            bptPaid[sender][depositID[sender]] = shares;
            timestamp[sender][depositID[sender]] = block.timestamp;

            emit HookFeeCharged(shares, depositID[sender], sender);
            depositID[sender] += 1;
            
        }
        return (true, hookAdjustedAmountsOutRaw);
    }

    /**
    * @notice acts as the outflowApprover for the atomica pool
    * @dev this function is used to permissionlessly check if the user's outflow request can be approved
    */
    function approveOutflowInsurance(uint256 depositID_, uint256 outflowRequestID_) external returns(bool approved){
        uint256 requestedAmount = _wrappedOutflow.outflowRequest(outflowRequestID_);

        if(
            requestedAmount == bptPaid[msg.sender][depositID_] && 
            timestamp[msg.sender][depositID_] + 864000 >= block.timestamp
        ){
            _wrappedOutflow.approveOutflowRequest(outflowRequestID_);
            emit ApproveOutflowInsurance(depositID_, outflowRequestID_, true, requestedAmount, block.timestamp);
            return true;
        }

        _wrappedOutflow.declineOutflowRequest(outflowRequestID_);
        emit ApproveOutflowInsurance(depositID_, outflowRequestID_, false, requestedAmount, block.timestamp );
        return false;
    }

    // Permissioned functions

    /**
     * @notice Sets the hook add liquidity fee percentage, charged on every add liquidity operation.
     * @dev This function must be permissioned.
     */
    function setAddLiquidityHookFeePercentage(uint64 hookFeePercentage) external onlyOwner {
        addLiquidityHookFeePercentage = hookFeePercentage;

        emit HookAddLiquidityFeePercentageChanged(address(this), hookFeePercentage);
    }

    /**
     * @notice Sets the hook remove liquidity fee percentage, charged on every remove liquidity operation.
     * @dev This function must be permissioned.
     */
    function setRemoveLiquidityHookFeePercentage(uint64 hookFeePercentage) external onlyOwner {
        removeLiquidityHookFeePercentage = hookFeePercentage;

        emit HookRemoveLiquidityFeePercentageChanged(address(this), hookFeePercentage);
    }
}