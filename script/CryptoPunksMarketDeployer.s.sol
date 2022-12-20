// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {DeployByteCode} from "../src/util/DeployByteCode.sol";
import {ICryptoPunksMarket} from "../src/external/ICryptoPunksMarket.sol";

contract CryptoPunksMarketDeployer is Script {
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("LOCAL_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        ICryptoPunksMarket market = ICryptoPunksMarket(address(0x5FbDB2315678afecb367f032d93F642f64180aa3));
        console.log(market.imageHash());
        vm.stopBroadcast();
    }
}
