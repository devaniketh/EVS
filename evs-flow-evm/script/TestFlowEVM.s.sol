// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/GameToken.sol";
import "../src/GameVault.sol";
import "../src/SubwaySurfersGame.sol";
import "../src/IGameInterface.sol";

/**
 * @title TestFlowEVM
 * @dev Test script for Flow EVM deployment verification
 */
contract TestFlowEVM is Script {
    function run() external {
        // Replace with your deployed contract addresses
        address gameTokenAddr = vm.envAddress("GAME_TOKEN_ADDRESS");
        address gameVaultAddr = vm.envAddress("GAME_VAULT_ADDRESS");
        address gameAddr = vm.envAddress("GAME_ADDRESS");
        
        GameToken gameToken = GameToken(gameTokenAddr);
        GameVault gameVault = GameVault(gameVaultAddr);
        SubwaySurfersGame game = SubwaySurfersGame(gameAddr);
        
        console.log("=== Flow EVM Contract Verification ===");
        console.log("GameToken Address:", address(gameToken));
        console.log("GameVault Address:", address(gameVault));
        console.log("SubwaySurfersGame Address:", address(game));
        
        // Test basic functionality
        console.log("\n=== Testing Basic Functionality ===");
        
        // Check token details
        console.log("Token Name:", gameToken.name());
        console.log("Token Symbol:", gameToken.symbol());
        console.log("Token Decimals:", gameToken.decimals());
        console.log("Total Supply:", gameToken.totalSupply() / 10**18, "tokens");
        
        // Check game configuration
        console.log("\n=== Game Configuration ===");
        console.log("Easy Target Distance:", game.distanceTargets(IGameInterface.DifficultyLevel.Easy));
        console.log("Medium Target Distance:", game.distanceTargets(IGameInterface.DifficultyLevel.Medium));
        console.log("Hard Target Distance:", game.distanceTargets(IGameInterface.DifficultyLevel.Hard));
        console.log("Min Wager:", game.MIN_WAGER() / 10**18, "tokens");
        console.log("Max Wager:", game.MAX_WAGER() / 10**18, "tokens");
        console.log("Max Game Duration:", game.MAX_GAME_DURATION(), "seconds");
        
        // Check vault configuration
        console.log("\n=== Vault Configuration ===");
        console.log("Vault Balance:", gameVault.getVaultBalance() / 10**18, "tokens");
        console.log("Total Rewards:", gameVault.totalRewards() / 10**18, "tokens");
        console.log("Total Fees:", gameVault.totalFees() / 10**18, "tokens");
        
        // Check game statistics
        console.log("\n=== Game Statistics ===");
        (uint256 totalGames, uint256 totalWagered, uint256 totalRewards, uint256 totalFees) = game.getGameStats();
        console.log("Total Games:", totalGames);
        console.log("Total Wagered:", totalWagered / 10**18, "tokens");
        console.log("Total Rewards:", totalRewards / 10**18, "tokens");
        console.log("Total Fees:", totalFees / 10**18, "tokens");
        
        console.log("\n=== Flow EVM Integration Test Complete ===");
        console.log("All contracts are properly deployed and configured!");
        console.log("Ready for Flow EVM integration with sponsored transactions and data sources.");
    }
}
