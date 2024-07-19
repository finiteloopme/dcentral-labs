// contracts/nft-erc721.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721, ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFT is ERC721URIStorage {
    uint256 private _nextTokenId;
    string private _tokenURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory tokenURI
    ) ERC721(name, symbol) {
        _tokenURI = tokenURI;
    }

    function awardItem(address player)
        public
        returns (uint256)
    {
        uint256 tokenId = _nextTokenId++;
        _mint(player, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        return tokenId;
    }
}