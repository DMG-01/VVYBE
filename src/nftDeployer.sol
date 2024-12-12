//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {NFT} from "src/NFT.sol";
contract NFTDeployer  {

/************EVENTS */
event newNftHasBeenCreated(address tokenAddress, address tokenOwner, string name, string symbol,uint256 timeOfDeployment);


function createNft(string memory nftName, string memory nftSymbol ) public returns (NFT) {

NFT newNft = new NFT(nftName,nftSymbol,msg.sender);
emit newNftHasBeenCreated(address(newNft),msg.sender,nftName,nftSymbol,block.timestamp);
return newNft;

}

function mintNewNft(address nftAddress,uint256 nftTokenId, string[] memory nftProperties, string[] memory nftPropertiesValue, address addressToMintTo) public  {
  NFT(nftAddress).mintNewNft(addressToMintTo,nftProperties,nftPropertiesValue,nftTokenId);
   
}

function mint() public {

}


function burnNft() public {}




}