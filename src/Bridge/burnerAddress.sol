//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";


contract BurnerAddress is IERC721Receiver {
    
    constructor() {
        ADMIN = msg.sender;
    }
     
     address ADMIN;

     function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external override pure  returns (bytes4) {
        // Optionally handle the received token (e.g., store info)
        return this.onERC721Received.selector; // Required confirmation
    }
}