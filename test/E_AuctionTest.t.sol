//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Test} from "lib/forge-std /src/Test.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/ERC20Mock.sol";
import {ERC721Mock} from "lib/openzeppelin-contracts/contracts/mocks/ERC721Mock.sol";
import {E_Auction} from "src/E_Auction.sol";
import {deployScript} from "script/deployerScript.script.sol";

contract E_AuctionTest is Test {

    E_Auction e_auction;
    deployScript deployer;

    function setUp() public {
        e_auction = deployer.run();
    }
}