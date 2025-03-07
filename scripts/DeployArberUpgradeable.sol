// scripts/DeployArberUpgradeable.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {ArberUpgradeable} from "../src/ArberUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployArberUpgradeable is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address wethAddress = vm.envAddress("WETH");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory routers = new address[](6);
        routers[0] = address(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Pancake swap v2 router
        routers[1] = address(0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24); // Uniswap v2 router
        routers[2] = address(0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7); // Apwswap v2 router
        routers[3] = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Jup v2 router
        routers[4] = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // Sushiswap v2 router
        routers[5] = address(0x10ed43c718714eb63d5aa57b78b54704e256024e); // Pinkswap

        // Deploy the implementation
        ArberUpgradeable arberImpl = new ArberUpgradeable();

        // Encode initializer data
        bytes memory initData = abi.encodeWithSelector(
            ArberUpgradeable.initialize.selector,
            routers,
            wethAddress
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
