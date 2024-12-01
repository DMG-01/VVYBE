//SPDX-License-Identifier: MIT

pragma solidity 0.8.13; 

import {IERC165} from "lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";



contract E_Auction {

bytes4 constant ERC721_INTERFACE_ID = 0x80ac58cd;
uint256 auctionId = 0;
address  DEPLOYER;


constructor() {
    DEPLOYER = msg.sender;
}



struct TokenAuctionDetails {
    address tokenAddress;
    address tokenSeller;
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
error invalidAuctionId(uint256 auctionIdPassed);
error youCannotCallThisFunction();
error auctionIsNotOver(uint256 timeLeft);
error tokenIsNotERC721(address tokenAddress);


    function createAuction(uint256 auctionTimePeriod, address tokenAddressForSale, uint256 startingAmount, uint256 tokenId, address methodOfPayment) public {
        bool isERC721 = isErc721Token(tokenAddressForSale);
        if(isERC721 == false) {
            revert tokenIsNotERC721(tokenAddressForSale);
        }
        address tokenOwner = ERC721(tokenAddressForSale).ownerOf(tokenId);
        if(tokenOwner != msg.sender) {
            revert invalidTokenOwner(tokenOwner, msg.sender);
        }
        TokenAuctionDetails memory tokenAuctionDetails = TokenAuctionDetails(tokenAddressForSale,msg.sender,block.timestamp + auctionTimePeriod,startingAmount,tokenId,startingAmount,methodOfPayment,msg.sender);
        uint256 _auctionId = auctionId++;
        auctionIdToTokenDetails[_auctionId] = tokenAuctionDetails;
        ERC721(tokenAddressForSale).approve(address(this),tokenId);
        ERC721(tokenAddressForSale).transferFrom(msg.sender,address(this),tokenId);
        emit auctionPlaced(_auctionId, auctionIdToTokenDetails[_auctionId]);
         
    }
    

    function makeABid(uint256 _auctionId, uint256 amountToTransfer) public payable returns(TokenAuctionDetails memory) {
        
        (bool isOpened,) = isAuctionOpen(_auctionId);

        if(isOpened == false) {
            revert bidHasClosed(auctionIdToTokenDetails[_auctionId].auctionEndTime); 
        } 

        if(auctionIdToTokenDetails[_auctionId].methodOfPayment == address(0)) {
            if(msg.value < auctionIdToTokenDetails[_auctionId].currentHighestBid) {
                revert bidPlacedIsLessThanTheCurrentHighestBid(msg.value, auctionIdToTokenDetails[_auctionId].currentHighestBid); 
            }
            address previousHighestBidder =  auctionIdToTokenDetails[_auctionId].currentHighestBidder;
            uint256 previousHighestBid = auctionIdToTokenDetails[_auctionId].currentHighestBid;
            (bool sent,) = previousHighestBidder.call{value:previousHighestBid}("");
            require(sent,"transfer failed");
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
        address previousHighestBidder =  auctionIdToTokenDetails[_auctionId].currentHighestBidder;
        uint256 previousHighestBid = auctionIdToTokenDetails[_auctionId].currentHighestBid;
         ERC20(auctionIdToTokenDetails[_auctionId].methodOfPayment).approve(previousHighestBidder,previousHighestBid);
         bool returned =   ERC20(auctionIdToTokenDetails[_auctionId].methodOfPayment).transferFrom(address(this),previousHighestBidder,previousHighestBid);
         require(returned,"failed");
        auctionIdToTokenDetails[_auctionId].currentHighestBid = amountToTransfer; 
            auctionIdToTokenDetails[_auctionId].currentHighestBidder = msg.sender;
            emit bidPlaced(_auctionId,auctionIdToTokenDetails[_auctionId]);
            return auctionIdToTokenDetails[_auctionId];
      }


    }


function claimAuction(uint256 _auctionId) public returns(TokenAuctionDetails memory){

    TokenAuctionDetails memory auctionToClaim  = auctionIdToTokenDetails[_auctionId];
   (bool isOpened,) =  isAuctionOpen(_auctionId);

   if(isOpened == true) {
    revert auctionIsNotOver(auctionToClaim.auctionEndTime - block.timestamp);
   }

    
    address auctionWinner = auctionToClaim.currentHighestBidder;
    uint256 auctionAmount = auctionToClaim.currentHighestBid;

    if((msg.sender != auctionWinner) || (msg.sender != DEPLOYER)) {
        revert youCannotCallThisFunction();
    }



   ERC721(auctionToClaim.tokenAddress).approve(auctionWinner,auctionToClaim.tokenId);
   ERC721(auctionToClaim.tokenAddress).transferFrom(address(this),auctionWinner,auctionToClaim.tokenId);

   if(auctionToClaim.tokenAddress == address(0)) {
    (bool success,) = auctionToClaim.tokenSeller.call{value:auctionAmount}("");
    require(success, "error occured");
    return auctionToClaim;
   } 

   ERC20(auctionToClaim.methodOfPayment).approve(auctionToClaim.tokenSeller, auctionAmount);
   ERC20(auctionToClaim.methodOfPayment).transferFrom(address(this),auctionToClaim.tokenSeller,auctionAmount);
   return auctionToClaim;


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
        return true;
        }catch {
        return false;
     }


}





/*************RETURN FUNCTIONS */

function getAuctionDetails(uint256 _auctionId) public view returns(TokenAuctionDetails memory) {
return auctionIdToTokenDetails[_auctionId];
}


function isAuctionOpen(uint256 _auctionId) public view returns(bool,uint256) {
    TokenAuctionDetails memory _tokenAuctionDetails = auctionIdToTokenDetails[_auctionId];
    if(block.timestamp > _tokenAuctionDetails.auctionEndTime) {
        return(false,0);
    }else {
        return(true,_tokenAuctionDetails.auctionEndTime - block.timestamp);
    }

}
}
