// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GameToken.sol";
import "../src/GameVault.sol";
import "../src/SubwaySurfersGame.sol";
import "../src/IGameInterface.sol";

contract SubwaySurfersGameTest is Test {
    GameToken public gameToken;
    GameVault public gameVault;
    SubwaySurfersGame public game;
    
    address public player1 = address(0x1);
    address public player2 = address(0x2);
    address public owner = address(0x3);
    
    uint256 public constant INITIAL_BALANCE = 10000 * 10**18;
    uint256 public constant WAGER_AMOUNT = 100 * 10**18;
    
    function setUp() public {
        // Deploy contracts
        vm.startPrank(owner);
        gameToken = new GameToken();
        gameVault = new GameVault(address(gameToken));
        game = new SubwaySurfersGame(address(gameToken), address(gameVault));
        
        // Set up permissions
        gameToken.addMinter(address(game));
        gameVault.setGameContract(address(game));
        
        // Mint tokens to players and game contract
        gameToken.mint(player1, INITIAL_BALANCE);
        gameToken.mint(player2, INITIAL_BALANCE);
        gameToken.mint(address(game), INITIAL_BALANCE);
        vm.stopPrank();
        
        // Approve game contract to spend tokens
        vm.startPrank(player1);
        gameToken.approve(address(game), type(uint256).max);
        vm.stopPrank();
        
        vm.startPrank(player2);
        gameToken.approve(address(game), type(uint256).max);
        vm.stopPrank();
        
        // Approve vault to spend tokens from game contract
        vm.startPrank(address(game));
        gameToken.approve(address(gameVault), type(uint256).max);
        vm.stopPrank();
    }
    
    function testGameStart() public {
        vm.startPrank(player1);
        
        uint256 sessionId = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Easy);
        
        IGameInterface.GameSession memory session = game.getGameSession(sessionId);
        assertEq(session.player, player1);
        assertEq(session.wagerAmount, WAGER_AMOUNT);
        assertEq(session.targetDistance, 1000); // Easy difficulty
        assertEq(uint256(session.status), uint256(IGameInterface.GameStatus.InProgress));
        assertTrue(session.isActive);
        
        vm.stopPrank();
    }
    
    function testGameCompletion() public {
        vm.startPrank(player1);
        
        uint256 sessionId = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Easy);
        
        // Update distance to reach target
        game.updateDistance(sessionId, 1000);
        
        IGameInterface.GameSession memory session = game.getGameSession(sessionId);
        assertEq(uint256(session.status), uint256(IGameInterface.GameStatus.Completed));
        assertFalse(session.isActive);
        
        // Check player received 2x reward
        uint256 expectedBalance = INITIAL_BALANCE + WAGER_AMOUNT; // 2x reward - original wager
        assertEq(gameToken.balanceOf(player1), expectedBalance);
        
        vm.stopPrank();
    }
    
    function testGameFailure() public {
        vm.startPrank(player1);
        
        uint256 sessionId = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Easy);
        
        // Abandon game before reaching target
        game.abandonGame(sessionId);
        
        IGameInterface.GameSession memory session = game.getGameSession(sessionId);
        assertEq(uint256(session.status), uint256(IGameInterface.GameStatus.Failed));
        assertFalse(session.isActive);
        
        // Check player lost tokens (5% fee taken)
        uint256 expectedBalance = INITIAL_BALANCE - WAGER_AMOUNT;
        assertEq(gameToken.balanceOf(player1), expectedBalance);
        
        vm.stopPrank();
    }
    
    function testDistanceUpdate() public {
        vm.startPrank(player1);
        
        uint256 sessionId = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Medium);
        
        // Update distance incrementally
        game.updateDistance(sessionId, 500);
        IGameInterface.GameSession memory session = game.getGameSession(sessionId);
        assertEq(session.currentDistance, 500);
        
        game.updateDistance(sessionId, 1000);
        session = game.getGameSession(sessionId);
        assertEq(session.currentDistance, 1000);
        
        // Try to update with lower distance (should fail)
        vm.expectRevert("Distance must increase");
        game.updateDistance(sessionId, 500);
        
        vm.stopPrank();
    }
    
    function testGameExpiration() public {
        vm.startPrank(player1);
        
        uint256 sessionId = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Easy);
        
        // Fast forward time beyond max game duration
        vm.warp(block.timestamp + 301); // 301 seconds > 300 max duration
        
        // Try to update distance (should fail)
        vm.expectRevert("Game time exceeded");
        game.updateDistance(sessionId, 1000);
        
        vm.stopPrank();
    }
    
    function testForceCompleteExpiredGame() public {
        vm.startPrank(player1);
        uint256 sessionId = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Easy);
        vm.stopPrank();
        
        // Fast forward time beyond max game duration
        vm.warp(block.timestamp + 301);
        
        // Owner can force complete expired game
        vm.startPrank(owner);
        game.forceCompleteExpiredGame(sessionId);
        vm.stopPrank();
        
        IGameInterface.GameSession memory session = game.getGameSession(sessionId);
        assertEq(uint256(session.status), uint256(IGameInterface.GameStatus.Failed));
        assertFalse(session.isActive);
    }
    
    function testInvalidWagerAmount() public {
        vm.startPrank(player1);
        
        // Test minimum wager
        vm.expectRevert("Invalid wager amount");
        game.startGame(5 * 10**18, IGameInterface.DifficultyLevel.Easy);
        
        // Test maximum wager
        vm.expectRevert("Invalid wager amount");
        game.startGame(20000 * 10**18, IGameInterface.DifficultyLevel.Easy);
        
        vm.stopPrank();
    }
    
    function testInsufficientBalance() public {
        address poorPlayer = address(0x4);
        vm.startPrank(poorPlayer);
        
        // Try to start game without tokens
        vm.expectRevert("Insufficient token balance");
        game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Easy);
        
        vm.stopPrank();
    }
    
    function testGameStatistics() public {
        vm.startPrank(player1);
        
        // Start and complete a game
        uint256 sessionId = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Easy);
        game.updateDistance(sessionId, 1000);
        
        (uint256 totalGames, uint256 totalWagered, uint256 totalRewards, uint256 totalFees) = game.getGameStats();
        assertEq(totalGames, 1);
        assertEq(totalWagered, WAGER_AMOUNT);
        assertEq(totalRewards, WAGER_AMOUNT * 2);
        assertEq(totalFees, 0);
        
        vm.stopPrank();
    }
    
    function testPlayerStatistics() public {
        vm.startPrank(player1);
        
        // Start and complete a game
        uint256 sessionId = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Easy);
        game.updateDistance(sessionId, 1000);
        
        (uint256 gamesPlayed, uint256 gamesWon, uint256 totalWagered) = game.getPlayerStats(player1);
        assertEq(gamesPlayed, 1);
        assertEq(gamesWon, 1);
        assertEq(totalWagered, WAGER_AMOUNT);
        
        vm.stopPrank();
    }
    
    function testMultiplePlayers() public {
        // Player 1 starts and completes a game
        vm.startPrank(player1);
        uint256 sessionId1 = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Easy);
        game.updateDistance(sessionId1, 1000);
        vm.stopPrank();
        
        // Player 2 starts and abandons a game
        vm.startPrank(player2);
        uint256 sessionId2 = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Medium);
        game.abandonGame(sessionId2);
        vm.stopPrank();
        
        // Check both players have different active games
        uint256[] memory player1Games = game.getPlayerActiveGames(player1);
        uint256[] memory player2Games = game.getPlayerActiveGames(player2);
        
        assertEq(player1Games.length, 0); // Player 1 completed their game
        assertEq(player2Games.length, 0); // Player 2 abandoned their game
    }
    
    function testDifficultyLevels() public {
        vm.startPrank(player1);
        
        // Test Easy difficulty
        uint256 easySession = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Easy);
        IGameInterface.GameSession memory session = game.getGameSession(easySession);
        assertEq(session.targetDistance, 1000);
        game.abandonGame(easySession);
        
        // Test Medium difficulty
        uint256 mediumSession = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Medium);
        session = game.getGameSession(mediumSession);
        assertEq(session.targetDistance, 2500);
        game.abandonGame(mediumSession);
        
        // Test Hard difficulty
        uint256 hardSession = game.startGame(WAGER_AMOUNT, IGameInterface.DifficultyLevel.Hard);
        session = game.getGameSession(hardSession);
        assertEq(session.targetDistance, 5000);
        game.abandonGame(hardSession);
        
        vm.stopPrank();
    }
}
