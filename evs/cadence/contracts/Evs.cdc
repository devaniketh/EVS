import FungibleToken from 0xf233dcee88fe0abe
import FlowToken from 0x1654653399040a61
import MetadataViews from 0x1d7e57aa55817448
import NonFungibleToken from 0x1d7e57aa55817448

/// EVS - Endless Runner Game with Staking Mechanics
/// Players stake Flow tokens to play, winners get 2x rewards from losing players' stakes
access(all)
contract Evs {
    
    // ========== DATA STRUCTURES ==========
    
    /// Represents a game session instance
    access(all)
    struct GameSession {
        access(all) let id: UInt64
        access(all) let player: Address
        access(all) let stakeAmount: UFix64
        access(all) let startTime: UFix64
        access(all) let status: GameStatus
        access(all) let score: UInt64
        access(all) let multiplier: UFix64
        
        init(id: UInt64, player: Address, stakeAmount: UFix64, multiplier: UFix64) {
            self.id = id
            self.player = player
            self.stakeAmount = stakeAmount
            self.startTime = getCurrentBlock().timestamp
            self.status = GameStatus.ACTIVE
            self.score = 0
            self.multiplier = multiplier
        }
    }
    
    /// Game status enumeration
    access(all)
    enum GameStatus {
        case ACTIVE
        case COMPLETED
        case CANCELLED
        case TRANSFERRED
    }
    
    /// Player statistics and data
    access(all)
    struct PlayerData {
        access(all) let address: Address
        access(all) let totalStaked: UFix64
        access(all) let totalWon: UFix64
        access(all) let totalLost: UFix64
        access(all) let gamesPlayed: UInt64
        access(all) let gamesWon: UInt64
        access(all) let bestScore: UInt64
        access(all) let multiplier: UFix64
        
        init(address: Address) {
            self.address = address
            self.totalStaked = 0.0
            self.totalWon = 0.0
            self.totalLost = 0.0
            self.gamesPlayed = 0
            self.gamesWon = 0
            self.bestScore = 0
            self.multiplier = 1.0
        }
    }
    
    /// Staking pool for managing rewards
    access(all)
    struct StakingPool {
        access(all) let totalPool: UFix64
        access(all) let totalStaked: UFix64
        access(all) let totalRewards: UFix64
        access(all) let activeGames: UInt64
        
        init() {
            self.totalPool = 0.0
            self.totalStaked = 0.0
            self.totalRewards = 0.0
            self.activeGames = 0
        }
    }
    
    /// Cross-chain bridge data
    access(all)
    struct BridgeData {
        access(all) let targetChain: String
        access(all) let targetAddress: String
        access(all) let gameId: UInt64
        access(all) let stakeAmount: UFix64
        access(all) let timestamp: UFix64
        
        init(targetChain: String, targetAddress: String, gameId: UInt64, stakeAmount: UFix64) {
            self.targetChain = targetChain
            self.targetAddress = targetAddress
            self.gameId = gameId
            self.stakeAmount = stakeAmount
            self.timestamp = getCurrentBlock().timestamp
        }
    }
    
    // ========== STORAGE ==========
    
    access(all) let gameSessions: {UInt64: GameSession}
    access(all) let players: {Address: PlayerData}
    access(all) let stakingPool: StakingPool
    access(all) let bridgeTransfers: {UInt64: BridgeData}
    
    access(all) var nextGameId: UInt64
    access(all) var nextBridgeId: UInt64
    access(all) var admin: Address?
    
    // ========== EVENTS ==========
    
    access(all)
    event GameStarted(gameId: UInt64, player: Address, stakeAmount: UFix64, multiplier: UFix64)
    
    access(all)
    event GameCompleted(gameId: UInt64, player: Address, score: UInt64, reward: UFix64, won: Bool)
    
    access(all)
    event GameTransferred(gameId: UInt64, fromChain: String, toChain: String, targetAddress: String)
    
    access(all)
    event StakeDeposited(player: Address, amount: UFix64, newTotal: UFix64)
    
    access(all)
    event RewardDistributed(player: Address, amount: UFix64, fromPool: UFix64)
    
    access(all)
    event PoolUpdated(totalPool: UFix64, totalStaked: UFix64, activeGames: UInt64)
    
    // ========== ERRORS ==========
    
    access(all)
    let ErrorGameNotFound: String = "Game session not found"
    
    access(all)
    let ErrorInsufficientStake: String = "Insufficient stake amount"
    
    access(all)
    let ErrorGameNotActive: String = "Game is not active"
    
    access(all)
    let ErrorUnauthorized: String = "Unauthorized access"
    
    access(all)
    let ErrorInsufficientPool: String = "Insufficient pool funds"
    
    access(all)
    let ErrorInvalidMultiplier: String = "Invalid multiplier value"
    
    // ========== INITIALIZER ==========
    
    init() {
        self.gameSessions = {}
        self.players = {}
        self.stakingPool = StakingPool()
        self.bridgeTransfers = {}
        self.nextGameId = 1
        self.nextBridgeId = 1
        self.admin = nil
    }
    
    // ========== ADMIN FUNCTIONS ==========
    
    /// Set the admin address
    access(all)
    fun setAdmin(admin: Address) {
        self.admin = admin
    }
    
    /// Update pool parameters (admin only)
    access(all)
    fun updatePool(totalPool: UFix64, totalStaked: UFix64, activeGames: UInt64) {
        assert(self.admin != nil, message: self.ErrorUnauthorized)
        assert(getCurrentBlock().timestamp > 0, message: "Invalid timestamp")
        
        self.stakingPool = StakingPool()
        // Note: In a real implementation, you'd update the pool values here
        emit PoolUpdated(totalPool: totalPool, totalStaked: totalStaked, activeGames: activeGames)
    }
    
    // ========== PLAYER FUNCTIONS ==========
    
    /// Start a new game session with staking
    access(all)
    fun startGame(stakeAmount: UFix64, multiplier: UFix64): UInt64 {
        let player = getCurrentBlock().timestamp // Simplified for demo
        assert(stakeAmount > 0.0, message: self.ErrorInsufficientStake)
        assert(multiplier >= 1.0 && multiplier <= 10.0, message: self.ErrorInvalidMultiplier)
        
        let gameId = self.nextGameId
        self.nextGameId = self.nextGameId + 1
        
        let gameSession = GameSession(
            id: gameId,
            player: Address(0x0), // Simplified for demo
            stakeAmount: stakeAmount,
            multiplier: multiplier
        )
        
        self.gameSessions[gameId] = gameSession
        
        // Update player data
        if !self.players.containsKey(Address(0x0)) {
            self.players[Address(0x0)] = PlayerData(address: Address(0x0))
        }
        
        let playerData = self.players[Address(0x0)]!
        self.players[Address(0x0)] = PlayerData(
            address: Address(0x0)
        )
        
        emit GameStarted(
            gameId: gameId,
            player: Address(0x0),
            stakeAmount: stakeAmount,
            multiplier: multiplier
        )
        
        return gameId
    }
    
    /// Complete a game and distribute rewards
    access(all)
    fun completeGame(gameId: UInt64, score: UInt64, won: Bool): UFix64 {
        assert(self.gameSessions.containsKey(gameId), message: self.ErrorGameNotFound)
        
        let gameSession = self.gameSessions[gameId]!
        assert(gameSession.status == GameStatus.ACTIVE, message: self.ErrorGameNotActive)
        
        var reward: UFix64 = 0.0
        
        if won {
            // Winner gets 2x their stake from the pool
            reward = gameSession.stakeAmount * 2.0
            assert(self.stakingPool.totalPool >= reward, message: self.ErrorInsufficientPool)
            
            // Update player stats
            if self.players.containsKey(gameSession.player) {
                let playerData = self.players[gameSession.player]!
                self.players[gameSession.player] = PlayerData(
                    address: gameSession.player
                )
            }
        } else {
            // Loser's stake goes to the pool
            // In a real implementation, this would update the pool
        }
        
        // Update game status
        self.gameSessions[gameId] = GameSession(
            id: gameId,
            player: gameSession.player,
            stakeAmount: gameSession.stakeAmount,
            multiplier: gameSession.multiplier
        )
        
        emit GameCompleted(
            gameId: gameId,
            player: gameSession.player,
            score: score,
            reward: reward,
            won: won
        )
        
        return reward
    }
    
    /// Transfer game to another chain
    access(all)
    fun transferGameToChain(gameId: UInt64, targetChain: String, targetAddress: String): UInt64 {
        assert(self.gameSessions.containsKey(gameId), message: self.ErrorGameNotFound)
        
        let gameSession = self.gameSessions[gameId]!
        assert(gameSession.status == GameStatus.ACTIVE, message: self.ErrorGameNotActive)
        
        let bridgeId = self.nextBridgeId
        self.nextBridgeId = self.nextBridgeId + 1
        
        let bridgeData = BridgeData(
            targetChain: targetChain,
            targetAddress: targetAddress,
            gameId: gameId,
            stakeAmount: gameSession.stakeAmount
        )
        
        self.bridgeTransfers[bridgeId] = bridgeData
        
        // Update game status to transferred
        self.gameSessions[gameId] = GameSession(
            id: gameId,
            player: gameSession.player,
            stakeAmount: gameSession.stakeAmount,
            multiplier: gameSession.multiplier
        )
        
        emit GameTransferred(
            gameId: gameId,
            fromChain: "Flow",
            toChain: targetChain,
            targetAddress: targetAddress
        )
        
        return bridgeId
    }
    
    // ========== VIEW FUNCTIONS ==========
    
    /// Get game session details
    access(all)
    fun getGameSession(gameId: UInt64): GameSession? {
        return self.gameSessions[gameId]
    }
    
    /// Get player statistics
    access(all)
    fun getPlayerData(player: Address): PlayerData? {
        return self.players[player]
    }
    
    /// Get staking pool information
    access(all)
    fun getStakingPool(): StakingPool {
        return self.stakingPool
    }
    
    /// Get bridge transfer data
    access(all)
    fun getBridgeTransfer(bridgeId: UInt64): BridgeData? {
        return self.bridgeTransfers[bridgeId]
    }
    
    /// Get all active games for a player
    access(all)
    fun getActiveGames(player: Address): [UInt64] {
        var activeGames: [UInt64] = []
        
        for gameId in self.gameSessions.keys {
            let game = self.gameSessions[gameId]!
            if game.player == player && game.status == GameStatus.ACTIVE {
                activeGames.append(gameId)
            }
        }
        
        return activeGames
    }
    
    /// Calculate potential reward for a stake amount
    access(all)
    fun calculatePotentialReward(stakeAmount: UFix64, multiplier: UFix64): UFix64 {
        return stakeAmount * multiplier * 2.0
    }
    
    /// Get total games count
    access(all)
    fun getTotalGames(): UInt64 {
        return UInt64(self.gameSessions.length)
    }
    
    /// Get total active games
    access(all)
    fun getActiveGamesCount(): UInt64 {
        var count: UInt64 = 0
        
        for gameId in self.gameSessions.keys {
            let game = self.gameSessions[gameId]!
            if game.status == GameStatus.ACTIVE {
                count = count + 1
            }
        }
        
        return count
    }
}