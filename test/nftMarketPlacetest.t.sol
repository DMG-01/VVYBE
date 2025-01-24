//SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

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
    uint256 NEW_PERCENTAGE_FEE = 2;
    ERC20Mock usdt;
    ERC721Mock ajdNft;

  
    
    function setUp() public {
        deployer = new deployScript();
        (,,,nftMarketPlace,,) = deployer.run();
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
       
    }

    function testRemoveNftFromSaleRevertsWithInvalidCaller() public {
        vm.startPrank(USER1);
        nftMarketPlace.sellNft(address(ajdNft),TOKEN_ID,TOKEN_PRICE,address(usdt));
        vm.stopPrank();
        vm.startPrank(USER2);
        vm.expectRevert(NftMarketPlace.onlyNftOwnerCanCallThisFunction.selector);
        nftMarketPlace.removeNftFromSale(0);
    }

    function testRemoveNftFromSaleRevertsWhenNftHasBeenSold() public {
        vm.startPrank(USER1);
        nftMarketPlace.sellNft(address(ajdNft),TOKEN_ID,TOKEN_PRICE,address(usdt));
        vm.stopPrank();
        vm.startPrank(USER2);
        nftMarketPlace.buyNft(0);
        vm.stopPrank();
        vm.startPrank(USER1);
        vm.expectRevert(NftMarketPlace.youCannotCallThisFunctionSinceNftHasBeenSold.selector);
        nftMarketPlace.removeNftFromSale(0);
    }

    function testRemoveNftFromSaleWorks() public {
        vm.startPrank(USER1);
        nftMarketPlace.sellNft(address(ajdNft),TOKEN_ID,TOKEN_PRICE,address(usdt));
        nftMarketPlace.removeNftFromSale(0);
        assertEq(ERC721(ajdNft).ownerOf(TOKEN_ID),USER1);
    }

    function testChangePercentageFeeRevertsWithInvalidCaller() public {
        vm.startPrank(USER1);
        vm.expectRevert(NftMarketPlace.onlyAdminCanCallThisFunction.selector);
        nftMarketPlace.changePercentageFee(NEW_PERCENTAGE_FEE);
    }

    function testchangePercentageFeeWorks() public {
        address deloyerAddress =  nftMarketPlace.returnDeployer();
        vm.startPrank(deloyerAddress);
         nftMarketPlace.changePercentageFee(NEW_PERCENTAGE_FEE);
         assertEq(NEW_PERCENTAGE_FEE,nftMarketPlace.returnPercentageFee());


    }

    function testAddAdminRevertsWhenCalledByNonAdmin() public {
        vm.startPrank(USER1);
        vm.expectRevert(NftMarketPlace.onlyAdminCanCallThisFunction.selector);
        nftMarketPlace.addAdmin(USER2);
    }

    function testAddAdminWorks() public {
        address deloyerAddress =  nftMarketPlace.returnDeployer();
        vm.startPrank(deloyerAddress);
        nftMarketPlace.addAdmin(USER1);
        assertEq(true,nftMarketPlace.checkIsAddressAdmin(USER1));
    }

    function testRemoveAdminRevertsWhenCalledByNonAdmin() public {
         address deloyerAddress =  nftMarketPlace.returnDeployer();
        vm.startPrank(USER1);
        vm.expectRevert(NftMarketPlace.onlyAdminCanCallThisFunction.selector);
        nftMarketPlace.removeAdmin(deloyerAddress);

    }
    function testRemoveInitialDeployerReverts() public  {
        address deployerAddress =  nftMarketPlace.returnDeployer();
        vm.startPrank(deployerAddress);
        nftMarketPlace.addAdmin(USER1);
        vm.startPrank(USER1);
        vm.expectRevert(NftMarketPlace.youCannotRemoveInitialDeployer.selector);
        nftMarketPlace.removeAdmin(deployerAddress);
    }

    function testRemoveAdminWorks() public {
        address deployerAddress =  nftMarketPlace.returnDeployer();
        vm.startPrank(deployerAddress);
        nftMarketPlace.addAdmin(USER1);
        assertEq(true,nftMarketPlace.checkIsAddressAdmin(USER1));
        nftMarketPlace.removeAdmin(USER1);
        assertEq(false,nftMarketPlace.checkIsAddressAdmin(USER1));
    }
}
