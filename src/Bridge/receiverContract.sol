// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {NFT} from "src/NFT.sol";
import {CCIPReceiver} from "lib/chainlink-develop/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {NFTDeployer} from "src/nftDeployer.sol";
import {Client} from "lib/chainlink-develop/contracts/src/v0.8/ccip/libraries/Client.sol";
import {BridgedNft} from "src/Bridge/bridgedNFT.sol";

contract NftBridgeReceiverContract is CCIPReceiver {
    address public i_routerAddress;
    string tokenInitials = "BV";
    string tokenNameInitials = "brigedVybe";

    mapping(address => bool) isMinted;
    mapping(address => address) addressSourceChainToDestinationChain;

    /**********ERRORS */
    error invalidCaller();

    constructor(address routerAddress) CCIPReceiver(routerAddress) {
        i_routerAddress = routerAddress;
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        if (msg.sender != i_routerAddress) {
            revert invalidCaller();
        }


        // Decode receiver address, token URI, and token ID
        address receiver = abi.decode(message.sender, (address));
        (string memory uri, address nftToken,uint256 tokenId,string tokenName, string tokenSymbol) = abi.decode(message.data,(string,address,uint256,string,string));
        
            
         if(isMinted[nftToken]) {
           address tokenDestinationAddress = addressSourceChainToDestinationChain[nftToken];
           BridgedNft(tokenDestinationAddress).mint(receiver,uri,tokenId);
         } else {
            isMinted[nftToken] = true;
            string tokenNewName = abi.encodePacked(tokenNameInitials,tokenName);
            string newTokenSymbol = abi.encodePacked(tokenInitials,tokenSymbol);
            BridgedNft newBridgedNft = new BridgedNft(tokenNewName,tokenNewSymbol,address(this));
            addressSourceChainToDestinationChain[nftToken] = newBridgedNft;
         }

        // Mint the NFT
        BridgedNft nft = BridgedNft;
        nft.mint(receiver, uri, tokenId);
    }
}
