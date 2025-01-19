// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {NFT} from "src/NFT.sol";
import {CCIPReceiver} from "lib/chainlink-develop/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {NFTDeployer} from "src/nftDeployer.sol";
import {Client} from "lib/chainlink-develop/contracts/src/v0.8/ccip/libraries/Client.sol";

contract NftBridgeReceiverContract is CCIPReceiver {
    address public i_routerAddress;
    NFT public nftAddressDeployer;
    address nftDeployer;

    /**********ERRORS */
    error invalidCaller();

    constructor(address routerAddress, address _nftDeployer) CCIPReceiver(routerAddress) {
        i_routerAddress = routerAddress;
        nftDeployer = _nftDeployer;
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        if (msg.sender != i_routerAddress) {
            revert invalidCaller();
        }

        // Decode receiver address, token URI, and token ID
        address receiver = abi.decode(message.sender, (address));
        string memory uri = string(message.data);
       uint256 tokenId = message.destTokenAmounts[0].amount; 


        // Create NFT collection and mint the NFT
       // NFT _nft = NFTDeployer.createNftCollection("WNFT", "WNFT");
    
        // _nft.mintNewNft(receiver, uri, tokenId);
    }
}
