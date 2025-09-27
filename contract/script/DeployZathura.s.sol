// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ZathuraCore.sol";

contract DeployZathura is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address oneInchRouter = vm.envAddress("ONE_INCH_ROUTER");
        address weth = vm.envAddress("WETH");

        vm.startBroadcast(deployerPrivateKey);

        ZathuraCore zathura = new ZathuraCore(oneInchRouter, weth);

        console.log("ZathuraCore deployed at:", address(zathura));
        console.log("1inch Router:", oneInchRouter);
        console.log("WETH:", weth);

        vm.stopBroadcast();
    }
}
