//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {deployScript} from "script/deployerScript.script.sol";
import {E_Auction} from "src/E_Auction.sol";
import {Test} from "lib/forge-std /src/Test.sol";
import {NFT} from "src/NFT.sol";
import { NFTDeployer} from "src/nftDeployer.sol";

contract nftTest is Test {

deployScript deployer;
NFT nft;
address nftDeployer;

function setUp() public {
(,nft,)= deployer.run();
nftDeployer = nft.returnNftOwner();
}

function testDeployerIsContractOwner() public view {
    
    assertEq(nft.checkIsDeployer(nftDeployer),true);
}


}