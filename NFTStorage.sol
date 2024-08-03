// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTStorage is IERC721Receiver, Ownable {
    struct NFT {
        address tokenAddress;
        uint256 tokenId;
    }

    NFT[] private nfts;
    mapping(address => bool) private hasReceivedNFT;

    event NFTReceived(address indexed operator, address indexed from, uint256 tokenId, bytes data);
    event NFTIssued(address indexed to, address indexed tokenAddress, uint256 tokenId);

    constructor(address initialOwner) Ownable(initialOwner) {}

    // Функция для получения NFT. Только владелец может вызывать эту функцию.
    function receiveNFT(address tokenAddress, uint256 tokenId) external onlyOwner {
        IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        nfts.push(NFT(tokenAddress, tokenId));
        emit NFTReceived(msg.sender, address(this), tokenId, "");
    }

    // Функция для выдачи NFT. Любой может вызывать эту функцию.
    function issueNFT(address to, uint256 index) external {
        require(!hasReceivedNFT[to], "User has already received an NFT");
        require(index < nfts.length, "Invalid index");

        NFT memory nft = nfts[index];
        IERC721(nft.tokenAddress).safeTransferFrom(address(this), to, nft.tokenId);
        emit NFTIssued(to, nft.tokenAddress, nft.tokenId);

        // Удаление NFT из массива
        nfts[index] = nfts[nfts.length - 1];
        nfts.pop();

        // Отметка, что адрес получил NFT
        hasReceivedNFT[to] = true;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }

    function getNFTCount() public view returns (uint256) {
        return nfts.length;
    }

    function getNFT(uint256 index) public view returns (address tokenAddress, uint256 tokenId) {
        require(index < nfts.length, "Invalid index");
        NFT memory nft = nfts[index];
        return (nft.tokenAddress, nft.tokenId);
    }
}
