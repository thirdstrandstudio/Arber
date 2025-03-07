// scripts/DeployArberUpgradeable.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {ArberUpgradeable} from "../src/ArberUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployArberUpgradeable is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory routers = new address[](2);
        routers[0] = address("0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff"); // Replace with actual router addresses
        routers[1] = address("0xedf6066a2b290C185783862C7F4776A2C8077AD1"); // Replace with actual router addresses

        // Deploy the implementation
        ArberUpgradeable arberImpl = new ArberUpgradeable();

        // Encode initializer data
        bytes memory initData = abi.encodeWithSelector(
            ArberUpgradeable.initialize.selector,
            routers
        );

        // Deploy proxy and initialize
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(arberImpl),
            initData
        );

        ArberUpgradeable arber = ArberUpgradeable(address(proxy));

        console.log("ArberUpgradeable deployed at:", address(arber));
        console.log("Implementation deployed at:", address(arberImpl));

        vm.stopBroadcast();
    }
}
