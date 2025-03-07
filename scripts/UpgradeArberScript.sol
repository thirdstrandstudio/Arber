// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "../src/ArberUpgradeable.sol";

contract UpgradeArberScript is Script {
    function run() external {
        // Read the proxy address and deployer address from environment variables.
        // Set these in your .env file or via your shell environment.
        //  ArberUpgradeable deployed at: 0x1CdF6aAbDCd19D2ED3AC927BB7B9835Ac6942590
        //  Implementation deployed at: 0x2B2f5f350291c9dEb4A49Cc29e47f0E25f905845
        address proxy = vm.envAddress("ARBER_ADDRESS");
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        address wethAddress = vm.envAddress("WETH");

        vm.startBroadcast(deployer);

        // Deploy the new implementation of ArberUpgradeable.
        ArberUpgradeable newImplementation = new ArberUpgradeable();


        address[] memory routers = new address[](2);
        routers[0] = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff); // Replace with actual router addresses
        routers[1] = address(0xedf6066a2b290C185783862C7F4776A2C8077AD1); // Replace with

        // Encode initializer data
        bytes memory initData = abi.encodeWithSelector(
            ArberUpgradeable.initialize.selector,
            routers,
            wethAddress
        );

        // Call upgradeTo on the proxy. Since this is a UUPS proxy, the
        // upgrade function is implemented in the logic contract itself.
        // Make sure that the deployer is the owner of the proxy.
        ArberUpgradeable(proxy).upgradeToAndCall(address(newImplementation), "");

        vm.stopBroadcast();
    }
}
