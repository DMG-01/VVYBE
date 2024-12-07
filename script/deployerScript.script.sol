//SPDX-License-Identifier:MIT

pragma solidity ^ 0.8.13;
import {E_Auction} from "src/E_Auction.sol";
import {Script} from "lib/forge-std /src/Script.sol";

contract deployScript is Script {
    E_Auction e_auction;

    function run() external returns(E_Auction) {
        vm.startBroadcast();
        e_auction = new E_Auction();
        vm.stopBroadcast();
        return e_auction;

    }
}