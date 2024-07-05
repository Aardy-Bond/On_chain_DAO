// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract FakeNFTMarketplace {
    /// @dev Maintain a mapping of Fake TokenID to Owner addresses
    mapping(uint256 => address) public tokenOwners;
    
    /// @dev Set the purchase price for each Fake NFT
    uint256 nftCost = 0.11 ether;

    /// @dev purchase() accepts ETH and marks the owner of the given tokenId as the caller address
    /// @param _tokenId - the fake NFT token Id to purchase
    function buyToken(uint256 _tokenId) external payable {
        require(msg.value == nftCost, "This NFT costs 0.11 ether");
        tokenOwners[_tokenId] = msg.sender;
    }

    /// @dev getPrice() returns the price of one NFT
    function getNFTPrice() external view returns (uint256) {
        return nftCost;
    }

    /// @dev available() checks whether the given tokenId has already been sold or not
    /// @param _tokenId - the tokenId to check for
    function isTokenAvailable(uint256 _tokenId) external view returns (bool) {
        // address(0) = 0x0000000000000000000000000000000000000000
        // This is the default value for addresses in Solidity
        if (tokenOwners[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }
}