// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "../src/ArberUpgradeable.sol"; // adjust the import path as needed

contract AddRouter is Script {
    function run() external {
        // Load private key and addresses from environment variables
        uint256 pk = vm.envUint("PRIVATE_KEY");
        //address token0 = vm.envAddress("TOKEN0_ADDRESS");
        //address token1 = vm.envAddress("TOKEN1_ADDRESS");
        address arberAddress = vm.envAddress("ARBER_ADDRESS");

        // Cast the deployed ArberUpgradeable contract
        ArberUpgradeable arber = ArberUpgradeable(arberAddress);

        vm.startBroadcast(pk);

        arber.addRouter(); //btcb
        //arber.addTokenPair(busd, 0x2170Ed0880ac9A755fd29B2688956BD959F933F8); //eth
        //arber.addTokenPair(busd, 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47); //eth
        arber.addRouter(0x55d398326f99059fF775485246999027B3197955); //wbnb

        vm.stopBroadcast();
    }
}
