# EVS - Endless Runner Game with Staking Mechanics

A Subway Surfer-style endless runner game built on Flow blockchain with integrated staking mechanics, cross-chain bridging capabilities, and reward distribution from a shared pool.

## 🎮 Game Overview

EVS is a blockchain-based endless runner game where players:

- **Stake Flow tokens** to play
- **Earn 2x rewards** when they win (from losing players' stakes)
- **Transfer games** across different blockchains
- **Compete** in multiple concurrent game instances

## 🏗️ Architecture

### Core Components

1. **Game Sessions**: Individual game instances with staking
2. **Staking Pool**: Centralized pool for reward distribution
3. **Player Data**: Statistics and performance tracking
4. **Cross-Chain Bridge**: Transfer games between blockchains
5. **Admin Functions**: Pool management and system control

### Key Features

- ✅ **Multi-Instance Gaming**: Multiple games can run simultaneously
- ✅ **Staking Mechanics**: Players stake Flow tokens to play
- ✅ **Reward System**: Winners get 2x rewards from the pool
- ✅ **Cross-Chain Support**: Transfer games to any EVM/non-EVM chain
- ✅ **Player Statistics**: Track performance and earnings
- ✅ **Admin Controls**: Manage the staking pool and system

## 📁 Project Structure

```
cadence/
├── contracts/
│   └── Evs.cdc                 # Main game contract
├── transactions/
│   ├── StartGame.cdc          # Start a new game session
│   ├── CompleteGame.cdc       # Complete a game and claim rewards
│   ├── TransferGameToChain.cdc # Transfer game to another chain
│   └── SetAdmin.cdc           # Set admin address
├── scripts/
│   ├── GetGameSession.cdc     # Query game session details
│   ├── GetPlayerData.cdc      # Get player statistics
│   ├── GetStakingPool.cdc     # Get pool information
│   ├── GetActiveGames.cdc     # Get player's active games
│   └── CalculateReward.cdc    # Calculate potential rewards
└── tests/
    └── Evs_test.cdc           # Comprehensive test suite
```

## 🚀 Getting Started

### Prerequisites

- Flow CLI installed
- Flow emulator running
- Basic understanding of Cadence

### Setup

1. **Start Flow Emulator**:

   ```bash
   flow emulator start
   ```

2. **Deploy Contracts**:

   ```bash
   flow project deploy
   ```

3. **Run Tests**:
   ```bash
   flow test
   ```

## 🎯 Game Mechanics

### Starting a Game

```cadence
// Start a new game with 10 FLOW stake and 2x multiplier
let gameId = Evs.startGame(stakeAmount: 10.0, multiplier: 2.0)
```

### Game Session Structure

```cadence
struct GameSession {
    let id: UInt64           // Unique game identifier
    let player: Address      // Player's address
    let stakeAmount: UFix64 // Amount staked
    let startTime: UFix64    // Game start timestamp
    let status: GameStatus   // Current game status
    let score: UInt64        // Player's score
    let multiplier: UFix64   // Reward multiplier
}
```

### Reward Calculation

- **Winners**: Receive `stakeAmount * multiplier * 2.0` from the pool
- **Losers**: Their stake goes to the pool for future winners
- **Pool**: Funded by losing players, pays out to winners

## 🌉 Cross-Chain Bridge

### Supported Chains

- **EVM Chains**: Ethereum, Polygon, BSC, Avalanche
- **Non-EVM Chains**: Solana, Near, Cosmos
- **Layer 2s**: Arbitrum, Optimism, Base

### Bridge Process

1. **Initiate Transfer**: Call `transferGameToChain()`
2. **Generate Bridge ID**: Unique identifier for tracking
3. **Update Game Status**: Mark as transferred
4. **Emit Event**: Log transfer details

```cadence
let bridgeId = Evs.transferGameToChain(
    gameId: gameId,
    targetChain: "Ethereum",
    targetAddress: "0x1234..."
)
```

## 📊 Player Statistics

Track comprehensive player data:

```cadence
struct PlayerData {
    let address: Address      // Player address
    let totalStaked: UFix64   // Total amount staked
    let totalWon: UFix64      // Total winnings
    let totalLost: UFix64     // Total losses
    let gamesPlayed: UInt64   // Total games played
    let gamesWon: UInt64      // Games won
    let bestScore: UInt64     // Highest score achieved
    let multiplier: UFix64   // Current multiplier
}
```

## 🔧 Admin Functions

### Pool Management

```cadence
// Set admin address
Evs.setAdmin(admin: adminAddress)

// Update pool parameters
Evs.updatePool(
    totalPool: 10000.0,
    totalStaked: 5000.0,
    activeGames: 25
)
```

### Monitoring

- **Total Pool**: Total funds available for rewards
- **Active Games**: Number of currently running games
- **Player Statistics**: Individual performance tracking
- **Bridge Transfers**: Cross-chain game transfers

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests
flow test

# Run specific test file
flow test cadence/tests/Evs_test.cdc
```

### Test Coverage

- ✅ Game session creation
- ✅ Stake validation
- ✅ Multiplier validation
- ✅ Reward calculations
- ✅ Game completion
- ✅ Cross-chain transfers
- ✅ Player statistics
- ✅ Pool management

## 📈 Events

Monitor game activity through events:

```cadence
// Game started
event GameStarted(gameId: UInt64, player: Address, stakeAmount: UFix64, multiplier: UFix64)

// Game completed
event GameCompleted(gameId: UInt64, player: Address, score: UInt64, reward: UFix64, won: Bool)

// Game transferred
event GameTransferred(gameId: UInt64, fromChain: String, toChain: String, targetAddress: String)

// Pool updated
event PoolUpdated(totalPool: UFix64, totalStaked: UFix64, activeGames: UInt64)
```

## 🔒 Security Features

- **Access Control**: Admin-only functions protected
- **Input Validation**: All parameters validated
- **Error Handling**: Comprehensive error messages
- **State Management**: Immutable game states
- **Resource Management**: Proper token handling

## 🚀 Deployment

### Local Development

```bash
# Start emulator
flow emulator start

# Deploy contracts
flow project deploy --network emulator

# Run tests
flow test --network emulator
```

### Testnet Deployment

```bash
# Deploy to testnet
flow project deploy --network testnet

# Verify deployment
flow project verify --network testnet
```

### Mainnet Deployment

```bash
# Deploy to mainnet
flow project deploy --network mainnet

# Verify deployment
flow project verify --network mainnet
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For questions and support:

- Create an issue on GitHub
- Join our Discord community
- Check the documentation

## 🔮 Future Enhancements

- **NFT Integration**: Game achievements as NFTs
- **Tournament Mode**: Competitive tournaments
- **Social Features**: Leaderboards and rankings
- **Mobile App**: Native mobile game client
- **Advanced Analytics**: Detailed performance metrics
- **Governance**: DAO-based pool management

---

**Built with ❤️ on Flow Blockchain**
