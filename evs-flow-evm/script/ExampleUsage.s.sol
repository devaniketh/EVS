// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/GameToken.sol";
import "../src/GameVault.sol";
import "../src/SubwaySurfersGame.sol";
import "../src/IGameInterface.sol";

/**
 * @title ExampleUsage
 * @dev Example script showing how to interact with the Subway Surfers game
 */
contract ExampleUsage is Script {
    GameToken public gameToken;
    GameVault public gameVault;
    SubwaySurfersGame public game;
    
    address public player = address(0x1);
    uint256 public constant WAGER_AMOUNT = 100 * 10**18;
    
    function run() external {
        // This would be used after deployment
        // Replace with actual deployed contract addresses
        address gameTokenAddr = address(0x1234567890123456789012345678901234567890);
        address gameVaultAddr = address(0x2345678901234567890123456789012345678901);
        address gameAddr = address(0x3456789012345678901234567890123456789012);
        
        gameToken = GameToken(gameTokenAddr);
        gameVault = GameVault(gameVaultAddr);
        game = SubwaySurfersGame(gameAddr);
        
        console.log("=== Subway Surfers Game Example ===");
        
        // Check initial balances
        console.log("Player token balance:", gameToken.balanceOf(player) / 10**18);
        console.log("Vault balance:", gameVault.getVaultBalance() / 10**18);
        
        // Start a game
        console.log("\n=== Starting Game ===");
        console.log("Wager amount:", WAGER_AMOUNT / 10**18, "tokens");
        console.log("Difficulty: Easy (1000m target)");
        
        // Note: In a real scenario, you would call these functions
        // uint256 sessionId = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Easy);
        // console.log("Game started with session ID:", sessionId);
        
        // Simulate distance updates
        console.log("\n=== Simulating Game Progress ===");
        console.log("Distance: 0m -> 250m -> 500m -> 750m -> 1000m (TARGET REACHED)");
        console.log("Target reached! Game completed successfully!");
        
        // Show final balances
        console.log("\n=== Final Results ===");
        console.log("Player would receive:", (WAGER_AMOUNT * 2) / 10**18, "tokens (2x reward)");
        console.log("Net profit:", WAGER_AMOUNT / 10**18, "tokens");
        
        // Show game statistics
        console.log("\n=== Game Statistics ===");
        (uint256 totalGames, uint256 totalWagered, uint256 totalRewards, uint256 totalFees) = game.getGameStats();
        console.log("Total games played:", totalGames);
        console.log("Total tokens wagered:", totalWagered / 10**18);
        console.log("Total rewards distributed:", totalRewards / 10**18);
        console.log("Total fees collected:", totalFees / 10**18);
        
        console.log("\n=== Example Complete ===");
    }
    
    function demonstrateGameFlow() external {
        console.log("=== Complete Game Flow Example ===");
        
        console.log("1. Player approves game contract to spend tokens");
        console.log("2. Player starts game with wager and difficulty");
        console.log("3. Tokens are transferred to vault");
        console.log("4. Player updates distance as they progress");
        console.log("5a. If target reached: Player gets 2x reward");
        console.log("5b. If failed/abandoned: 5% fee + remaining to vault");
        
        console.log("\n=== Difficulty Levels ===");
        console.log("Easy: 1,000 meters (lower risk, lower reward)");
        console.log("Medium: 2,500 meters (medium risk, medium reward)");
        console.log("Hard: 5,000 meters (higher risk, higher reward)");
        
        console.log("\n=== Game Rules ===");
        console.log("- Minimum wager: 10 tokens");
        console.log("- Maximum wager: 10,000 tokens");
        console.log("- Time limit: 5 minutes per game");
        console.log("- Reward: 2x wager amount");
        console.log("- Fee: 5% of wager amount (on failure)");
    }
}
