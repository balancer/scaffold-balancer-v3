// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import { IBasePoolFactory } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import { VaultGuard } from "@balancer-labs/v3-vault/contracts/VaultGuard.sol";
import { BaseHooks } from "@balancer-labs/v3-vault/contracts/BaseHooks.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IOracle} from "../oracle/oracle.sol";

import {
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {Chainlink, ChainlinkClient} from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract CalculateDynamicFeeHook is BaseHooks, VaultGuard, ChainlinkClient, ConfirmedOwner {

    address private immutable _allowedFactory;
    address private immutable _trustedRouter;

    using Chainlink for Chainlink.Request;

    address _ORACLE = 0xD2e4d744c5dECC4Dbb0994bFc220Fe059237A177;
    event EmitDynamicFee (uint256 fee);
    /**
     *  Sepolia
     *@dev LINK address in Sepolia network: 0x779877A7B0D9E8603169DdbD7836e478b4624789
     * @dev Check https://docs.chain.link/docs/link-token-contracts/ for LINK address for the right network
     */

    constructor(IVault vault, address allowedFactory, address trustedRouter) VaultGuard(vault) ConfirmedOwner(msg.sender) {
        _allowedFactory = allowedFactory;
        _trustedRouter = trustedRouter;

        _setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
    }

    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallComputeDynamicSwapFee = true;
    }

    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata 
    ) public view override onlyVault returns (bool) {
        return factory == _allowedFactory && IBasePoolFactory(factory).isPoolFromFactory(pool); 
    }

    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata,
        address,
        uint256 
    ) public view override onlyVault returns (bool, uint256) {
        //gets the dynamic fee from the oracle
        uint256 dynamicFee = IOracle(_ORACLE).getDynamicFee();
        // Only trusted routers are allowed to call this hook.
        require(msg.sender == _trustedRouter, "CalculateDynamicFeeHook: Only trusted routers can call this hook");
        return(true, dynamicFee);
    }
}