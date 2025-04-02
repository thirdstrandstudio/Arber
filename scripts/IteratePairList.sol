// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "../src/ArberUpgradeable.sol"; // adjust the import path as needed
import {IArberUpgradeable} from "../src/IArberUpgradeable.sol";

contract IteratePairList is Script {
    function run() external {
        // Load private key and addresses from environment variables
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address arberAddress = vm.envAddress("ARBER_ADDRESS");

        // Cast the deployed ArberUpgradeable contract
        ArberUpgradeable arber = ArberUpgradeable(arberAddress);
        
        
        vm.startBroadcast(pk);
                
        IArberUpgradeable.IteratePairListInput memory iteratePairListInput = arber.shouldIteratePairList(0, 11, 1000000 gwei, 0, 100);


        //Checks if contract will make a profit before iterating
        if(iteratePairListInput.shouldIterate) {
            arber.iteratePairList(iteratePairListInput.start, 1, iteratePairListInput.amountIn, iteratePairListInput.slippageTolerance, iteratePairListInput.gasUsed, false);
        }
        vm.stopBroadcast();
    }
}
