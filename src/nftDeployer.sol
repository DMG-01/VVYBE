//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract NFTDeployer  {


function createNft(string memory nftName, string memory nftSymbol, uint256 firstTokenId ) public returns (ERC721) {
ERC721 newErc721 = new ERC721(nftName,nftSymbol);
//newErc721._mint(msg.sender,firstTokenId);


}

function mintNewNft() public  {}

function mint() public {

}


function burnNft() public {}




}