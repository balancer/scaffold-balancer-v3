// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { IHooks } from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    HookFlags,
    AfterSwapParams
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";

/**
 * @notice Hook that gives a swap fee discount to lpRWD holders.
 * @dev Uses to reward Liquidity Providers (LPs) based on multiple factors
 */
contract SwapReferralHook is BaseHooks, VaultGuard, Ownable {
    // Only pools from a specific factory are able to register and use this hook.
    address private immutable _allowedFactory;
    // Only trusted routers are allowed to call this hook, because the hook relies on the `getSender` implementation
    // implementation to work properly.
    address private immutable _trustedRouter;

    IVault private immutable vault;

    struct User {
        bool hasSwapped;               // Tracks if the user has swapped before
        string referralCodeUsed;       // Referral code the user used
    }

    struct Referrer {
        uint256 accumulatedDiscount;   // Accumulated discount for referrer, to be redeemed on next swap
    }

    mapping(address => User) public users;         // Tracks all user data
    mapping(string => address) public codeToAddress;  // Maps referral codes to user addresses
    mapping(address => string) public AddressToCode;  // Maps referral user addresses to codes
    mapping(address => Referrer) public referrers;  // Tracks referrer data
    mapping(string => bool) public referralCodeExists; // Ensures unique referral codes
    mapping(address => uint256) private finalSwapFeePercentage; // Used to store the finalSwapFeePercent in before Swap action and reset to zero in after Swap action

    uint256 public userDiscountPercentage = 0.50e18; // User gets 50% discount on swap fee using referral code
    uint256 public referrerDiscountPerUser = 0.20e18;    // Referrer gets 20% discount for each user who uses their referral code

    /**
     * @notice A new `LPIncentivizedHook` contract has been registered successfully.
     * @dev If the registration fails the call will revert, so there will be no event.
     * @param hooksContract This contract
     * @param factory The factory (must be the allowed factory, or the call will revert)
     * @param pool The pool on which the hook was registered
     */
    event SwapReferralHookRegistered(address indexed hooksContract, address indexed factory, address indexed pool);

    /**
     * @dev Referral code is generated successfully.
     * @param user address of user
     * @param referralCode Unique referralcode
     */
    event ReferralCodeGenerated(address indexed user, string referralCode);

    /**
     * @dev Swap Executed successfully.
     * @param user address of user
     * @param swapFee swapfee discount
     * @param userDiscount user discount
     * @param referrerDiscount referrel discount
     */
    event SwapFeeUpdated(address indexed user, uint256 swapFee, uint256 userDiscount, uint256 referrerDiscount);

    /**
     * @dev Referrer Discount Granted successfully.
     * @param referrer address of referrer
     * @param discount swapfee discount
     */
    event ReferrerDiscountGranted(address indexed referrer, uint256 discount);

    constructor(
        IVault _vault,
        address allowedFactory,
        address trustedRouter
    ) VaultGuard(_vault) Ownable(msg.sender) {
        _allowedFactory = allowedFactory;
        _trustedRouter = trustedRouter;
        vault = _vault;
    }

    /// @inheritdoc IHooks
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallComputeDynamicSwapFee = true;
        hookFlags.shouldCallBeforeSwap = true;
        hookFlags.shouldCallAfterSwap  = true;
    }

    /// @inheritdoc IHooks
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override onlyVault returns (bool) {
        // This hook implements a restrictive approach, where we check if the factory is an allowed factory and if
        // the pool was created by the allowed factory. Since we only use onComputeDynamicSwapFeePercentage, this
        // might be an overkill in real applications because the pool math doesn't play a role in the discount
        // calculation.

        emit SwapReferralHookRegistered(address(this), factory, pool);

        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /// @inheritdoc IHooks
    function onBeforeSwap(PoolSwapParams calldata params, address pool) public override onlyVault() returns (bool success) {
        address user = IRouterCommon(params.router).getSender();
        if (params.router != _trustedRouter) {
            finalSwapFeePercentage[user] = 0;
            return (true);
        }
        // Calculating the discount on swap fee
        uint256 _finalSwapFeePercentage = calculateSwapFee(params,user,pool);
        finalSwapFeePercentage[user] = _finalSwapFeePercentage;

        return (true);
    }

    /// @inheritdoc IHooks
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address,
        uint256 staticSwapFeePercentage
    ) public view override onlyVault returns (bool, uint256) {
        // If the router is not trusted, do not apply the veBAL discount. `getSender` may be manipulated by a
        // malicious router.
        if (params.router != _trustedRouter) {
            return (true, staticSwapFeePercentage);
        }

        address user = IRouterCommon(params.router).getSender();
        //get the last calculated discounted swap fee percentage
        uint256 _finalSwapFeePercentage = finalSwapFeePercentage[user];

        if(_finalSwapFeePercentage == 0){
            return (true, staticSwapFeePercentage);
        }
        return (true, _finalSwapFeePercentage);
    }

    /// @inheritdoc IHooks
    function onAfterSwap(
        AfterSwapParams calldata params
    ) public override onlyVault returns (bool success, uint256 hookAdjustedAmountCalculatedRaw) {
        hookAdjustedAmountCalculatedRaw = params.amountCalculatedRaw;

        // If the router is not trusted, do not apply the veBAL discount. `getSender` may be manipulated by a
        // malicious router.
        if (params.router != _trustedRouter) {
            return (true, hookAdjustedAmountCalculatedRaw);
        }
        address user = IRouterCommon(params.router).getSender();
        // Reset the last discounted swapped fee amount
        finalSwapFeePercentage[user] = 0;
        return (true, hookAdjustedAmountCalculatedRaw);
    }

    function calculateSwapFee(PoolSwapParams calldata params, address user, address pool) internal returns (uint256){
        bytes memory userData = params.userData;
        string memory referralCode;
        if(userData.length > 0) {
           referralCode = abi.decode(userData, (string));
        }
        uint256 _staticSwapFeePercentage = vault.getStaticSwapFeePercentage(pool);

        uint256 userDiscount = 0;
        uint256 referrerDiscountToApply = 0;

        // Check if it's the user's first swap
        if (!users[user].hasSwapped) {
            users[user].hasSwapped = true;

            if (bytes(referralCode).length > 0) {
                address referrer = codeToAddress[referralCode];
                require(referrer != address(0), "Invalid referral code");
                require(referrer != user, "Cannot use your own referral code");

                users[user].referralCodeUsed = referralCode;

                // Apply 50% discount for the referred user
                userDiscount = (_staticSwapFeePercentage * userDiscountPercentage) / 1e18;

                // Grant 20% discount to referrer (accumulated for their next swap)
                referrers[referrer].accumulatedDiscount += referrerDiscountPerUser;
                emit ReferrerDiscountGranted(referrer, referrerDiscountPerUser);
            }

            // Generate referral code for the user after their first swap
            string memory newReferralCode = generateReferralCode(user);
        }

        // Handle referrer discount if they have any pending discounts
        referrerDiscountToApply = _applyReferrerDiscount(user, _staticSwapFeePercentage, userDiscount);
        
        // Calculate the final swap fee percentage after applying both discounts
        uint256 finalSwapFeePer = _staticSwapFeePercentage - userDiscount - referrerDiscountToApply;

        // Ensure the final swap fee percentage is not less than 0%
        if (finalSwapFeePer > _staticSwapFeePercentage) {
            finalSwapFeePer = 0;
        }

        // Execute the swap logic (swap fee is now discounted)
        emit SwapFeeUpdated(user, finalSwapFeePer, userDiscount, referrerDiscountToApply);
        return finalSwapFeePer;
    }

    // Function to generate a unique referral code for the user
    function generateReferralCode(address user) internal returns (string memory) {
        string memory newReferralCode;
            
        newReferralCode = _generateCode(user, block.timestamp);

        referralCodeExists[newReferralCode] = true;
        codeToAddress[newReferralCode] = user;
        AddressToCode[user] = newReferralCode;

        emit ReferralCodeGenerated(user, newReferralCode);
        return newReferralCode;
    }

    // Internal function to generate a unique referral code
    function _generateCode(address user, uint256 salt) internal pure returns (string memory) {
        bytes32 hash = keccak256(abi.encodePacked(user, salt));
        return _toAlphanumericString(hash);
    }

    // Convert bytes32 to alphanumeric string
    function _toAlphanumericString(bytes32 _bytes) internal pure returns (string memory) {
        bytes memory ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        bytes memory str = new bytes(10);

        for (uint256 i = 0; i < 10; i++) {
            str[i] = ALPHABET[uint8(_bytes[i]) % ALPHABET.length];
        }

        return string(str);
    }

    // Internal function to apply the referrer's discount and carry over any excess discount
    function _applyReferrerDiscount(address referrer, uint256 staticSwapFeePercentage, uint256 _userDiscount) internal returns (uint256) {
        uint256 referrerDiscount = (referrers[referrer].accumulatedDiscount * staticSwapFeePercentage) / 1e18;
        uint256 discountApplied = 0;

        if (referrerDiscount > 0) {
            uint256 maxDiscount = (staticSwapFeePercentage - _userDiscount); // Cap referrer discount at 100% of the staticSwapFeePercentage

            if (referrerDiscount > maxDiscount) {
                discountApplied = maxDiscount; // Apply up to 100% discount
                referrers[referrer].accumulatedDiscount -= maxDiscount; // Carry over excess discount
            } else {
                discountApplied = referrerDiscount; // Apply full available discount
                referrers[referrer].accumulatedDiscount = 0; // Reset referrer discount
            }
        }

        return discountApplied;
    }

        // Update user discount percentage (e.g., 0.50e18 for 50%)
    function updateUserDiscountPercentage(uint256 newDiscount) external onlyOwner{
        // Only pool owner or admin should have the authority to update
        userDiscountPercentage = newDiscount;
    }

    // Update referrer discount percentage (e.g., 0.20e18 for 20% per user referred)
    function updateReferrerDiscountPerUser(uint256 newDiscount) external onlyOwner{
        // Only pool owner or admin should have the authority to update
        referrerDiscountPerUser = newDiscount;
    }
}
