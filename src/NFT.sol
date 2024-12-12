//SPDX-License-Identifier: MIT
pragma solidity 0.8.13 

 import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

 contract NFT is ERC721 {



    /**********EVENTS ****/
    event newTokenMinted(address mintedTo,address tokenId);


constructor(
    string memory name,
    string memory symbol;
)

uint256 tokenId = 0;



function mintNewNft() {
     nftTokenId =  tokenId++;
    _mint(addressToMintTo, nftTokenId);
    emit newTokenMinted(addressToMintTo,tokenId);
}





 }
