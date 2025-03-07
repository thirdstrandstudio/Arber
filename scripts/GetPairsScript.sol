// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/ArberUpgradeable.sol";

contract GetPairsScript is Script {
    function run() external {
        // Retrieve the deployed ArberUpgradeable address from env variable
        address arberAddress = vm.envAddress("ARBER_ADDRESS");
        // Set the number of pairs you expect; if you add a getter for pairList length in your contract, use it instead.
        uint256 pairCount = 10;

        // Create an instance of the ArberUpgradeable contract
        ArberUpgradeable arber = ArberUpgradeable(arberAddress);

        console.log("Listing pairs from ArberUpgradeable at:", arberAddress);
        for (uint256 i = 0; i < pairCount; i++) {
            // The auto-generated getter for pairList only returns token0 and token1.
            (address token0, address token1) = arber.pairList(i);

            console.log("-------------------------------------------------");
            console.log("Pair index:", i);
            console.log(" Token0:", token0);
            console.log(" Token1:", token1);
        }
    }
}
