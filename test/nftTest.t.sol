//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {deployScript} from "script/deployerScript.script.sol";
import {E_Auction} from "src/E_Auction.sol";
import {Test} from "lib/forge-std /src/Test.sol";
import {NFT} from "src/NFT.sol";
import { NFTDeployer} from "src/nftDeployer.sol";
import {console} from "lib/forge-std /src/console.sol";

contract nftTest is Test {

deployScript deployer;
uint256 TOKEN_ID = 1;
NFT nft;
address USER1 = makeAddr("USER1");
address USER2 = makeAddr("USER2");
address nftDeployer;
string[] tokenProperties;
string[] tokenValues;

function setUp() public {

deployer = new deployScript();
(,nft,,)= deployer.run();
nftDeployer = nft.returnNftOwner(); 

tokenProperties.push("name");
tokenValues.push("myNft");

tokenProperties.push("price");
tokenValues.push("5 ether");
console.log(nftDeployer);
console.log(nft.returnNftOwner());
}

function testDeployerIsContractOwner() public view {
    
    assertEq(nft.checkIsDeployer(nftDeployer),true);
}

function testMintNewNftFunctionRevertsWhenCalledByNonOwner() public  {
    vm.startPrank(USER1);
    vm.expectRevert(NFT.onlyOwnerCanCallThisFunction.selector);
    nft.mintNewNft(USER2,tokenProperties,tokenValues,TOKEN_ID);
}

function testmintNewNftRevetsWithUnequalPropertiesAndValueLength() public {
tokenProperties.push("age");
vm.startPrank(nftDeployer);
vm.expectRevert(abi.encodeWithSelector((NFT.tokenPropertiesIsNotEqualToTokenLength.selector),tokenProperties.length,tokenValues.length));
nft.mintNewNft(USER2,tokenProperties,tokenValues,TOKEN_ID);

}

function testMintTokenWorks() public {   
    vm.startPrank(nftDeployer);
   (,string  memory tokenUri)= nft.mintNewNft(USER2,tokenProperties,tokenValues,TOKEN_ID);
    assertEq(nft.ownerOf(TOKEN_ID),USER2);
    assertEq(tokenUri,nft.tokenURI(TOKEN_ID));
}




}