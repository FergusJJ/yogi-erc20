// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Yogi} from "../src/Yogi.sol";

contract YogiTest is Test {
    Yogi public yogi;

    address supplyOwnerAddress = makeAddr("BerachainWalletUser"); // 0xE3284cB941608AA9E65F7EDdbb50c461D936622f
    address randomWalletAddress = makeAddr("GiveMeTokens"); // 0x187A660c372Fa04D09C1A71f2927911e62e98a89
    address anotherWalletAddress = makeAddr("AnotherAddress");

    function setUp() public {
        vm.prank(supplyOwnerAddress);
        yogi = new Yogi("Yogi Coin", "YOGI", 1000000000);
    }

    function test_name() public {
        assertEq(yogi.name(), "Yogi Coin");
    }
    
    function test_symbol() public {
        assertEq(yogi.symbol(), "YOGI");
    }
    
    function test_supply() public {
        assertEq(yogi.totalSupply(), 1000000000);
    }

    function test_balanceOfAddress0() public {
        assertEq(yogi.balanceOf(address(0)), 0);
    }

    function test_governorIsAdmin() public {
        address governorAddress = address(yogi.governor());
        vm.prank(randomWalletAddress);
        try yogi.createProposal("Test proposal") {
            revert("Non-owner address was able to perform action");
        } catch {}
        assertEq(governorAddress, supplyOwnerAddress , "Governor should be the contract deployer");
    }

    function test_giveRightToVote() public {
        // Ensure that msg.sender is the governor
        vm.prank(supplyOwnerAddress);

        // Check that the governor address is supplyOwnerAddress
        assertEq(address(yogi.governor()), supplyOwnerAddress, "Governor address should be supplyOwnerAddress");

        vm.prank(supplyOwnerAddress);
        // Call giveRightToVote with the governor's address
        yogi.giveRightToVote(randomWalletAddress);

        // Check if the right to vote is correctly assigned
        assertEq(yogi.votingRights(randomWalletAddress), true, "Address #1 should have right to vote");
        assertEq(yogi.votingRights(anotherWalletAddress), false, "Address #2 should not have the right to vote");
    }
    
    function test_revokeRightToVote() public {
        
        assertEq(address(yogi.governor()), supplyOwnerAddress, "Governor address should be supplyOwnerAddress");
        
        vm.prank(supplyOwnerAddress); 
        yogi.giveRightToVote(randomWalletAddress);
        assertEq(yogi.votingRights(randomWalletAddress), true, "Address #1 should have right to vote");

        vm.prank(supplyOwnerAddress);
        yogi.revokeRightToVote(randomWalletAddress);
        assertEq(yogi.votingRights(randomWalletAddress), false, "Address #1 should not have right to vote");
    }

    function test_proposal() public {
        vm.prank(supplyOwnerAddress);
        yogi.createProposal("test proposal");
        assertEq(yogi.getProposalIdsLength(), 1, "Number of proposals should be 1");
        assertEq(yogi.proposalIds(0), 0, "ProposalId should be 0");
        assertEq(yogi.getProposalName(0), "test proposal", "proposal names do not match");


        uint256 yesVotes = yogi.getCurrentVotes(0)[0]; 
        uint256 noVotes =  yogi.getCurrentVotes(0)[1]; 
        uint256 vetoVotes = yogi.getCurrentVotes(0)[2]; 
        uint256 abstainVotes =  yogi.getCurrentVotes(0)[3]; 

        assertEq(yesVotes, 0, "number of yes votes do not match");
        assertEq(noVotes, 0, "number of no votes do not match");
        assertEq(vetoVotes, 0, "number of veto votes do not match");
        assertEq(abstainVotes, 0, "number of abstain votes do not match");
    
        assertEq(yogi.isProposalOpen(0), true, "proposal should be open");
    }

    function test_vote() public {

        vm.prank(supplyOwnerAddress);
        yogi.createProposal("test proposal");
        uint proposalId = yogi.getProposalIdsLength() - 1;

        vm.prank(supplyOwnerAddress);        
        yogi.giveRightToVote(supplyOwnerAddress);
        vm.prank(supplyOwnerAddress);
        yogi.vote(proposalId, Yogi.VoteOption.Yes);

        vm.prank(supplyOwnerAddress);        
        yogi.giveRightToVote(randomWalletAddress);        
        vm.prank(randomWalletAddress);
        yogi.vote(proposalId, Yogi.VoteOption.Yes);

        vm.prank(supplyOwnerAddress);        
        yogi.giveRightToVote(anotherWalletAddress);
        vm.prank(anotherWalletAddress);
        yogi.vote(proposalId, Yogi.VoteOption.Yes);

        assertEq(yogi.getYesVotes(proposalId), 3, "Number of yes votes is incorrect");

        vm.prank(anotherWalletAddress);
        //vm.expectRevert(abi.encodeWithSignature("address lacks voting rights"));
        //yogi.vote(proposalId, Yogi.VoteOption.Yes);
    }

    function test_closeVote() public {
        vm.prank(supplyOwnerAddress);
        yogi.createProposal("test proposal");
        assertEq(yogi.isProposalOpen(0), true, "proposal should be open");
        
        vm.prank(anotherWalletAddress);
        try yogi.closeProposal(0) {
            revert("Non-owner address was able to perform action");
        } catch {} 
        
        vm.prank(supplyOwnerAddress); 
        yogi.closeProposal(0);
        
        vm.prank(anotherWalletAddress);
        try yogi.vote(0, Yogi.VoteOption.Yes) {
            revert("user was able to vote on closed proposal");
        } catch {}


        Yogi.VoteOutcome outcome = yogi.getWinner(0);
        Yogi.VoteOutcome expected = Yogi.VoteOutcome.Tie;


        assertEq(uint256(outcome), uint256(expected), "incorrect vote outcome");

    } 
}
