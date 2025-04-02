// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "../src/ArberUpgradeable.sol"; // adjust the import path as needed

contract AddRouter is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address arberAddress = vm.envAddress("ARBER_ADDRESS");
        address router = vm.envAddress("ROUTER_ADDRESS");

        // Cast the deployed ArberUpgradeable contract
        ArberUpgradeable arber = ArberUpgradeable(arberAddress);
        vm.startBroadcast(pk);
        arber.addRouter(router);
        vm.stopBroadcast();
    }
}
