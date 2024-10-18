// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { GovernedLotteryHook } from "../contracts/hooks/GovernedLotteryHook.sol";
import { AfterSwapParams, SwapKind } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

contract GovernedLotteryHookTest is Test {
    GovernedLotteryHook hook;
    IVault vault;
    address owner;
    address router;
    address alice;
    address bob;

    IERC20 tokenIn;
    IERC20 tokenOut;

    function setUp() public {
        owner = address(this);
        vault = IVault(address(0xBA12222222228d8Ba445958a75a0704d566BF2C8));
        router = address(0x886A3Ec7bcC508B8795990B60Fa21f85F9dB7948);
        alice = address(1);
        bob = address(2);

        tokenIn = IERC20(address(0xba100000625a3754423978a60c9317c58a424e3D));
        tokenOut = IERC20(address(0xba100000625a3754423978a60c9317c58a424e3D));

        hook = new GovernedLotteryHook(vault, router);
    }

    function testCreateProposal() public {
        string memory description = "Proposal to change swap fee";
        uint64 newSwapFee = 300;
        uint8 luckyNumber = 7;

        vm.startPrank(owner);
        hook.createProposal(description, newSwapFee, luckyNumber);

        (uint256 proposalId, , , , , , uint256 votingDeadline) = hook.proposals(0);
        assertEq(proposalId, 0);
        assertEq(votingDeadline > block.timestamp, true);
        vm.stopPrank();
    }

    function testVoteOnProposal() public {
        vm.startPrank(owner);
        hook.createProposal("Test Voting", 200, 8);
        vm.stopPrank();

        vm.startPrank(alice);
        hook.voteOnProposal(0, true);
        (uint256 votesFor, , , , , uint256 votesAgainst, ) = hook.proposals(0);
        assertEq(votesFor, 1);
        assertEq(votesAgainst, 0);

        vm.expectRevert("You have already voted");
        hook.voteOnProposal(0, true);
        vm.stopPrank();
    }

    function testImplementProposal() public {
        vm.startPrank(owner);
        hook.createProposal("Change fee", 400, 9);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 weeks);
        vm.startPrank(owner);
        hook.implementProposal(0);

        (uint64 swapFee, uint8 luckyNumber) = hook.getCurrentSettings();
        assertEq(swapFee, 400);
        assertEq(luckyNumber, 9);
        vm.stopPrank();
    }

    //     function testOnAfterSwap() public {
    //     uint256 amountIn = 1000 * 1e18;
    //     uint256 fee = amountIn / 100;

    //     deal(address(tokenIn), alice, amountIn);
    //     deal(address(tokenOut), address(hook), 500 * 1e18);

    //     vm.prank(alice);
    //     tokenIn.transfer(address(hook), amountIn);

    //  AfterSwapParams memory swapParams = AfterSwapParams({
    //     poolId: bytes32(0),                   // Pool ID
    //     tokenIn: address(tokenIn),             // Token being swapped in
    //     tokenOut: address(tokenOut),           // Token being swapped out
    //     kind: SwapKind.EXACT_IN,               // Type of swap (Exact In)
    //     amountIn: amountIn,                    // Amount of tokens being swapped in
    //     amountOut: 0,                          // Amount of tokens to be swapped out (for Exact In)
    //     balanceIn: amountIn,                   // Current balance of tokenIn
    //     balanceOut: 500 * 1e18,                // Current balance of tokenOut
    //     lastChangeBlockIn: block.number,       // Last block tokenIn balance changed
    //     lastChangeBlockOut: block.number,      // Last block tokenOut balance changed
    //     protocolSwapFeePercentage: 0,          // Protocol swap fee percentage
    //     router: router                         // Router executing the swap
    // });

    //     vm.prank(router);
    //     (bool success, uint256 hookAdjustedAmount) = hook.onAfterSwap(swapParams);

    //     assertTrue(success, "onAfterSwap should succeed");

    //     uint256 balanceAfter = tokenOut.balanceOf(address(hook));
    //     assertGt(balanceAfter, 0, "Balance after swap should be greater than zero");
    // }

    function testImplementProposalBeforeDeadline() public {
        vm.startPrank(owner);
        hook.createProposal("Early Implementation", 500, 10);
        vm.expectRevert("Voting period has not ended");
        hook.implementProposal(0);
        vm.stopPrank();
    }

    function testMultipleProposalsAndVotes() public {
        vm.startPrank(owner);
        hook.createProposal("Proposal 1", 150, 5);
        hook.createProposal("Proposal 2", 250, 6);
        vm.stopPrank();

        vm.startPrank(alice);
        hook.voteOnProposal(0, true);
        vm.stopPrank();

        vm.startPrank(bob);
        hook.voteOnProposal(1, false);
        vm.stopPrank();

        (uint256 votesFor1, , , , , uint256 votesAgainst1, ) = hook.proposals(0);
        assertEq(votesFor1, 1);
        assertEq(votesAgainst1, 0);

        (uint256 votesFor2, , , , , uint256 votesAgainst2, ) = hook.proposals(1);
        assertEq(votesFor2, 0);
        assertEq(votesAgainst2, 1);
    }
}
