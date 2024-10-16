// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { GovernedLotteryHook } from "../contracts/hooks/GovernedLotteryHook.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IRouterCommon } from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import { AfterSwapParams, SwapKind } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

// Mock IVault implementation for testing
contract MockVault is IVault {
    function sendTo(IERC20 token, address recipient, uint256 amount) external override {}

    function vault() external view override returns (IVault) {}
}

// Mock IRouterCommon implementation for testing
contract MockRouter is IRouterCommon {
    function getSender() external pure override returns (address) {
        return msg.sender;
    }

    IAllowanceTransfer.PermitBatch calldata permit2Batch,
    bytes calldata permit2Signature,
    bytes[] calldata multicallData,
    bytes calldata permit2Signature,
    bytes[] calldata multicallData

    function multicall(bytes[] calldata data) external override returns (bytes[] memory results) {}
}

contract GovernedLotteryHookTest is Test {
    GovernedLotteryHook lotteryHook;
    MockVault vault;
    MockRouter router;
    address trustedRouter;
    IERC20 mockToken;

    function setUp() public {
        vault = new MockVault();
        router = new MockRouter();
        trustedRouter = address(router);
        mockToken = IERC20(address(0xba100000625a3754423978a60c9317c58a424e3D));

        lotteryHook = new GovernedLotteryHook(IVault(vault), trustedRouter);
    }

    function testDeployment() public {
        assertEq(lotteryHook.hookSwapFeePercentage(), 0);
        assertEq(lotteryHook.LUCKY_NUMBER(), 10);
        assertEq(lotteryHook.MAX_NUMBER(), 20);
    }

    function testSetSwapFeePercentage() public {
        uint64 newFee = 500; // 5%
        lotteryHook.setHookSwapFeePercentage(newFee);
        assertEq(lotteryHook.hookSwapFeePercentage(), newFee);
    }

    function testRandomNumberGeneration() public {
        uint8 randomNumber = lotteryHook.getRandomNumber();
        assertTrue(randomNumber >= 1 && randomNumber <= 20);
    }

    function testOnAfterSwapWithExactIn() public {
        uint64 swapFeePercentage = 1000; // 10%
        lotteryHook.setHookSwapFeePercentage(swapFeePercentage);

        AfterSwapParams memory params = AfterSwapParams({
            router: trustedRouter,
            tokenIn: mockToken,
            tokenOut: mockToken,
            kind: SwapKind.EXACT_IN,
            amountCalculatedRaw: 1000 * 1e18,
            amountIn: 1000 * 1e18,
            amountOut: 0,
            balanceIn: 1000 * 1e18,
            balanceOut: 1000 * 1e18,
            lastChangeBlockIn: block.number,
            lastChangeBlockOut: block.number,
            protocolSwapFeePercentage: 0,
            userData: abi.encodePacked("")
        });

        (bool success, uint256 adjustedAmount) = lotteryHook.onAfterSwap(params);

        assertTrue(success);
        uint256 expectedFee = (params.amountCalculatedRaw * swapFeePercentage) / 1e18;
        assertEq(adjustedAmount, params.amountCalculatedRaw - expectedFee);
    }

    function testOnAfterSwapWithExactOut() public {
        uint64 swapFeePercentage = 1000; // 10%
        lotteryHook.setHookSwapFeePercentage(swapFeePercentage);

        AfterSwapParams memory params = AfterSwapParams({
            router: trustedRouter,
            tokenIn: mockToken,
            tokenOut: mockToken,
            kind: SwapKind.EXACT_OUT,
            amountCalculatedRaw: 1000 * 1e18,
            amountIn: 0,
            amountOut: 1000 * 1e18,
            balanceIn: 1000 * 1e18,
            balanceOut: 1000 * 1e18,
            lastChangeBlockIn: block.number,
            lastChangeBlockOut: block.number,
            protocolSwapFeePercentage: 0,
            userData: abi.encodePacked("")
        });

        (bool success, uint256 adjustedAmount) = lotteryHook.onAfterSwap(params);

        assertTrue(success);
        uint256 expectedFee = (params.amountCalculatedRaw * swapFeePercentage) / 1e18;
        assertEq(adjustedAmount, params.amountCalculatedRaw + expectedFee);
    }

    function testLotteryWin() public {
        uint8 luckyNumber = lotteryHook.LUCKY_NUMBER();
        uint256 swapAmount = 1000 * 1e18;

        for (uint256 i = 0; i < 50; i++) {
            AfterSwapParams memory params = AfterSwapParams({
                router: trustedRouter,
                tokenIn: mockToken,
                tokenOut: mockToken,
                kind: SwapKind.EXACT_IN,
                amountCalculatedRaw: swapAmount,
                amountIn: swapAmount,
                amountOut: 0,
                balanceIn: 1000 * 1e18,
                balanceOut: 1000 * 1e18,
                lastChangeBlockIn: block.number,
                lastChangeBlockOut: block.number,
                protocolSwapFeePercentage: 0,
                userData: abi.encodePacked("")
            });

            (bool success, uint256 adjustedAmount) = lotteryHook.onAfterSwap(params);
            assertTrue(success);

            uint8 randomNumber = lotteryHook.getRandomNumber();
            if (randomNumber == luckyNumber) {
                emit log("Lottery win triggered!");
                break;
            }
        }
    }
}
