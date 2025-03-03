//SPDX-License-Identifier: MIT 
 pragma solidity 0.8.21 ;

 import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
 import {Base64} from "lib/openzeppelin-contracts/contracts/utils/Base64.sol";
 import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
 //import {CCIPReceiver} from "src/Bridge/receiverContract.sol";

  contract NFT is ERC721 {

   address owner;

     /*@new */ uint256 totalCount

    /**********EVENTS ****/
    event newTokenMinted(address mintedTo,uint256 tokenId,string tokenUri, uint256 timeOfMint);
    event tokenHasBeenBurned(address burnerAddress, uint256 tokenId, uint256 timeOfBurn);

    /***********MAPPINGS */
    mapping(uint256 => string )tokenIdToURI;


    /*************ERRORS */

    error tokenPropertiesIsNotEqualToTokenLength(uint256 propertiesLength, uint256 valuesLength);
    error onlyOwnerCanCallThisFunction();
    error addressCannotCallThisFunction();
    
    address  CCIPRECEIVER;

constructor(string memory _name, string memory _symbol, address _owner) ERC721(_name, _symbol) {
    owner = _owner;
}





function mintNewNft(string calldata ipfsLocation,address addressToMintTo, string[] memory tokenProperties, string[] memory tokenValues,uint256 nftTokenId) public  returns(uint256, string memory){

    if(msg.sender != owner) {
        revert onlyOwnerCanCallThisFunction();
    }
    if(tokenProperties.length != tokenValues.length) {
        revert tokenPropertiesIsNotEqualToTokenLength(tokenProperties.length, tokenValues.length);
    }
    string memory _tokenURI = generateUri(ipfsLocation,tokenProperties,tokenValues);
    tokenIdToURI[nftTokenId] = _tokenURI;
    _mint(addressToMintTo, nftTokenId);
     totalCount++;
    emit newTokenMinted(addressToMintTo,nftTokenId,_tokenURI,block.timestamp);
    return(nftTokenId,_tokenURI);
}



function burnNft(uint256 tokenId) public  {

    _burn(tokenId);
    totalCount--;
    emit tokenHasBeenBurned(msg.sender,tokenId,block.timestamp);

}


function generateUri(
    string memory ipfsLocation, 
    string[] memory tokenProperties,
    string[] memory tokenValues
) internal pure returns (string memory) {
    require(
        tokenProperties.length == tokenValues.length,
        "Properties and values length mismatch"
    );

    
    string memory properties = "{";

    
    properties = string(
        abi.encodePacked(
            properties,
            '"image": "', ipfsLocation, '", '
        )
    );

    
    for (uint256 i = 0; i < tokenProperties.length; i++) {
        properties = string(
            abi.encodePacked(
                properties,
                '"', tokenProperties[i], '": "', tokenValues[i], '"',
                i == tokenProperties.length - 1 ? "" : ", "
            )
        );
    }

    
    properties = string(abi.encodePacked(properties, "}"));

    
    return string(
        abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(properties))
        )
    );
}



/***************GETTER FUNCTION *****/


function returnTotalNftCount() public returns(uint256) {

    return totalCount;
}
function tokenURI(uint256 _tokenId) public view override returns(string memory ) {
    return tokenIdToURI[_tokenId];
}


function returnNftOwner() public view returns(address) {
    return owner;
}
// CHECK THE FUNCTIOn and its use
function checkIsDeployer(address addressToCheck) public view returns(bool isOwner) {
    if (addressToCheck == owner) {
        return true;
    }else  {
        return false;
    }
}

 }
