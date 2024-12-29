//SPDX-License-Identifier:MIT
pragma solidity 0.8.13;


import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract nftMarketPlace {

    uint256 saleId = 0;
    uint256 percentageFee = 1;
    

    struct nftDetails {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        address methodOfPayment;
        address sellerAddress;
    }

    mapping(uint256 => nftDetails) idToNftDetails; 
    mapping(uint256 => bool) isSold;

    /*****************ERRORS ****/
    error nftHasBeenSold();


    /*********************EVENTS ***/
    event nftHasBeenListedForSale(address tokenAddress, uint256 tokenId, uint256 amount, address methodOfPayment, address seller);
    event nftHasBeenBought(address buyerAddress, nftDetails detailsOfNft, uint256 timeOfSale);
    
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
    require( ERC20(idToNftDetails[_saleId].methodOfPayment).allowance(msg.sender,address(this)) >=  idToNftDetails[_saleId].amount,"INCREASE ERC20 ALLOWANCE OF THIS ADDRESS");

    isSold[_saleId] = true;
    uint256 percentageToSend = 100 - percentageFee;
    uint256 amountAfterFee = ((percentageToSend*idToNftDetails[_saleId].amount)/100);
    ERC20(idToNftDetails[_saleId].methodOfPayment).transferFrom(msg.sender,idToNftDetails[_saleId].sellerAddress,amountAfterFee);
    ERC721(idToNftDetails[_saleId].tokenAddress).transferFrom(address(this),msg.sender,idToNftDetails[_saleId].tokenId);

    emit nftHasBeenBought(msg.sender,idToNftDetails[_saleId],block.timestamp);
    return(idToNftDetails[_saleId]);
}


function changeNftPrice() public {}


function changeNftCollectionPrice() public {}

function removeNftFromSale() public {

}


function changePercentageFee() public {

}


}

