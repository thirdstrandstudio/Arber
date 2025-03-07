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
        address busd = 0x55d398326f99059fF775485246999027B3197955;

        //arber.addTokenPair(busd, 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c); //btcb
        //arber.addTokenPair(busd, 0x2170Ed0880ac9A755fd29B2688956BD959F933F8); //eth
        //arber.addTokenPair(busd, 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47); //eth
        //arber.addTokenPair(0x55d398326f99059fF775485246999027B3197955, 0x87266413e5b64DB72f11bB6795Ee976545DBAf43); //wbnb

        vm.stopBroadcast();
    }
}
