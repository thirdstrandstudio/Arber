// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "../src/ArberUpgradeable.sol"; // adjust the import path as needed

contract AddTokenPair is Script {
    function run() external {
        // Load private key and addresses from environment variables
        uint256 pk = vm.envUint("PRIVATE_KEY");
        //address token0 = vm.envAddress("TOKEN0_ADDRESS");
        //address token1 = vm.envAddress("TOKEN1_ADDRESS");
        address arberAddress = vm.envAddress("ARBER_ADDRESS");

        // Cast the deployed ArberUpgradeable contract
        ArberUpgradeable arber = ArberUpgradeable(arberAddress);

        vm.startBroadcast(pk);


        // Call addTokenPair to add a new token pair
        arber.addTokenPair(0xc2132D05D31c914a87C6611C10748AEb04B58e8F, 0xD6DF932A45C0f255f85145f286eA0b292B21C90B);



        vm.stopBroadcast();
    }
}
