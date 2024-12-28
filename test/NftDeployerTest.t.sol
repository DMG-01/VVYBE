//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


import {Test} from "lib/forge-std /src/Test.sol";
import {deployScript} from "script/deployerScript.script.sol";
import {NFT} from "src/NFT.sol";
import { NFTDeployer} from "src/nftDeployer.sol";
import {E_Auction} from "src/E_Auction.sol";
import {console} from "lib/forge-std /src/console.sol";


contract NftDeployerTest is Test {

deployScript deployer;
NFTDeployer nftDeployer;
address USER1 =  makeAddr("USER1");
string NFT_NAME = "USER1_NFT";
string NFT_SYMBOL = "U_1_N";
NFT NFT_ADDRESS;


modifier user1DeploysNFT {
vm.startPrank(USER1);
NFT_ADDRESS = nftDeployer.createNftCollection(NFT_NAME,NFT_SYMBOL);
_;
}

function setUp() public {
    deployer = new deployScript();
    (,,nftDeployer) = deployer.run();
    console.log("nft deployer contract has been deployed");
}

function testCreateNftCollectionWorks() public {
    vm.startPrank(USER1);
    NFT_ADDRESS = nftDeployer.createNftCollection(NFT_NAME,NFT_SYMBOL);
    assertEq(USER1,NFT_ADDRESS.returnNftOwner());
}




}
