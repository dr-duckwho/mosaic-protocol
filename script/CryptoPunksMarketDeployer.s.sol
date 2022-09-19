// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {DeployByteCode} from "../src/util/DeployByteCode.sol";
import {CryptoPunksMarket} from "../src/external/CryptoPunksMarket.sol";

contract CryptoPunksMarketDeployer is Script {
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("LOCAL_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        CryptoPunksMarket market = CryptoPunksMarket(address(0x5FbDB2315678afecb367f032d93F642f64180aa3));
        console.log(market.imageHash());
        vm.stopBroadcast();
    }
}
