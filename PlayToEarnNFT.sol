// SPDX-License-Identifier: FTM
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PlayToEarnNFT is
ERC721("Play To Earn NFT", "PTENFT"),
Ownable(address(0x2c9f3404c42d555c5b766b1f59d6FF24D27f2ecE))
{
    uint256 public lastTimestamp;
    uint256 public nextTokenId; // NFT Token ID

    constructor() {
        // First timestamp creation
        lastTimestamp = block.timestamp;

        // Give nft to the owner
        _safeMint(owner(), nextTokenId);
        // Increase the token id to the next NFT
        nextTokenId++;
    }

    function mintNFT() public onlyOwner {
        require(
            block.timestamp >= lastTimestamp + 1 hours,
            "NFTs can only be minted every 1 hour"
        );

        // Update the last time stamp
        lastTimestamp = block.timestamp;

        // Give nft to the owner
        _safeMint(owner(), nextTokenId);
        // Increase the NFT Token ID
        nextTokenId++;
    }

    function burnNFT(uint256 tokenId) public onlyOwner {
        // Check if the current wallet owns the nft
        require(ownerOf(tokenId) == owner(), "You can only burn your own NFTs");

        // Burn...
        _burn(tokenId);
    }
}
