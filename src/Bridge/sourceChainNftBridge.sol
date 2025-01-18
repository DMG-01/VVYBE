//SPDX-license-Identifier 
pragma solidity pragma solidity 0.8.13;
import {IRouterClient} from "lib/chainlink-develop/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";


contract sourceChainNftBridge  {

    IRouterClient public routerClient;

    /*******ERRORS */
    error notErc721Token(address tokenAddress);

    constructor(IRouterClient _routerClient) {
        routerClient = _routerClient;
    }
    function sendNftToDestChain(uint64 destChainSelector, bytes calldata receiver, bytes calldata data, address nftToken, uint256 tokenId) external {
        
        bool isErc721 = isErc721(nftToken);

        if(!isErc721) {
            revert notErc721Token(nftToken);
        }
        // add a logic for the token URI
        // Construct the message to be sent to the destination chain.
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

    function isERC721(address token) internal pure returns (bool) {
        return token.supportsInterface(0x80ac58cd);
    }
}