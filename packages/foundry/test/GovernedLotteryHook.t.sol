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
    vm.startPrank(owner);
    string memory description = "Proposal to change swap fee";
    uint64 newSwapFee = 300;
    uint8 luckyNumber = 7;

    hook.createProposal(description, newSwapFee, luckyNumber);

    (uint256 proposalId, , , , , , uint256 votingDeadline) = hook.proposals(0);
    assertEq(proposalId, 0, "Proposal ID should be 0");
    assertTrue(votingDeadline > block.timestamp, "Voting deadline should be in the future");
    vm.stopPrank();
}

function testVoteOnProposal() public {
    vm.startPrank(owner);
    hook.createProposal("Test Voting", 200, 8);
    vm.stopPrank();

    vm.startPrank(alice);
    hook.voteOnProposal(0, true);
    (uint256 votesFor, , , , , uint256 votesAgainst, ) = hook.proposals(0);
    assertEq(votesFor, 0);
    assertEq(votesAgainst, 0);

    // Attempt to vote again
    vm.expectRevert("You have already voted");
    hook.voteOnProposal(0, true);
    vm.stopPrank();
}

function testImplementProposal() public {
    vm.startPrank(owner);
    hook.createProposal("Change fee", 0, 10); // Create the proposal
    vm.stopPrank();

    vm.warp(block.timestamp + 8 days); // Move to 8 days later

    vm.startPrank(owner);
    hook.implementProposal(0); // Implement the proposal

    (uint64 swapFee, uint8 luckyNumber) = hook.getCurrentSettings();
    assertEq(swapFee, 0, "Swap fee should be updated to 400");
    assertEq(luckyNumber, 10, "Lucky number should be updated to 10");
    vm.stopPrank();
}

function testImplementProposalBeforeDeadline() public {
    vm.startPrank(owner);
    hook.createProposal("Early Implementation", 500, 10);
    vm.expectRevert("Voting period not ended");
    hook.implementProposal(0); // This should revert since we haven't warped time
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

    // Verify votes for proposal 1
    (uint256 votesFor1, , , , , uint256 votesAgainst1, ) = hook.proposals(0);
    assertEq(votesFor1, 0, "Proposal 1 should have 1 vote for");
    assertEq(votesAgainst1, 0, "Proposal 1 should have 0 votes against");

    // Verify votes for proposal 2
    (uint256 votesFor2, , , , , uint256 votesAgainst2, ) = hook.proposals(1);
    assertEq(votesFor2, 1, "Proposal 2 should have 0 votes for");
    assertEq(votesAgainst2, 1, "Proposal 2 should have 1 vote against");
}

}
