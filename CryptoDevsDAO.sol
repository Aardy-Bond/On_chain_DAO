// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "/Users/aaryanbondekar/Desktop/DeFi/Onchain-DAO/src/Ownable.sol";

interface IFakeNFTMarketplace {
    function getNFTPrice() external view returns (uint256);
    function isTokenAvailable(uint256 _tokenId) external view returns (bool);
    function buyToken(uint256 _tokenId) external payable;
}

interface ICryptoDevsNFT {
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract CryptoDevsDAO is Ownable {
    struct ProposalDetails {
        uint256 nftTokenId;
        uint256 votingDeadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool isExecuted;
        mapping(uint256 => bool) hasVoted;
    }

    mapping(uint256 => ProposalDetails) public proposalRegistry;
    uint256 public proposalCounter;

    IFakeNFTMarketplace nftMarketContract;
    ICryptoDevsNFT cryptoDevsNFTContract;

    constructor(address _nftMarketplace, address _cryptoDevsNFT) Ownable(msg.sender) payable {
        nftMarketContract = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFTContract = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    modifier onlyNFTHolder() {
        require(cryptoDevsNFTContract.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposalRegistry[proposalIndex].votingDeadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposalRegistry[proposalIndex].votingDeadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposalRegistry[proposalIndex].isExecuted == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    enum VoteType {
        YAY,
        NAY
    }

    function createNewProposal(uint256 _nftTokenId)
        external
        onlyNFTHolder
        returns (uint256)
    {
        require(nftMarketContract.isTokenAvailable(_nftTokenId), "NFT_NOT_FOR_SALE");
        ProposalDetails storage proposal = proposalRegistry[proposalCounter];
        proposal.nftTokenId = _nftTokenId;
        proposal.votingDeadline = block.timestamp + 5 minutes;

        proposalCounter++;

        return proposalCounter - 1;
    }

    function castVote(uint256 proposalIndex, VoteType vote)
        external
        onlyNFTHolder
        activeProposalOnly(proposalIndex)
    {
        ProposalDetails storage proposal = proposalRegistry[proposalIndex];

        uint256 voterNFTBalance = cryptoDevsNFTContract.balanceOf(msg.sender);
        uint256 voteCount = 0;

        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoDevsNFTContract.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.hasVoted[tokenId] == false) {
                voteCount++;
                proposal.hasVoted[tokenId] = true;
            }
        }
        require(voteCount > 0, "ALREADY_VOTED");

        if (vote == VoteType.YAY) {
            proposal.yayVotes += voteCount;
        } else {
            proposal.nayVotes += voteCount;
        }
    }

    function executeProposal(uint256 proposalIndex)
        external
        onlyNFTHolder
        inactiveProposalOnly(proposalIndex)
    {
        ProposalDetails storage proposal = proposalRegistry[proposalIndex];

        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketContract.getNFTPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketContract.buyToken{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.isExecuted = true;
    }

    function withdrawFunds() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw, contract balance empty");
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "FAILED_TO_WITHDRAW_FUNDS");
    }

    receive() external payable {}

    fallback() external payable {}
}