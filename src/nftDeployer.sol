//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {NFT} from "src/NFT.sol";
contract NFTDeployer  {

/************EVENTS */
event newNftCollectionHasBeenCreated(address tokenAddress, address tokenOwner, string name, string symbol,uint256 timeOfDeployment);
event newNftHasBeenMinted(address tokenAddress, address callerAddress, uint256 tokenId, address addressToMintTo);


function createNftCollection(string memory nftName, string memory nftSymbol ) public returns (NFT) {

NFT newNft = new NFT(nftName,nftSymbol,msg.sender);
emit newNftCollectionHasBeenCreated(address(newNft),msg.sender,nftName,nftSymbol,block.timestamp);
return newNft;

}








}