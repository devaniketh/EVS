// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ZathuraLiquidityManager.sol";
import "../src/ZathuraCore.sol";

contract DeployLiquidityManager is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address zathuraCore = vm.envAddress("ZATHURA_CORE");
        address weth = vm.envAddress("WETH");
        address hyperliquidVault = vm.envAddress("HYPERLIQUID_VAULT");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy ZathuraLiquidityManager
        ZathuraLiquidityManager liquidityManager = new ZathuraLiquidityManager(zathuraCore, weth);

        // Configure Hyperliquid integration
        liquidityManager.configureHyperliquid(
            hyperliquidVault,
            5000, // 50% max allocation
            1000 // 10% rebalance threshold
        );

        console.log("ZathuraLiquidityManager deployed at:", address(liquidityManager));
        console.log("ZathuraCore:", zathuraCore);
        console.log("WETH:", weth);
        console.log("Hyperliquid Vault:", hyperliquidVault);

        vm.stopBroadcast();
    }
}
