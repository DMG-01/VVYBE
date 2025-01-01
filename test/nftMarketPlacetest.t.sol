//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {Test} from "lib/forge-std /src/Test.sol";
import {deployScript} from "script/deployerScript.script.sol";
import {E_Auction} from "src/E_Auction.sol";
import {Script} from "lib/forge-std /src/Script.sol";
import {NFT} from "src/NFT.sol";
import { NFTDeployer} from "src/nftDeployer.sol";
import {NftMarketPlace} from "src/nftMarketPlace.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {ERC721Mock} from "lib/openzeppelin-contracts/contracts/mocks/ERC721Mock.sol";
import {console} from "lib/forge-std /src/console.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";


contract nftMarketPlaceTest is Test {

    deployScript deployer;
    NftMarketPlace nftMarketPlace;
    address USER1 =  makeAddr("USER1");
    address  USER2 = makeAddr("USER2");
    uint256 TOKEN_ID = 5;
    uint256 TOKEN_PRICE = 6 ether;
    uint256 NEW_TOKEN_PRICE = 5 ether;
    ERC20Mock usdt;
    ERC721Mock ajdNft;

  
    
    function setUp() public {
        deployer = new deployScript();
        (,,,nftMarketPlace) = deployer.run();
          usdt = new ERC20Mock("USDT","USDT",USER2,10E18);
          ajdNft = new ERC721Mock("AJDNFT","AJDNFT");
         ajdNft.mint(USER1,TOKEN_ID);
         vm.startPrank(USER1);
         ERC721(ajdNft).approve(address(nftMarketPlace),TOKEN_ID);
         vm.stopPrank();
         vm.startPrank(USER2);
         ERC20(usdt).approve(address(nftMarketPlace),TOKEN_PRICE);
         vm.stopPrank();
         console.log(ERC20(usdt).balanceOf(USER2));
    }

    function testDeployerIsAdmin() public view {
        address deployerAddress = nftMarketPlace.returnDeployer();
        assertEq(true,nftMarketPlace.checkIsAddressAdmin(deployerAddress));
    }

    function testSellNftWorks() public  {
        vm.startPrank(USER1);
        nftMarketPlace.sellNft(address(ajdNft),TOKEN_ID,TOKEN_PRICE,address(usdt));
        assertEq(ERC721(ajdNft).ownerOf(TOKEN_ID),address(nftMarketPlace));
        assertEq(false,nftMarketPlace.checkIfTokenWithSaleIdIsStillListed(0));
    }

    function testBuyNftWorks() public {
        vm.startPrank(USER1);
        nftMarketPlace.sellNft(address(ajdNft),TOKEN_ID,TOKEN_PRICE,address(usdt));
        vm.stopPrank();
        vm.startPrank(USER2);
        nftMarketPlace.buyNft(0);
        assertEq(true,nftMarketPlace.checkIfTokenWithSaleIdIsStillListed(0));
        assertEq(ERC20(usdt).balanceOf(USER2),10e18 - TOKEN_PRICE);
        assertEq(ERC721(ajdNft).ownerOf(TOKEN_ID),USER2);
        console.log(ERC20(usdt).balanceOf(address(nftMarketPlace)));
    }


    function testChangeNftPriceRevertsWithInvalidCaller() public {
        vm.startPrank(USER1);
        nftMarketPlace.sellNft(address(ajdNft),TOKEN_ID,TOKEN_PRICE,address(usdt));
        vm.stopPrank();
        vm.startPrank(USER2);
        vm.expectRevert(NftMarketPlace.onlyNftOwnerCanCallThisFunction.selector);
        nftMarketPlace.changeNftPrice(0,NEW_TOKEN_PRICE,address(usdt));
    }

    function testchangeNftPriceRevertsWhenNftHasBeenSold() public {
        vm.startPrank(USER1);
        nftMarketPlace.sellNft(address(ajdNft),TOKEN_ID,TOKEN_PRICE,address(usdt));
        vm.stopPrank();
        vm.startPrank(USER2);
        nftMarketPlace.buyNft(0);
        vm.stopPrank();
        vm.startPrank(USER1);
        vm.expectRevert(NftMarketPlace.youCannotChangeThePriceOfNftSinceItHasBeenSold.selector);
        nftMarketPlace.changeNftPrice(0,NEW_TOKEN_PRICE,address(usdt));
    }

    function testChangeNftPriceWorksWell() public {
        vm.startPrank(USER1);
        nftMarketPlace.sellNft(address(ajdNft),TOKEN_ID,TOKEN_PRICE,address(usdt));
        nftMarketPlace.changeNftPrice(0,NEW_TOKEN_PRICE,address(usdt));
       nftMarketPlace.nftDetails memory returnedStruct = nftMarketPlace.returnSaleIdDetails(0);


    }
    
}
