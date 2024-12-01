//SPDX-License-Identifier: MIT

pragma solidity 0.8.13; 

import {IERC165} from "lib/forge-std/openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import {ERC721} from "lib/forge-std/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC20} from "lib/forge-std/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";



contract E_Auction {

bytes4 constant ERC721_INTERFACE_ID = 0x80ac58cd;
uint256 auctionId = 0;

struct TokenAuctionDetails {
    address tokenAddress;
    uint256 auctionEndTime;
    uint256 startingAmount;
    uint256 tokenId;
    uint256 currentHighestBid;
    address methodOfPayment;
    address currentHighestBidder;
}


/******************MAPPINGS */
mapping(uint256 => TokenAuctionDetails) auctionIdToTokenDetails;

/******************EVENTS********* */

event auctionPlaced(uint256 _auctionId, TokenAuctionDetails _tokenAuctionDetails);
event bidPlaced(uint256 _auctionId, TokenAuctionDetails _tokenAuctionDetails);

error addressIsNotAContract(address tokenAddressToCheck);
error invalidTokenOwner(address tokenOwner, address allegedOwner);
error noAuctionWithIdFound(uint256 allegedAuctionId);
error bidHasClosed(uint256 timeBidClosed);
error bidPlacedIsLessThanTheCurrentHighestBid(uint256 bidPlaced,uint256 currentHighestBid);



    function createAuction(uint256 auctionTimePeriod, address tokenAddressForSale, uint256 startingAmount, uint256 tokenId, address methodOfPayment) public {
        isErc721Token(tokenAddressForSale);
        address tokenOwner = ERC721(tokenAddressForSale).ownerOf(tokenId);
        if(tokenOwner != msg.sender) {
            revert invalidTokenOwner(tokenOwner, msg.sender);
        }
        TokenAuctionDetails memory tokenAuctionDetails = TokenAuctionDetails(tokenAddressForSale,block.timestamp + auctionTimePeriod,startingAmount,tokenId,startingAmount,methodOfPayment,msg.sender);
        uint256 _auctionId = auctionId++;
        auctionIdToTokenDetails[_auctionId] = tokenAuctionDetails;
        emit  auctionPlaced(_auctionId, auctionIdToTokenDetails[_auctionId]);
         
    }

    function makeABid(uint256 _auctionId, uint256 amountToTransfer) public payable returns(TokenAuctionDetails memory) {
        bool isOpened;
        (isOpened,) = isAuctionOpen(_auctionId);

        if(isOpened == false) {
            revert bidHasClosed(auctionIdToTokenDetails[_auctionId].auctionEndTime); 
        } 

        if(auctionIdToTokenDetails[_auctionId].methodOfPayment == address(0)) {
            if(msg.value < auctionIdToTokenDetails[_auctionId].currentHighestBid) {
                revert bidPlacedIsLessThanTheCurrentHighestBid(msg.value, auctionIdToTokenDetails[_auctionId].currentHighestBid); 
            }

            auctionIdToTokenDetails[_auctionId].currentHighestBid = msg.value; 
            auctionIdToTokenDetails[_auctionId].currentHighestBidder = msg.sender;
            emit bidPlaced(_auctionId,auctionIdToTokenDetails[_auctionId]);
            return auctionIdToTokenDetails[_auctionId];
        }

     if(amountToTransfer < auctionIdToTokenDetails[_auctionId].currentHighestBid) {
            revert bidPlacedIsLessThanTheCurrentHighestBid(amountToTransfer, auctionIdToTokenDetails[_auctionId].currentHighestBid); 
            
            }
        ERC20(auctionIdToTokenDetails[_auctionId].methodOfPayment).approve(address(this),amountToTransfer);
      bool success =   ERC20(auctionIdToTokenDetails[_auctionId].methodOfPayment).transferFrom(msg.sender,address(this),amountToTransfer);
      if(success) {
        auctionIdToTokenDetails[_auctionId].currentHighestBid = amountToTransfer; 
            auctionIdToTokenDetails[_auctionId].currentHighestBidder = msg.sender;
                        emit bidPlaced(_auctionId,auctionIdToTokenDetails[_auctionId]);
            return auctionIdToTokenDetails[_auctionId];
      }


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
