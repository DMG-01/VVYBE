//SPDX-LicenseIdentifier: MIT
pragma solidity 0.8.21;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract BridgedNft is ERC721 {


    mapping(uint256 => string) public tokenIdToTokenURI;

constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
}


function mint (address to, string tokenUri, address tokenId) external returns(uint256, string memory) {
    _mint(to,tokenId);
    tokenIdToTokenURI[tokenId] = tokenUri;
    return(tokenId, tokenUri);
} 

function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return tokenIdToTokenURI[tokenId];  

}