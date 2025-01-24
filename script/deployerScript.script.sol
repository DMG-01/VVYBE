//SPDX-License-Identifier:MIT

pragma solidity ^ 0.8.13;
import {E_Auction} from "src/E_Auction.sol";
import {Script} from "lib/forge-std /src/Script.sol";
import {NFT} from "src/NFT.sol";
import { NFTDeployer} from "src/nftDeployer.sol";
import {NftMarketPlace} from "src/nftMarketPlace.sol";
import {BridgedNft} from "src/Bridge/bridgedNFT.sol";
import {BurnerAddress} from "src/Bridge/burnerAddress.sol";
//import {NftBridgeReceiverContract} from "src/Bridge/receiverContract.sol";
//import {sourceChainNftBridge} from "src/Bridge/sourceChainNftBridge.sol";

//import 


contract deployScript is Script {

    function run() external returns(E_Auction,NFT,NFTDeployer,NftMarketPlace,BridgedNft,BurnerAddress) {
        vm.startBroadcast();
       E_Auction e_auction = new E_Auction();
       NFT nft = new NFT("MIMI","MIMI",msg.sender);
       NFTDeployer nftDeployer = new NFTDeployer(); 
       NftMarketPlace nftMarketPlace = new NftMarketPlace();
       BridgedNft bridgedNft = new BridgedNft("vvybe","vvybe",msg.sender);
       BurnerAddress burnerAddress = new BurnerAddress();
        vm.stopBroadcast();
        return (e_auction,nft,nftDeployer,nftMarketPlace,bridgedNft,burnerAddress);


    }
}