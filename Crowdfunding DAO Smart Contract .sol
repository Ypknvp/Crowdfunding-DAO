// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CrowdfundingDAO {
    struct Proposal {
        uint id;
        string description;
        uint256 amount;
        address payable recipient;
        uint votes;
        bool executed;
        bool approved;
        mapping(address => bool) voted;
    }

    address public admin;
    uint public proposalCount;
    uint256 public totalFunds;
    bool public paused;

    mapping(uint => Proposal) public proposals;
    mapping(address => uint256) public balances;

    event ProposalCreated(uint id, string description, uint amount, address recipient);
    event Voted(uint proposalId, address voter);
    event FundsWithdrawn(uint proposalId, address recipient, uint amount);
    event EmergencyPaused(bool paused);
    event DonationReceived(address donor, uint amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyIfFundsAvailable(uint _amount) {
        require(address(this).balance >= _amount, "Not enough funds");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function createProposal(string memory _description, uint256 _amount, address payable _recipient) public notPaused {
        require(_amount > 0, "Amount must be greater than zero");

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.description = _description;
        newProposal.amount = _amount;
        newProposal.recipient = _recipient;
        newProposal.executed = false;
        newProposal.approved = false;
        proposalCount++;

        emit ProposalCreated(newProposal.id, _description, _amount, _recipient);
    }

    function vote(uint _proposalId) public notPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.voted[msg.sender], "You have already voted");

        proposal.voted[msg.sender] = true;
        proposal.votes += 1; // Simple voting mechanism

        if (proposal.votes > 2) {
            proposal.approved = true;
        }

        emit Voted(_proposalId, msg.sender);
    }

    function donate() public payable notPaused {
        require(msg.value > 0, "Must send ETH to donate");

        balances[msg.sender] += msg.value;
        totalFunds += msg.value;

        emit DonationReceived(msg.sender, msg.value);
    }

    function withdrawFunds(uint _proposalId) public notPaused onlyIfFundsAvailable(proposals[_proposalId].amount) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.approved, "Proposal not approved");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;
        totalFunds -= proposal.amount;
        proposal.recipient.transfer(proposal.amount);

        emit FundsWithdrawn(_proposalId, proposal.recipient, proposal.amount);
    }

    function togglePause() public onlyAdmin {
        paused = !paused;
        emit EmergencyPaused(paused);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
