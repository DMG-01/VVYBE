//SPDX-License-Identifier: MIT
pragma solidity  0.8.13;

import {IRouterClient} from "lib/chainlink-develop/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {BurnerAddress} from "src/Bridge/burnerAddress.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {Client} from "lib/chainlink-develop/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC165} from "lib/openzeppelin-contracts/contracts/interfaces/IERC165.sol";

contract sourceChainNftBridge  {

    IRouterClient public routerClient;
    BurnerAddress public burnerAddress;

    /*******ERRORS */
    error notErc721Token(address tokenAddress);

    constructor(IRouterClient _routerClient) {
        routerClient = _routerClient;
    }
    function sendNftToDestChain(uint64 destChainSelector,address receiverAddress,  bytes calldata receiver, address nftToken, uint256 tokenId) external {
        
        bool isErc721 = isERC721(nftToken);

        if(!isErc721) {
            revert notErc721Token(nftToken);
        }

        string memory tokenUri = IERC721Metadata(nftToken).tokenURI(tokenId);
        

        
         IERC721(nftToken).transferFrom(msg.sender, address(this), tokenId);
         IERC721(nftToken).approve(address(burnerAddress), tokenId);
         IERC721(nftToken).transferFrom(address(this),address(burnerAddress),tokenId);
       
       uint64 sourceChainId = returnChainId();
       uint64 destinationChainId = getContractChainId(address(receiverAddress)); 
        
         string memory jsonAddTokenUri = string(
    abi.encodePacked(
        "{",
        '"sourceChainId": "', Strings.toString(sourceChainId), '", ',
        '"destinationChainId": "', Strings.toString(destinationChainId), '"',
        "}"
    )
         );

    string memory newTokenUri = string(abi.encodePacked(tokenUri,jsonAddTokenUri));
    bytes memory data = bytes(newTokenUri);



        
        
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: receiver,
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](1),
            feeToken: address(0),
            extraArgs: abi.encodeWithSelector(Client.EVM_EXTRA_ARGS_V1_TAG, Client.EVMExtraArgsV1({gasLimit: 200000}))
        });

        // Set the token amount to be transferred.
        message.tokenAmounts[0] = Client.EVMTokenAmount({
            token: nftToken,
            amount: tokenId
        });

        // Send the message to the destination chain.
        routerClient.ccipSend(destChainSelector, message);
    }

    function isERC721(address token) internal view returns (bool) {
        return IERC165(token).supportsInterface(0x80ac58cd);
    }

    function returnChainId()  public view returns(uint64) {
        uint64 chainId;

        assembly {
            chainId := chainid()
        }

        return chainId;
    }

    function getContractChainId(address contractAddress) public view returns(uint64){
        uint64 contractChainId;

        assembly {
            contractChainId := extcodehash(contractAddress)
        }
        return contractChainId;
    }
}