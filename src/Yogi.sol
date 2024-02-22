// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";




contract Yogi is ERC20 {

    address public governor;
    
    enum VoteOption { Yes, No, NoWithVeto, Abstain }
    enum VoteOutcome { Yes, No, Unclear, Tie }

    struct Proposal {
        bytes32 name;
        bool isOpen;
        uint yesVotes;
        uint noVotes;
        uint vetoVotes;
        uint abstainVotes;
    }

    //store all proposals by their proposal Id
    mapping(uint => Proposal) public proposals;
    
    //store address to vote values for each proposal id
    mapping(uint => mapping(address => uint)) public votes;

    //store the eligible voting addresses for each proposal
    mapping(address => bool) public votingRights;

    //store number of proposals
    uint[] public proposalIds;

    //errors
    error InvalidVoteOption();
    
    //events
    event ProposalCreated(uint indexed proposalId, bytes32 name);


    constructor(string memory name_, string memory symbol_, uint256 mintedTokens_) ERC20(name_, symbol_){
        governor = msg.sender; // allowed to open new proposals
        _mint(msg.sender, mintedTokens_);
    }

bool private initialized;

function initialize(uint256 initialSupply) public {
    require(!initialized, "Contract is already initialized");
    _mint(msg.sender, initialSupply);
    initialized = true;
}

    function createProposal(bytes32 _name) external {
        require(msg.sender == governor, "only the governor can create a proposal");
        uint proposalId = proposalIds.length;
        proposals[proposalId] = Proposal({
            name:_name, 
            isOpen:true, 
            yesVotes:0, 
            noVotes: 0, 
            vetoVotes: 0, 
            abstainVotes: 0
        });
        proposalIds.push(proposalId);
        emit ProposalCreated(proposalId, _name);
    }


    function vote(uint proposalId, VoteOption _voteOption) public {
        require(proposalId < proposalIds.length, "proposal does not exist");
        require(proposals[proposalId].isOpen, "proposal is closed");
        require(votingRights[msg.sender], "address lacks voting rights");
        if (_voteOption == VoteOption.Yes) {
            proposals[proposalId].yesVotes += 1;
        } else if (_voteOption == VoteOption.No) {
            proposals[proposalId].noVotes += 1;
        } else if (_voteOption == VoteOption.NoWithVeto) {
            proposals[proposalId].vetoVotes += 1;
        } else if (_voteOption == VoteOption.Abstain) {
            proposals[proposalId].abstainVotes += 1;
        } else {
            revert InvalidVoteOption();
        }
        votingRights[msg.sender] = false;
    }

    function giveRightToVote(address voter) public {
        require(msg.sender == governor, "only the governor can modify voting rights");
        votingRights[voter] = true;
    }

    function revokeRightToVote(address voter) public {
        require(msg.sender == governor, "only the governor can modify voting rights");
        votingRights[voter] = false;
    }

    function closeProposal(uint proposalId) public {
        require(msg.sender == governor, "only the governor can close a proposal");
        require(proposalId < proposalIds.length, "proposal does not exist");
        require(proposals[proposalId].isOpen, "proposal is already closed");
        proposals[proposalId].isOpen = false;
    } 

    function getWinner(uint proposalId) public view returns (VoteOutcome) {
        require(proposalId < proposalIds.length, "proposal does not exist");
        require(!proposals[proposalId].isOpen, "proposal is not closed");

        uint totalVotes = proposals[proposalId].yesVotes + proposals[proposalId].noVotes + proposals[proposalId].vetoVotes + proposals[proposalId].abstainVotes;

        uint abstainVotes = proposals[proposalId].abstainVotes;
        uint noVotes = proposals[proposalId].noVotes;
        uint yesVotes = proposals[proposalId].yesVotes; 
        uint vetoVotes = proposals[proposalId].vetoVotes;

        if (vetoVotes > (totalVotes * 33 / 100)) {
            return VoteOutcome.No;
        } else if (yesVotes > noVotes && yesVotes > abstainVotes && yesVotes > vetoVotes) {
            return VoteOutcome.Yes;
        } else if (noVotes > yesVotes && noVotes > abstainVotes && noVotes > vetoVotes) {
            return VoteOutcome.No;
         }  else if (abstainVotes > yesVotes && abstainVotes > noVotes && abstainVotes > vetoVotes) {
            return VoteOutcome.Unclear;
        } else {
            // Handle tie or no clear winner
            return VoteOutcome.Tie;
        }
    }

    function getCurrentVotes(uint proposalId) public view returns (uint256[4] memory) {
        require(proposalId < proposalIds.length, "proposal does not exist");
        
        uint abstainVotes = proposals[proposalId].abstainVotes;
        uint noVotes = proposals[proposalId].noVotes;
        uint yesVotes = proposals[proposalId].yesVotes; 
        uint vetoVotes = proposals[proposalId].vetoVotes;
        
        return [yesVotes, noVotes, vetoVotes, abstainVotes];
    }

    function getProposalIdsLength() public view returns (uint) {
        return proposalIds.length;
    }

    function getProposal(uint key) public view returns (Proposal memory) {
        require(key < proposalIds.length, "proposal does not exist");
        return proposals[key];
    }

    function getProposalName(uint index) public view returns (bytes32) {
        require(index < proposalIds.length, "proposal does not exist");
        return proposals[index].name;
    }

    function isProposalOpen(uint index) public view returns (bool) {
        require(index < proposalIds.length, "proposal does not exist");
        return proposals[index].isOpen;
    }

    function getYesVotes(uint index) public view returns (uint) {
        require(index < proposalIds.length, "proposal does not exist");
        return proposals[index].yesVotes;
    }

    function getNoVotes(uint index) public view returns (uint) {
        require(index < proposalIds.length, "proposal does not exist");
        return proposals[index].noVotes;
    }

    function getVetoVotes(uint index) public view returns (uint) {
        require(index < proposalIds.length, "proposal does not exist");
        return proposals[index].vetoVotes;
    }

    function getAbstainVotes(uint index) public view returns (uint) {
        require(index < proposalIds.length, "proposal does not exist");
        return proposals[index].abstainVotes;
    }

}
