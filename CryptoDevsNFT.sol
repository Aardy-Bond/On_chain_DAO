// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "/Users/aaryanbondekar/Desktop/DeFi/Onchain-DAO/src/IERC721Enumerable.sol";

contract CryptoDevsNFT is ERC721Enumerable {
    // Initialize the ERC-721 contract
    constructor() ERC721("CryptoDevsCollection", "CDC") {}

    // Have a public mint function anyone can call to get an NFT
    function mintToken() public {
        _safeMint(msg.sender, totalSupply());
    }
}