//SPDX-license-Identifier: MIT

pragma solidity 0.8.13;

import {Test} from "lib/forge-std /src/Test.sol";
import {deployScript} from "script/deployerScript.script.sol";
import {E_Auction} from "src/E_Auction.sol";
import {Script} from "lib/forge-std /src/Script.sol";
import {NFT} from "src/NFT.sol";
import { NFTDeployer} from "src/nftDeployer.sol";
import {NftMarketPlace} from "src/nftMarketPlace.sol";


contract nftMarketPlaceTest is Test {

    deployScript deployer;
    NftMarketPlace nftMarketPlace;

    function setUp() public {
        deployer = new deployScript();
        (,,,nftMarketPlace) = deployer.run();
    }

    function testDeployerIsAdmin() public view {
        address deployerAddress = nftMarketPlace.returnDeployer();
        assertEq(true,nftMarketPlace.checkIsAddressAdmin(deployerAddress));
    }
    
}
