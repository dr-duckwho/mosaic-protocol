// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC721} from "@openzeppelin/token/ERC721/IERC721.sol";

import "forge-std/Script.sol";
import "../src/CryptoPunksGroupRegistry.sol";

contract TicketRegistryScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("LOCAL_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        vm.stopBroadcast();
    }
}
