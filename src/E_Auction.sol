//SPDX-License-Identifier: MIT

pragma solidity 0.8.21; 

import {IERC165} from "lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";



contract E_Auction {

bytes4 constant ERC721_INTERFACE_ID = 0x80ac58cd;
uint256 auctionId = 0;
address  DEPLOYER;
uint8 auctionFeePercentage;



constructor() {
    DEPLOYER = msg.sender;
    adminAddress[msg.sender] = true;
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
mapping(address => bool) adminAddress;

/******************EVENTS********* */

event auctionPlaced(uint256 _auctionId, TokenAuctionDetails _tokenAuctionDetails);
event bidPlaced(uint256 _auctionId,address callerAddress,TokenAuctionDetails _tokenAuctionDetails);
event auctionClaimed(address callerAddress, uint256 timeOfClaim, uint256 _auctionId, TokenAuctionDetails);

error addressIsNotAContract(address tokenAddressToCheck);
error invalidTokenOwner(address tokenOwner, address allegedOwner);
error noAuctionWithIdFound(uint256 allegedAuctionId);
error bidHasClosed(uint256 timeBidClosed);
error bidPlacedIsLessThanTheCurrentHighestBid(uint256 bidPlaced,uint256 currentHighestBid);
error bidPlacedIsLessThanTheStartingAmount(uint256 bidPlaced, uint256  startingAmount);
error invalidAuctionId(uint256 auctionIdPassed);
error youCannotCallThisFunction();
error auctionIsNotOver(uint256 timeLeft);
error tokenIsNotERC721(address tokenAddress);
error invalidMethodOfPayment(address methodOfPayment);
error youCannotBidWithErc20Token();
error onlyAdminCanCallThisFunction();
error youCannotRemoveInitialDeployerFromAdmin();
error onlyDeployerAddressCanCallThisFunction();

modifier isAdmin {
    if(adminAddress[msg.sender] != true) {
        revert onlyAdminCanCallThisFunction();
    }
    _;
} 


    function createAuctionWithErc20Token(uint256 auctionTimePeriod, address tokenAddressForSale, uint256 startingAmount, uint256 tokenId, address methodOfPayment) public {
        bool isERC721 = isErc721Token(tokenAddressForSale);
        if(isERC721 == false) {
            revert tokenIsNotERC721(tokenAddressForSale);
        }
         require(ERC721(tokenAddressForSale).getApproved(tokenId) == address(this), "CONTRACT NOT APPROVED TO SPEND TOKEN");
        ERC721(tokenAddressForSale).transferFrom(msg.sender, address(this), tokenId);
        TokenAuctionDetails memory tokenAuctionDetails = TokenAuctionDetails(tokenAddressForSale,msg.sender,block.timestamp + auctionTimePeriod,startingAmount,tokenId,0,methodOfPayment,msg.sender);
        uint256 _auctionId = auctionId++;
        auctionIdToTokenDetails[_auctionId] = tokenAuctionDetails;
        emit auctionPlaced(_auctionId, auctionIdToTokenDetails[_auctionId]);
         
    }


    function createAuctionWithNativeEther(uint256 auctionTimePeriod, address tokenAddressForSale, uint256 startingAmount, uint256 tokenId) public {
        bool isErc721 = isErc721Token(tokenAddressForSale);

        if(isErc721 == false) {
            revert tokenIsNotERC721(tokenAddressForSale);
        }

        require(ERC721(tokenAddressForSale).getApproved(tokenId) == address(this), "CONTRACT NOT APPROVED TO SPEND TOKEN");
        ERC721(tokenAddressForSale).transferFrom(msg.sender, address(this), tokenId);
        TokenAuctionDetails memory tokenAuctionDetails = TokenAuctionDetails(tokenAddressForSale,msg.sender,block.timestamp + auctionTimePeriod,startingAmount,tokenId,0,address(0),msg.sender);
        uint256 _auctionId = auctionId++;
        auctionIdToTokenDetails[_auctionId] = tokenAuctionDetails;
        emit auctionPlaced(_auctionId,auctionIdToTokenDetails[_auctionId]);

    }
    

    function makeABidWithERC20Token(uint256 _auctionId, uint256 amountToTransfer) public returns(TokenAuctionDetails memory) {
        
        (bool isOpened,) = isAuctionOpen(_auctionId);

        if(isOpened == false) {
            revert bidHasClosed(auctionIdToTokenDetails[_auctionId].auctionEndTime); 
        } 

       
if(auctionIdToTokenDetails[_auctionId].methodOfPayment != address(0)) {
    if(amountToTransfer >= auctionIdToTokenDetails[_auctionId].startingAmount) {

     if(amountToTransfer < auctionIdToTokenDetails[_auctionId].currentHighestBid) {
            revert bidPlacedIsLessThanTheCurrentHighestBid(amountToTransfer, auctionIdToTokenDetails[_auctionId].currentHighestBid); 
            
            }
             require(ERC20(auctionIdToTokenDetails[_auctionId].methodOfPayment).approve(address(this), amountToTransfer),"NO TRANSFER MADE");
      
      bool success =   ERC20(auctionIdToTokenDetails[_auctionId].methodOfPayment).transferFrom(msg.sender,address(this),amountToTransfer);
      if(success) {
        address previousHighestBidder =  auctionIdToTokenDetails[_auctionId].currentHighestBidder;
        uint256 previousHighestBid = auctionIdToTokenDetails[_auctionId].currentHighestBid;
         
         bool returned =   ERC20(auctionIdToTokenDetails[_auctionId].methodOfPayment).transferFrom(address(this),previousHighestBidder,previousHighestBid);
         require(returned,"failed");
        auctionIdToTokenDetails[_auctionId].currentHighestBid = amountToTransfer; 
            auctionIdToTokenDetails[_auctionId].currentHighestBidder = msg.sender;
            emit bidPlaced(_auctionId,msg.sender,auctionIdToTokenDetails[_auctionId]);  
            return auctionIdToTokenDetails[_auctionId];
      }

    else {
       revert invalidMethodOfPayment(auctionIdToTokenDetails[_auctionId].methodOfPayment);
    }
} else {
    revert  bidPlacedIsLessThanTheStartingAmount(amountToTransfer,auctionIdToTokenDetails[_auctionId].startingAmount);
}

}else {
    revert youCannotBidWithErc20Token();
}
    } 

    function makeABidWithNativeEther(uint256 _auctionId) public payable returns(TokenAuctionDetails memory) {
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
            emit bidPlaced(_auctionId,msg.sender,auctionIdToTokenDetails[_auctionId]);
            return auctionIdToTokenDetails[_auctionId];

        }else {
            revert invalidMethodOfPayment(auctionIdToTokenDetails[_auctionId].methodOfPayment);
        }
    }




function claimAuction(uint256 _auctionId) public returns (TokenAuctionDetails memory) {
    TokenAuctionDetails memory auctionToClaim = auctionIdToTokenDetails[_auctionId];
    (bool isOpened, ) = isAuctionOpen(_auctionId);

    if (isOpened == true) {
        revert auctionIsNotOver(auctionToClaim.auctionEndTime - block.timestamp);
    }

    address auctionWinner = auctionToClaim.currentHighestBidder;
    address tokenSeller = auctionToClaim.tokenSeller;
    uint256 auctionAmount = auctionToClaim.currentHighestBid;


    
    if (msg.sender != auctionWinner && msg.sender != DEPLOYER && msg.sender != tokenSeller) {
        revert youCannotCallThisFunction();
    }

    ERC721(auctionToClaim.tokenAddress).approve(auctionWinner, auctionToClaim.tokenId);
    ERC721(auctionToClaim.tokenAddress).transferFrom(address(this), auctionWinner, auctionToClaim.tokenId);

    if (auctionToClaim.tokenAddress == address(0)) {
        (bool success, ) = tokenSeller.call{value: auctionAmount}("");
        require(success, "error occurred");
        emit auctionClaimed(msg.sender, block.timestamp, _auctionId, auctionToClaim);
        return auctionToClaim;
    }

    uint256 auctionAmountAfterFee =  ((uint256(auctionFeePercentage)*auctionAmount)/100);
    ERC20(auctionToClaim.methodOfPayment).approve(tokenSeller, type(uint256).max);
    if(auctionFeePercentage != 0) {
          ERC20(auctionToClaim.methodOfPayment).transferFrom(address(this), tokenSeller, auctionAmountAfterFee);
    }else {
    ERC20(auctionToClaim.methodOfPayment).transferFrom(address(this), tokenSeller, auctionAmount);
    }
    emit auctionClaimed(msg.sender, block.timestamp, _auctionId, auctionToClaim);
    return auctionToClaim;
}

function addAdmin(address addressToMakeAdmin) isAdmin public {

adminAddress[addressToMakeAdmin] = true;
}

function removeAdmin(address addressOfAdminToRemove) isAdmin public {
    if(addressOfAdminToRemove == DEPLOYER) {
        revert youCannotRemoveInitialDeployerFromAdmin();
    }
    adminAddress[addressOfAdminToRemove] = false;
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

function withdrawEther(uint256 amount) external {
    if(msg.sender != DEPLOYER) {
        revert onlyDeployerAddressCanCallThisFunction();
    }

    if(amount == 0) { 
    (bool success,) = DEPLOYER.call{value: address(this).balance}("");
     require(success);
    }else {
         (bool success,) = DEPLOYER.call{value: amount}("");
          (success);
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

function returnAuctionCount() public view returns(uint256) {
    return auctionId;
}

function ownerOf(address tokenAddress, uint256 tokenId) public view returns(address) {
    return(ERC721(tokenAddress).ownerOf(tokenId));
}

function returnInitialDeloyer () public view returns(address) {
    return DEPLOYER;
}

function checkIsAdmin(address addressToCheck) public view returns(bool) {
    return adminAddress[addressToCheck];
}

function returnAuctionFeePercentage() public view returns(uint8) {
return auctionFeePercentage;
}
}
