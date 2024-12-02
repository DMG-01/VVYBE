//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Test} from "lib/forge-std /src/Test.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {ERC721Mock} from "lib/openzeppelin-contracts/contracts/mocks/ERC721Mock.sol";
import {E_Auction} from "src/E_Auction.sol";
import {deployScript} from "script/deployerScript.script.sol";
import {console} from "lib/forge-std /src/console.sol";

contract E_AuctionTest is Test {

    E_Auction e_auction;
    deployScript deployer;
    ERC20Mock usdt;
    ERC721Mock ajdNft;
    address USER1 = makeAddr("USER1");
    address USER2 = makeAddr("USER2");
    uint256 AUCTION_TIME_PERIOD = 100;
    address ERC721_TOKEN_ADDRESS;
    uint256 ERC721_STARTING_AMOUNT = 5 ether;
    uint256 ERC721_TOKEN_ID = 1;
    address ERC20_TOKEN_ADDRESS;


    function setUp() public {
    console.log("Starting setUp...");
    e_auction = new E_Auction();

    console.log("E_Auction deployed");

    usdt = new ERC20Mock("USDT", "USDT", address(this), 1000e18);
    console.log("ERC20Mock deployed");

    ajdNft = new ERC721Mock("anjolaDaveNFT", "AJDNFT");
    console.log("ERC721Mock deployed");

    ajdNft.mint(USER1, ERC721_TOKEN_ID);
    console.log("ERC721 Token minted");
    
    ERC721_TOKEN_ADDRESS = address(ajdNft);
    ERC20_TOKEN_ADDRESS = address(usdt);
}


    function testCreateAuctionFailsWithErc20Token() public {
        vm.startPrank(USER1);
        vm.expectRevert();
        e_auction.createAuction(AUCTION_TIME_PERIOD,address(usdt),ERC721_STARTING_AMOUNT,ERC721_TOKEN_ID,address(usdt));
    }
}