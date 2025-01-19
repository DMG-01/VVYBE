//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;  

import {Test} from "lib/forge-std /src/Test.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {ERC721Mock} from "lib/openzeppelin-contracts/contracts/mocks/ERC721Mock.sol";
import {E_Auction} from "src/E_Auction.sol";
import {deployScript} from "script/deployerScript.script.sol";
import {console} from "lib/forge-std /src/console.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract E_AuctionTest is Test {

    E_Auction e_auction;
    deployScript deployer;
    ERC20Mock usdt;
    ERC721Mock ajdNft;
    address USER1 = makeAddr("USER1");
    address USER2 = makeAddr("USER2");
    address USER3 = makeAddr("USER3");
    address USER4 = makeAddr("USER4");
    uint256 AUCTION_TIME_PERIOD = 100;
    address ERC721_TOKEN_ADDRESS;
    uint256 ERC721_STARTING_AMOUNT = 5 ether;
    uint256 ERC20_STARTING_BALANCE = 7 ether;
    uint256 ERC20_LOWER_BID = 3 ether;
    uint256 ERC721_TOKEN_ID = 1;
    address ERC20_TOKEN_ADDRESS;


    function setUp() public {
    console.log("Starting setUp...");
    //e_auction = new E_Auction();
    deployer = new deployScript();
    (e_auction,,,) = deployer.run(); 

    console.log("E_Auction deployed");

    usdt = new ERC20Mock("USDT", "USDT", address(this), 1000e18);
    console.log("ERC20Mock deployed");

    usdt.mint(USER2,ERC20_STARTING_BALANCE);
    usdt.mint(USER4,ERC20_STARTING_BALANCE);

    ajdNft = new ERC721Mock("anjolaDaveNFT", "AJDNFT");
    console.log("ERC721Mock deployed");

    ajdNft.mint(USER1, ERC721_TOKEN_ID);
    console.log("ERC721 Token minted");
    
   
    ERC721_TOKEN_ADDRESS = address(ajdNft);
    ERC20_TOKEN_ADDRESS = address(usdt);
}

modifier ERC20AuctionCreated {
vm.startPrank(USER1);
         ERC721(ajdNft).approve(address(e_auction),ERC721_TOKEN_ID);
        e_auction.createAuctionWithErc20Token(AUCTION_TIME_PERIOD,address(ajdNft),ERC721_STARTING_AMOUNT,ERC721_TOKEN_ID,address(usdt));
        
        _;
}

modifier NativeEtherAuctionCreated  {
    vm.startPrank(USER1);
    ERC721(ajdNft).approve(address(e_auction),ERC721_TOKEN_ID);
    e_auction.createAuctionWithNativeEther(AUCTION_TIME_PERIOD,address(ajdNft),ERC721_STARTING_AMOUNT,ERC721_TOKEN_ID);
    vm.stopPrank();
    _;
}

     function testClaimAuctionWorks() public ERC20AuctionCreated   {
        vm.startPrank(USER2);
        usdt.approve(address(e_auction), ERC20_STARTING_BALANCE);
        
        e_auction.makeABidWithERC20Token(0, ERC20_STARTING_BALANCE);
        vm.warp(block.timestamp + AUCTION_TIME_PERIOD + 2);
      
        //vm.startPrank(address(e_auction));
        
       // vm.stopPrank();
        //vm.startPrank(USER2);
        e_auction.claimAuction(0);
        

        assertEq(ERC20_STARTING_BALANCE,ERC20(usdt).balanceOf(USER1));
        console.log(ERC20(usdt).balanceOf(USER1));
    }


    function testCreateAuctionFailsWithErc20Token() public {
        vm.startPrank(USER1);
        ERC20(usdt).approve(address(e_auction),ERC20_STARTING_BALANCE);
        vm.expectRevert(abi.encodeWithSelector((E_Auction.tokenIsNotERC721.selector),address(usdt)));
        e_auction.createAuctionWithErc20Token(AUCTION_TIME_PERIOD,address(usdt),ERC721_STARTING_AMOUNT,ERC721_TOKEN_ID,address(usdt));
    }

    function testCreateAuctionWithNativeEtherFailsWithErc20Token() public {
        vm.startPrank(USER1);
        ERC20(usdt).approve(address(e_auction),ERC20_STARTING_BALANCE);
        vm.expectRevert(abi.encodeWithSelector((E_Auction.tokenIsNotERC721.selector),address(usdt)));
        e_auction.createAuctionWithNativeEther(AUCTION_TIME_PERIOD,address(usdt),ERC721_STARTING_AMOUNT,ERC721_TOKEN_ID);
    }

    function testMakeABidRevertsWhenAuctionIsCreatedWithNativeEtherAndBidIsPlacedWithERC20Token() NativeEtherAuctionCreated public {
        vm.startPrank(USER2);
        ERC20(usdt).approve(address(e_auction),ERC20_STARTING_BALANCE);
        vm.expectRevert(E_Auction.youCannotBidWithErc20Token.selector);
        e_auction.makeABidWithERC20Token(0,ERC20_STARTING_BALANCE);
    }

    function testMakeABidWithNativeEtherRevertsWhenAuctionIsCreatedWithErc20Token() ERC20AuctionCreated public {
        vm.startPrank(USER2);
        vm.expectRevert(abi.encodeWithSelector((E_Auction.invalidMethodOfPayment.selector),ERC20_TOKEN_ADDRESS));
        e_auction.makeABidWithNativeEther(0);
    }

 

    function testCreateAuctionWorks() ERC20AuctionCreated public {
        
        assertEq(1,e_auction.returnAuctionCount());
        assertEq(address(e_auction), ERC721(ajdNft).ownerOf(ERC721_TOKEN_ID));
    }

    function testMakeABidRevertsWhenAuctionIsClosed() public ERC20AuctionCreated {
      vm.warp(block.timestamp + AUCTION_TIME_PERIOD + 5);
       vm.startPrank(USER2);
       usdt.approve(address(e_auction), ERC20_STARTING_BALANCE);
       vm.expectRevert(abi.encodeWithSelector((E_Auction.bidHasClosed.selector),AUCTION_TIME_PERIOD+1));
       e_auction.makeABidWithERC20Token(0,ERC20_STARTING_BALANCE);
    }

    function testMakeASuccessfulBid() public ERC20AuctionCreated {
        
        vm.startPrank(USER2);

        usdt.approve(address(e_auction), ERC20_STARTING_BALANCE);

        e_auction.makeABidWithERC20Token(0, ERC20_STARTING_BALANCE);

        
        (bool isOpen, ) = e_auction.isAuctionOpen(0);
        assertTrue(isOpen, "Auction should still be open");

        E_Auction.TokenAuctionDetails memory auctionDetails = e_auction.getAuctionDetails(0);

        assertEq(auctionDetails.currentHighestBid, ERC20_STARTING_BALANCE, "Current highest bid should match the bid placed");
        assertEq(auctionDetails.currentHighestBidder, USER2, "Current highest bidder should be USER2");
    }

    function testmakeABidRevertsWithLowerBid() public ERC20AuctionCreated {
        vm.startPrank(USER2);
        ERC20(usdt).approve(address(e_auction),ERC20_LOWER_BID);
        vm.expectRevert(abi.encodeWithSelector((E_Auction.bidPlacedIsLessThanTheStartingAmount.selector),ERC20_LOWER_BID,ERC721_STARTING_AMOUNT));
        e_auction.makeABidWithERC20Token(0,ERC20_LOWER_BID);
    }
    

    function testClaimAuctionRevertsWhenAuctionIsStillOpened() public ERC20AuctionCreated{
        vm.startPrank(USER2);
        usdt.approve(address(e_auction), ERC20_STARTING_BALANCE);
        e_auction.makeABidWithERC20Token(0, ERC20_STARTING_BALANCE);
        vm.expectRevert(abi.encodeWithSelector((E_Auction.auctionIsNotOver.selector),AUCTION_TIME_PERIOD ));
        e_auction.claimAuction(0);
    }

    function testClaimAuctionRevertsWithInvalidCaller() public ERC20AuctionCreated  {
        vm.startPrank(USER2);
        usdt.approve(address(e_auction), ERC20_STARTING_BALANCE);
        e_auction.makeABidWithERC20Token(0, ERC20_STARTING_BALANCE);
        vm.stopPrank();
        vm.startPrank(USER3);
        vm.warp(AUCTION_TIME_PERIOD + 2);
        vm.expectRevert(E_Auction.youCannotCallThisFunction.selector);
        e_auction.claimAuction(0);
    }


   

    function testWhenNoOneBuysTheToken() public ERC20AuctionCreated{
        vm.warp(block.timestamp + AUCTION_TIME_PERIOD + 2);
        address ownerOf = e_auction.ownerOf(address(ajdNft),ERC721_TOKEN_ID);
        console.log(ownerOf);
        vm.startPrank(USER1);
        e_auction.claimAuction(0);
        address ownerOfII = e_auction.ownerOf(address(ajdNft),ERC721_TOKEN_ID);
        console.log(ownerOfII);

    }

    function testPreviousBidderTokenIsReturned() public ERC20AuctionCreated{
        vm.startPrank(USER2);
        ERC20(usdt).approve(address(e_auction),ERC721_STARTING_AMOUNT);
        e_auction.makeABidWithERC20Token(0,ERC721_STARTING_AMOUNT);
        uint256 user2BalanceAfterBid = ERC20(usdt).balanceOf(USER2);
        assertEq(ERC20_STARTING_BALANCE - ERC721_STARTING_AMOUNT,user2BalanceAfterBid);
        vm.stopPrank();
        vm.startPrank(USER4);
        ERC20(usdt).approve(address(e_auction),ERC20_STARTING_BALANCE);
        e_auction.makeABidWithERC20Token(0,ERC20_STARTING_BALANCE);
        uint256 user4BalanceAfterBid = ERC20(usdt).balanceOf(USER4);
        assertEq(0,user4BalanceAfterBid);
        assertEq(ERC20_STARTING_BALANCE,ERC20(usdt).balanceOf(address(e_auction)));
        uint256 user2BalanceAfterUser4Bid = ERC20(usdt).balanceOf(USER2);
        assertEq(user2BalanceAfterBid + ERC721_STARTING_AMOUNT,user2BalanceAfterUser4Bid);



    }


    function testAddAdmin() public {
        address contractDeployer = e_auction.returnInitialDeloyer();
        vm.startPrank(contractDeployer);
        e_auction.addAdmin(USER3);
        assertEq(true,e_auction.checkIsAdmin(USER3));
    }

    function testRemoveAdmin() public {
       address contractDeployer = e_auction.returnInitialDeloyer();
        vm.startPrank(contractDeployer);
        e_auction.addAdmin(USER3);
        assertEq(true,e_auction.checkIsAdmin(USER3));
        e_auction.removeAdmin(USER3);
        assertEq(false,e_auction.checkIsAdmin(USER3));
    }

    function testRemoveInitialDeployerAsAdminReverts() public {
        address contractDeployer = e_auction.returnInitialDeloyer();
        vm.startPrank(contractDeployer);
        e_auction.addAdmin(USER3);
        vm.stopPrank();
        vm.startPrank(USER3);
        vm.expectRevert(E_Auction.youCannotRemoveInitialDeployerFromAdmin.selector);
        e_auction.removeAdmin(contractDeployer);
    } 

    function testOnlyAdminCanCallSpecificFunction() public {
        vm.startPrank(USER3);
        vm.expectRevert(E_Auction.onlyAdminCanCallThisFunction.selector);
        e_auction.addAdmin(USER2);
    }
    //test previousBidder money gets transferedBack




}