//SPDX-License-Identifier:MIT
pragma solidity 0.8.21;


import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract NftMarketPlace is IERC721Receiver {

    uint256 saleId = 0;
    uint256 percentageFee = 1;
    address DEPLOYER;
  
    
    constructor() {
         DEPLOYER = msg.sender;
         isAdmin[msg.sender] = true;
    }

    modifier onlyAdmin {
        if(false == isAdmin[msg.sender]) {
            revert onlyAdminCanCallThisFunction();
        }
        _;
    }

    struct nftDetails {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        address methodOfPayment;
        address sellerAddress;
    }

    mapping(uint256 => nftDetails) idToNftDetails; 
    mapping(uint256 => bool) isSold;
    mapping(address => bool) isAdmin;

    /*****************ERRORS ****/
    error nftHasBeenSold();
    error onlyNftOwnerCanCallThisFunction();
    error tokenHasBeenUnlistedFromSale();
    error onlyAdminCanCallThisFunction();
    error youCannotRemoveInitialDeployer();
    error youCannotChangeThePriceOfNftSinceItHasBeenSold();
    error youCannotCallThisFunctionSinceNftHasBeenSold();


    /*********************EVENTS ***/
    event nftHasBeenListedForSale(address tokenAddress, uint256 tokenId, uint256 amount, address methodOfPayment, address seller);
    event nftHasBeenBought(address buyerAddress, nftDetails detailsOfNft, uint256 timeOfSale);
    event nftPriceHasBeenChanged(uint256 timeOfChange, nftDetails _nftDetails);
    event nftHasBeenRemovedFomSale(uint256 timeOfUnlisiting, nftDetails detailsOfnlistedNft);
    event contractAddressPercentageFeeHasBeenChanged(address callerAddress, uint256 newPercentageFee);
    event newAdminHasBeenAdded(address callerAddress, address newAdminAddress);
    event adminHasBeenRemoved(address callerAddress, address adminAddressToRemove);


     function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external override pure  returns (bytes4) {
        // Optionally handle the received token (e.g., store info)
        return this.onERC721Received.selector; // Required confirmation
    }

    
    function sellNft(address tokenAddress,uint256 tokenId,uint256 amount,address methodOfPayment) public returns(uint256, nftDetails memory) {
        require(address(this) == ERC721(tokenAddress).getApproved(tokenId),"APPROVE THIS CONTRACT ADDRESS TO SPEND YOUR TOKEN");
        uint256 nftSaleId = saleId++;
        nftDetails memory  _nftDetails =  nftDetails(tokenAddress,tokenId,amount,methodOfPayment,msg.sender);
        idToNftDetails[nftSaleId] = _nftDetails;
        isSold[nftSaleId] = false;
        ERC721(tokenAddress).safeTransferFrom(msg.sender,address(this),tokenId);
        emit nftHasBeenListedForSale(tokenAddress, tokenId,amount, methodOfPayment,msg.sender);
        return(nftSaleId,_nftDetails);
    }


    function buyNft(uint256 _saleId) public returns(nftDetails memory) {

    if(isSold[_saleId] == true ) {
        revert nftHasBeenSold();
    }

    if(idToNftDetails[_saleId].tokenAddress ==address(0)) {
        revert tokenHasBeenUnlistedFromSale();
    }
    require( ERC20(idToNftDetails[_saleId].methodOfPayment).allowance(msg.sender,address(this)) >=  idToNftDetails[_saleId].amount,"INCREASE ERC20 ALLOWANCE OF THIS ADDRESS");

    isSold[_saleId] = true;
    uint256 percentageToSend = 100 - percentageFee;
    uint256 amountAfterFee = ((percentageToSend*idToNftDetails[_saleId].amount)/100);
    ERC20(idToNftDetails[_saleId].methodOfPayment).transferFrom(msg.sender,idToNftDetails[_saleId].sellerAddress,amountAfterFee);
    ERC20(idToNftDetails[_saleId].methodOfPayment).transferFrom(msg.sender,address(this),idToNftDetails[_saleId].amount - amountAfterFee);
    ERC721(idToNftDetails[_saleId].tokenAddress).transferFrom(address(this),msg.sender,idToNftDetails[_saleId].tokenId);

    emit nftHasBeenBought(msg.sender,idToNftDetails[_saleId],block.timestamp);
    return(idToNftDetails[_saleId]);
}


function changeNftPrice(uint256 _saleId, uint256 newAmount, address addressOfMethodOfPayment) public returns(nftDetails memory) {
  if(msg.sender != idToNftDetails[_saleId].sellerAddress) {
    revert onlyNftOwnerCanCallThisFunction();
  }

  if(isSold[_saleId]) {
    revert youCannotChangeThePriceOfNftSinceItHasBeenSold();
  }
 address _tokenAddress = idToNftDetails[_saleId].tokenAddress;
 uint256 _tokenId = idToNftDetails[_saleId].tokenId;
    
  idToNftDetails[_saleId] = nftDetails(_tokenAddress,_tokenId,newAmount,addressOfMethodOfPayment,msg.sender);
  emit nftPriceHasBeenChanged(block.timestamp,idToNftDetails[_saleId]);  return(idToNftDetails[_saleId]);
}



function removeNftFromSale(uint256 _saleId) public {
  if(msg.sender != idToNftDetails[_saleId].sellerAddress) {
    revert onlyNftOwnerCanCallThisFunction();
  }

  if(isSold[_saleId]) {
    revert youCannotCallThisFunctionSinceNftHasBeenSold();
  }
    nftDetails memory _nftDetails = idToNftDetails[_saleId];
   idToNftDetails[_saleId] = nftDetails(address(0),0,0,address(0),address(0));
   ERC721(_nftDetails.tokenAddress).safeTransferFrom(address(this),msg.sender,_nftDetails.tokenId);
   emit nftHasBeenRemovedFomSale(block.timestamp,_nftDetails);

}


function changePercentageFee(uint256 newPercentageFee) public onlyAdmin {
percentageFee = newPercentageFee;
emit contractAddressPercentageFeeHasBeenChanged(msg.sender,newPercentageFee);

}
function addAdmin(address adminAddressToAdd) public onlyAdmin {
    isAdmin[adminAddressToAdd] = true;
    emit newAdminHasBeenAdded(msg.sender, adminAddressToAdd);
}

function removeAdmin( address adminAddressToRemove) public onlyAdmin {
    if(adminAddressToRemove == DEPLOYER) {
        revert youCannotRemoveInitialDeployer();
    }
    isAdmin[adminAddressToRemove] = false;
    emit adminHasBeenRemoved(msg.sender, adminAddressToRemove);
}

function returnDeployer() public view returns(address) {
    return DEPLOYER;
}
    

function checkIsAddressAdmin(address addressToCheck) public view returns(bool) {
    return(isAdmin[addressToCheck]);
}

function checkIfTokenWithSaleIdIsStillListed(uint256 saleIdToCheck) public view returns(bool){
  return isSold[saleIdToCheck];
}

function returnSaleIdDetails(uint256 _saleIdToCheck) public view returns(nftDetails memory) {
    return idToNftDetails[_saleIdToCheck];
}

function returnPercentageFee() public view returns(uint256) {
    return percentageFee;
}

}

