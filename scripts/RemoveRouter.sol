// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "../src/ArberUpgradeable.sol"; // adjust the import path as needed

contract RemoveRouter is Script {
    function run() external {
        // Load private key and addresses from environment variables
        uint256 pk = vm.envUint("PRIVATE_KEY");
        //address token0 = vm.envAddress("TOKEN0_ADDRESS");
        //address token1 = vm.envAddress("TOKEN1_ADDRESS");
        address arberAddress = vm.envAddress("ARBER_ADDRESS");

        // Cast the deployed ArberUpgradeable contract
        ArberUpgradeable arber = ArberUpgradeable(arberAddress);

        vm.startBroadcast(pk);
        arber.removeRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        vm.stopBroadcast();
    }
}
