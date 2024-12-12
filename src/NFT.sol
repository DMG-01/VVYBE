//SPDX-License-Identifier: MIT 
 pragma solidity 0.8.13 ;

 import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
 import {Base64} from "lib/openzeppelin-contracts/contracts/utils/Base64.sol";
 import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

 contract NFT is ERC721 {



    /**********EVENTS ****/
    event newTokenMinted(address mintedTo,uint256 tokenId,string tokenUri, uint256 timeOfMint);

    /***********MAPPINGS */
    mapping(uint256 => string )tokenIdToURI;


    /*************ERRORS */

    error tokenPropertiesIsNotEqualToTokenLength(uint256 propertiesLength, uint256 valuesLength);


constructor(
    string memory name,
    string memory symbol
)ERC721(name,symbol) {
    
}

uint256 tokenId = 0;



function mintNewNft(address addressToMintTo, string[] memory tokenProperties, string[] memory tokenValues) public  returns(uint256, string memory){
    uint256  nftTokenId =  tokenId++;
    string memory tokenURI = generateUri(tokenProperties,tokenValues);
    tokenIdToURI[nftTokenId] = tokenURI;
    _mint(addressToMintTo, nftTokenId);
    tokenIdToURI[nftTokenId] = tokenURI;

    emit newTokenMinted(addressToMintTo,nftTokenId,tokenURI,block.timestamp);
    return(nftTokenId,tokenURI);
}


function generateUri(
    string[] memory tokenProperties,
    string[] memory tokenValues
) internal pure returns (string memory) {
    require(
        tokenProperties.length == tokenValues.length,
        "Properties and values length mismatch"
    );

    string memory properties = "{";
    
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


/***************GETTER FUNCTION */

function tokenURI(uint256 _tokenId) public view override returns(string memory ) {
    return tokenIdToURI[_tokenId];
}



 }
