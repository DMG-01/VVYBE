//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {NFT} from "src/NFT.sol";
import {CCIPReceiver} from "lib/chainlink-develop/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {NFTDeployer} from "src/nftDeployer.sol";
import {Client} from "lib/chainlink-develop/contracts/src/v0.8/ccip/libraries/Client.sol";

contract NftBridgeReceiverContract is CCIPReceiver {

address i_routerAddress;
NFT nftAddressDeployer;

/**********ERRORS */
error invalidCaller();

constructor(address routerAddress0) {
i_routerAddress = routerAddress;

}

function onccipReceive(Client.Any2EVMMessage memory message) external {
 if(msg.sender != i_routerAddress) {
    revert invalidCaller();
 }

address receiver = abi.decode(message.receiver, (address));
string uri = string(message.data);
uint256 tokenId = abi.decode(message.tokenAmounts[0].tokenId, (uint256));



}

}
// track in such a way that a person can mint more than one token id with the same smart contract and onn  the destination chain it would be a single smart contract with corresponding token id 
