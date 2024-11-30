//SPDX-License-Identifier: MIT

pragma solidity 0.8.13; 

import {IERC165} from "lib/forge-std/openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import {ERC721} from "lib/forge-std/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";



contract E_Auction {

bytes4 constant ERC721_INTERFACE_ID = 0x80ac58cd;
uint256 auctionId = 0;

struct TokenAuctionDetails {
    address tokenAddress;
    uint256 auctionEndTime;
    uint256 startingAmount;
    uint256 tokenId;
    uint256 currentAmount;
}


/******************MAPPINGS */
mapping(uint256 => TokenAuctionDetails) auctionIdToTokenDetails;

    // function that allows anyone to add a token to auction

error addressIsNotAContract(address tokenAddressToCheck);
error invalidTokenOwner(address tokenOwner, address allegedOwner);
error noAuctionWithIdFound(uint256 allegedAuctionId);



    function createAuction(uint256 auctionTimePeriod, address tokenAddressForSale, uint256 startingAmount, uint256 tokenId) public {
        isErc721Token(tokenAddressForSale);
        address tokenOwner = ERC721(tokenAddressForSale).ownerOf(tokenId);
        if(tokenOwner != msg.sender) {
            revert invalidTokenOwner(tokenOwner, msg.sender);
        }
        TokenAuctionDetails memory tokenAuctionDetails = TokenAuctionDetails(tokenAddressForSale,block.timestamp + auctionTimePeriod,startingAmount,tokenId,startingAmount);
        uint256 _autionId = auctionId++;
        auctionIdToTokenDetails[_autionId] = tokenAuctionDetails;
         
    }


function isErc721Token(address tokenAddress) public view returns(bool) {
    uint256 size;
    assembly {
        size := extcodesize(tokenAddress)
}
     if(size ==  0) {
        revert addressIsNotAContract(tokenAddress);
     }

     try IERC165(tokenAddress).supportsInterface(ERC721_INTERFACE_ID) returns (bool result) {
        return result;
        }catch {
        return false;
     }


}


function isAuctionOpen(uint256 _auctionId) public view returns(bool,uint256) {
    TokenAuctionDetails memory _tokenAuctionDetails = auctionIdToTokenDetails[_auctionId];
    if(block.timestamp > _tokenAuctionDetails.auctionEndTime) {
        return(false,0);
    }else {
        return(true,_tokenAuctionDetails.auctionEndTime - block.timestamp);
    }

}


/*************RETURN FUNCTIONS */

function getAuctionDetails(uint256 _auctionId) public view returns(TokenAuctionDetails memory) {
return auctionIdToTokenDetails[_auctionId];
}
}
