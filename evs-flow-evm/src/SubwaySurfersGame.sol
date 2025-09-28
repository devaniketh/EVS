// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IGameInterface.sol";
import "./GameToken.sol";
import "./GameVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title SubwaySurfersGame
 * @dev Main game contract for Subway Surfers style wagering game
 */
contract SubwaySurfersGame is IGameInterface, Ownable, ReentrancyGuard, Pausable {
    GameToken public gameToken;
    GameVault public gameVault;
    
    uint256 public nextSessionId = 1;
    uint256 public constant MAX_GAME_DURATION = 300; // 5 minutes in seconds
    uint256 public constant MIN_WAGER = 10 * 10**18; // 10 tokens minimum
    uint256 public constant MAX_WAGER = 10000 * 10**18; // 10,000 tokens maximum
    
    // Distance targets for different difficulty levels
    mapping(DifficultyLevel => uint256) public distanceTargets;
    
    // Game sessions storage
    mapping(uint256 => GameSession) public gameSessions;
    mapping(address => uint256[]) public playerActiveGames;
    
    // Game statistics
    uint256 public totalGames;
    uint256 public totalWagered;
    uint256 public totalRewards;
    uint256 public totalFees;
    
    // Player statistics
    mapping(address => uint256) public playerGamesPlayed;
    mapping(address => uint256) public playerGamesWon;
    mapping(address => uint256) public playerTotalWagered;
    
    event GameStatsUpdated(
        uint256 totalGames,
        uint256 totalWagered,
        uint256 totalRewards,
        uint256 totalFees
    );
    
    constructor(address _gameToken, address _gameVault) Ownable(msg.sender) {
        gameToken = GameToken(_gameToken);
        gameVault = GameVault(_gameVault);
        
        // Set distance targets for different difficulty levels
        distanceTargets[DifficultyLevel.Easy] = 1000;    // 1000 meters
        distanceTargets[DifficultyLevel.Medium] = 2500;  // 2500 meters
        distanceTargets[DifficultyLevel.Hard] = 5000;    // 5000 meters
    }
    
    modifier validSession(uint256 sessionId) {
        require(sessionId > 0 && sessionId < nextSessionId, "Invalid session ID");
        require(gameSessions[sessionId].isActive, "Session not active");
        _;
    }
    
    modifier onlyPlayer(uint256 sessionId) {
        require(gameSessions[sessionId].player == msg.sender, "Not the game player");
        _;
    }
    
    /**
     * @dev Start a new game session
     * @param wagerAmount Amount of tokens to wager
     * @param difficulty Difficulty level of the game
     * @return sessionId The ID of the created game session
     */
    function startGame(
        uint256 wagerAmount,
        DifficultyLevel difficulty
    ) external override whenNotPaused nonReentrant returns (uint256 sessionId) {
        require(wagerAmount >= MIN_WAGER && wagerAmount <= MAX_WAGER, "Invalid wager amount");
        require(gameToken.balanceOf(msg.sender) >= wagerAmount, "Insufficient token balance");
        require(gameToken.allowance(msg.sender, address(this)) >= wagerAmount, "Insufficient allowance");
        
        sessionId = nextSessionId++;
        uint256 targetDistance = distanceTargets[difficulty];
        
        GameSession storage session = gameSessions[sessionId];
        session.player = msg.sender;
        session.wagerAmount = wagerAmount;
        session.targetDistance = targetDistance;
        session.currentDistance = 0;
        session.startTime = block.timestamp;
        session.status = GameStatus.InProgress;
        session.difficulty = difficulty;
        session.isActive = true;
        
        // Add to player's active games
        playerActiveGames[msg.sender].push(sessionId);
        
        // Transfer tokens to vault
        require(gameToken.transferFrom(msg.sender, address(gameVault), wagerAmount), "Token transfer failed");
        gameVault.depositTokens(msg.sender, wagerAmount);
        
        // Update statistics
        totalGames++;
        totalWagered += wagerAmount;
        playerGamesPlayed[msg.sender]++;
        playerTotalWagered[msg.sender] += wagerAmount;
        
        emit GameStarted(msg.sender, sessionId, wagerAmount, targetDistance, difficulty);
        emit GameStatsUpdated(totalGames, totalWagered, totalRewards, totalFees);
    }
    
    /**
     * @dev Update the current distance in a game session
     * @param sessionId ID of the game session
     * @param newDistance New distance achieved
     */
    function updateDistance(
        uint256 sessionId,
        uint256 newDistance
    ) external override validSession(sessionId) onlyPlayer(sessionId) {
        GameSession storage session = gameSessions[sessionId];
        require(session.status == GameStatus.InProgress, "Game not in progress");
        require(newDistance > session.currentDistance, "Distance must increase");
        require(block.timestamp - session.startTime <= MAX_GAME_DURATION, "Game time exceeded");
        
        session.currentDistance = newDistance;
        
        emit DistanceUpdated(msg.sender, sessionId, newDistance);
        
        // Auto-complete if target distance reached
        if (newDistance >= session.targetDistance) {
            completeGame(sessionId);
        }
    }
    
    /**
     * @dev Complete a game session (called when target distance is reached)
     * @param sessionId ID of the game session
     */
    function completeGame(uint256 sessionId) public override validSession(sessionId) {
        GameSession storage session = gameSessions[sessionId];
        require(session.status == GameStatus.InProgress, "Game not in progress");
        require(session.currentDistance >= session.targetDistance, "Target distance not reached");
        
        session.status = GameStatus.Completed;
        session.endTime = block.timestamp;
        session.isActive = false;
        
        // Remove from player's active games
        _removeFromActiveGames(session.player, sessionId);
        
        // Distribute rewards
        gameVault.distributeRewards(session.player, session.wagerAmount);
        uint256 rewardAmount = session.wagerAmount * 2; // 2x reward
        totalRewards += rewardAmount;
        playerGamesWon[session.player]++;
        
        emit GameCompleted(session.player, sessionId, session.currentDistance, rewardAmount);
        emit GameStatsUpdated(totalGames, totalWagered, totalRewards, totalFees);
    }
    
    /**
     * @dev Abandon a game session (player gives up)
     * @param sessionId ID of the game session
     */
    function abandonGame(uint256 sessionId) external override validSession(sessionId) onlyPlayer(sessionId) {
        GameSession storage session = gameSessions[sessionId];
        require(session.status == GameStatus.InProgress, "Game not in progress");
        
        session.status = GameStatus.Failed;
        session.endTime = block.timestamp;
        session.isActive = false;
        
        // Remove from player's active games
        _removeFromActiveGames(session.player, sessionId);
        
        // Collect fees
        gameVault.collectFees(session.player, session.wagerAmount);
        uint256 feeAmount = (session.wagerAmount * 5) / 100; // 5% fee
        totalFees += feeAmount;
        
        emit GameFailed(session.player, sessionId, session.currentDistance, feeAmount);
        emit GameStatsUpdated(totalGames, totalWagered, totalRewards, totalFees);
    }
    
    /**
     * @dev Get game session details
     * @param sessionId ID of the game session
     * @return Game session details
     */
    function getGameSession(uint256 sessionId) external view override returns (GameSession memory) {
        require(sessionId > 0 && sessionId < nextSessionId, "Invalid session ID");
        return gameSessions[sessionId];
    }
    
    /**
     * @dev Get all active games for a player
     * @param player Address of the player
     * @return Array of active game session IDs
     */
    function getPlayerActiveGames(address player) external view override returns (uint256[] memory) {
        return playerActiveGames[player];
    }
    
    /**
     * @dev Get overall game statistics
     * @return Total games, total wagered, total rewards, total fees
     */
    function getGameStats() external view override returns (
        uint256,
        uint256,
        uint256,
        uint256
    ) {
        return (totalGames, totalWagered, totalRewards, totalFees);
    }
    
    /**
     * @dev Get player statistics
     * @param player Address of the player
     * @return Games played, games won, total wagered
     */
    function getPlayerStats(address player) external view returns (
        uint256,
        uint256,
        uint256
    ) {
        return (
            playerGamesPlayed[player],
            playerGamesWon[player],
            playerTotalWagered[player]
        );
    }
    
    /**
     * @dev Check if a game session has expired
     * @param sessionId ID of the game session
     * @return True if expired, false otherwise
     */
    function isGameExpired(uint256 sessionId) external view returns (bool) {
        if (sessionId == 0 || sessionId >= nextSessionId) return false;
        GameSession memory session = gameSessions[sessionId];
        return session.isActive && (block.timestamp - session.startTime > MAX_GAME_DURATION);
    }
    
    /**
     * @dev Force complete expired games (only owner)
     * @param sessionId ID of the game session
     */
    function forceCompleteExpiredGame(uint256 sessionId) external onlyOwner {
        require(sessionId > 0 && sessionId < nextSessionId, "Invalid session ID");
        GameSession storage session = gameSessions[sessionId];
        require(session.isActive, "Session not active");
        require(block.timestamp - session.startTime > MAX_GAME_DURATION, "Game not expired");
        
        session.status = GameStatus.Failed;
        session.endTime = block.timestamp;
        session.isActive = false;
        
        // Remove from player's active games
        _removeFromActiveGames(session.player, sessionId);
        
        // Collect fees
        gameVault.collectFees(session.player, session.wagerAmount);
        uint256 feeAmount = (session.wagerAmount * 5) / 100; // 5% fee
        totalFees += feeAmount;
        
        emit GameFailed(session.player, sessionId, session.currentDistance, feeAmount);
        emit GameStatsUpdated(totalGames, totalWagered, totalRewards, totalFees);
    }
    
    /**
     * @dev Update distance targets for difficulty levels (only owner)
     * @param difficulty Difficulty level
     * @param newTarget New distance target
     */
    function updateDistanceTarget(DifficultyLevel difficulty, uint256 newTarget) external onlyOwner {
        require(newTarget > 0, "Invalid target distance");
        distanceTargets[difficulty] = newTarget;
    }
    
    /**
     * @dev Pause the game
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the game
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Remove session from player's active games
     * @param player Address of the player
     * @param sessionId ID of the session to remove
     */
    function _removeFromActiveGames(address player, uint256 sessionId) internal {
        uint256[] storage activeGames = playerActiveGames[player];
        for (uint256 i = 0; i < activeGames.length; i++) {
            if (activeGames[i] == sessionId) {
                activeGames[i] = activeGames[activeGames.length - 1];
                activeGames.pop();
                break;
            }
        }
    }
}
