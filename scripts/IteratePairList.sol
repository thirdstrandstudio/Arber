// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "../src/ArberUpgradeable.sol"; // adjust the import path as needed

contract IteratePairList is Script {
    function run() external {
        // Load private key and addresses from environment variables
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address arberAddress = vm.envAddress("ARBER_ADDRESS");

        // Cast the deployed ArberUpgradeable contract
        ArberUpgradeable arber = ArberUpgradeable(arberAddress);
        
        
        vm.startBroadcast(pk);

        if(arber.shouldIteratePairList(0, 4, 1 * (10 ^ 5), 5, 1000)) {
            arber.iteratePairList(0, 4, 1 * (10 ^ 5), 5, 1000, false);
        }
        vm.stopBroadcast();
    }
}
