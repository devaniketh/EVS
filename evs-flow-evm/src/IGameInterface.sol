// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title IGameInterface
 * @dev Interface for Subway Surfers game interactions
 */
interface IGameInterface {
    // Game state enums
    enum GameStatus {
        NotStarted,
        InProgress,
        Completed,
        Failed
    }
    
    // Game difficulty levels
    enum DifficultyLevel {
        Easy,
        Medium,
        Hard
    }
    
    // Game session structure
    struct GameSession {
        address player;
        uint256 wagerAmount;
        uint256 targetDistance;
        uint256 currentDistance;
        uint256 startTime;
        uint256 endTime;
        GameStatus status;
        DifficultyLevel difficulty;
        bool isActive;
    }
    
    // Events
    event GameStarted(
        address indexed player,
        uint256 indexed sessionId,
        uint256 wagerAmount,
        uint256 targetDistance,
        DifficultyLevel difficulty
    );
    
    event DistanceUpdated(
        address indexed player,
        uint256 indexed sessionId,
        uint256 newDistance
    );
    
    event GameCompleted(
        address indexed player,
        uint256 indexed sessionId,
        uint256 finalDistance,
        uint256 rewardAmount
    );
    
    event GameFailed(
        address indexed player,
        uint256 indexed sessionId,
        uint256 finalDistance,
        uint256 feeAmount
    );
    
    event GameAbandoned(
        address indexed player,
        uint256 indexed sessionId
    );
    
    // Functions
    function startGame(
        uint256 wagerAmount,
        DifficultyLevel difficulty
    ) external returns (uint256 sessionId);
    
    function updateDistance(
        uint256 sessionId,
        uint256 newDistance
    ) external;
    
    function completeGame(uint256 sessionId) external;
    
    function abandonGame(uint256 sessionId) external;
    
    function getGameSession(uint256 sessionId) external view returns (GameSession memory);
    
    function getPlayerActiveGames(address player) external view returns (uint256[] memory);
    
    function getGameStats() external view returns (
        uint256 totalGames,
        uint256 totalWagered,
        uint256 totalRewards,
        uint256 totalFees
    );
}
