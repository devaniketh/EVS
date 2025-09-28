// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/GameToken.sol";
import "../src/GameVault.sol";
import "../src/SubwaySurfersGame.sol";

/**
 * @title DeployGame
 * @dev Deployment script for the Subway Surfers game contracts
 */
contract DeployGame is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with account:", deployer);
        console.log("Account balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy GameToken
        console.log("Deploying GameToken...");
        GameToken gameToken = new GameToken();
        console.log("GameToken deployed at:", address(gameToken));
        
        // Deploy GameVault
        console.log("Deploying GameVault...");
        GameVault gameVault = new GameVault(address(gameToken));
        console.log("GameVault deployed at:", address(gameVault));
        
        // Deploy SubwaySurfersGame
        console.log("Deploying SubwaySurfersGame...");
        SubwaySurfersGame game = new SubwaySurfersGame(address(gameToken), address(gameVault));
        console.log("SubwaySurfersGame deployed at:", address(game));
        
        // Set up permissions
        console.log("Setting up permissions...");
        
        // Add game contract as minter for GameToken
        gameToken.addMinter(address(game));
        console.log("Added game contract as minter");
        
        // Transfer ownership of GameVault to game contract
        gameVault.transferOwnership(address(game));
        console.log("Transferred GameVault ownership to game contract");
        
        // Mint initial tokens to deployer for testing
        uint256 initialMint = 10000 * 10**18; // 10,000 tokens
        gameToken.mint(deployer, initialMint);
        console.log("Minted", initialMint / 10**18, "tokens to deployer");
        
        vm.stopBroadcast();
        
        console.log("Deployment completed successfully!");
        console.log("GameToken:", address(gameToken));
        console.log("GameVault:", address(gameVault));
        console.log("SubwaySurfersGame:", address(game));
        
        // Display game configuration
        console.log("\nGame Configuration:");
        console.log("Easy target distance:", game.distanceTargets(IGameInterface.DifficultyLevel.Easy));
        console.log("Medium target distance:", game.distanceTargets(IGameInterface.DifficultyLevel.Medium));
        console.log("Hard target distance:", game.distanceTargets(IGameInterface.DifficultyLevel.Hard));
        console.log("Min wager:", game.MIN_WAGER() / 10**18, "tokens");
        console.log("Max wager:", game.MAX_WAGER() / 10**18, "tokens");
        console.log("Max game duration:", game.MAX_GAME_DURATION(), "seconds");
    }
}
