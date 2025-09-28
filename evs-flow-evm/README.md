# Subway Surfers Game - Smart Contract System

A decentralized wagering game inspired by Subway Surfers where players wager tokens and can win 2x rewards by crossing certain distances. Failed attempts result in tokens being locked in the vault to fund future rewards.

## 🎮 Game Overview

The Subway Surfers Game is a skill-based wagering system where:
- Players wager GameTokens to start a game session
- Each game has a target distance based on difficulty level
- Players must reach the target distance within a time limit
- Successful players receive 2x their wager as reward
- Failed players lose their tokens (5% fee + remaining funds go to vault)

## 🏗️ Contract Architecture

### Core Contracts

1. **GameToken.sol** - ERC20 token for wagering
   - Mintable by authorized contracts
   - Pausable for emergency situations
   - Maximum supply cap of 10 million tokens

2. **GameVault.sol** - Vault for managing rewards and fees
   - Handles token deposits from players
   - Distributes 2x rewards to winners
   - Collects 5% fees from losers
   - Manages vault balance for future rewards

3. **SubwaySurfersGame.sol** - Main game contract
   - Manages game sessions and logic
   - Handles distance tracking and validation
   - Implements time limits and difficulty levels
   - Tracks player statistics

4. **IGameInterface.sol** - Interface for game interactions
   - Defines game session structure
   - Specifies events and function signatures

## 🎯 Game Mechanics

### Difficulty Levels
- **Easy**: 1,000 meters target distance
- **Medium**: 2,500 meters target distance  
- **Hard**: 5,000 meters target distance

### Game Rules
- Minimum wager: 10 tokens
- Maximum wager: 10,000 tokens
- Maximum game duration: 5 minutes (300 seconds)
- Reward multiplier: 2x (successful players)
- Fee percentage: 5% (failed players)

### Game Flow
1. Player starts game with wager amount and difficulty
2. Tokens are transferred to vault
3. Player updates distance as they progress
4. Game auto-completes when target distance is reached
5. Rewards are distributed (2x) or fees collected (5%)

## 🚀 Deployment

### Prerequisites
- Foundry installed
- Private key for deployment
- RPC URL for target network

### Deploy Commands
```bash
# Set environment variables
export PRIVATE_KEY="your_private_key"
export RPC_URL="your_rpc_url"

# Deploy contracts
forge script script/DeployGame.s.sol --rpc-url $RPC_URL --broadcast --verify
```

### Contract Addresses
After deployment, you'll get:
- GameToken address
- GameVault address  
- SubwaySurfersGame address

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-contract SubwaySurfersGameTest

# Run with gas reporting
forge test --gas-report

# Run with detailed output
forge test -vvv
```

### Test Coverage
- Game creation and completion
- Distance tracking and validation
- Reward distribution and fee collection
- Time limits and expiration
- Access control and permissions
- Edge cases and error handling

## 📊 Key Functions

### Starting a Game
```solidity
function startGame(
    uint256 wagerAmount,
    DifficultyLevel difficulty
) external returns (uint256 sessionId)
```

### Updating Distance
```solidity
function updateDistance(
    uint256 sessionId,
    uint256 newDistance
) external
```

### Completing a Game
```solidity
function completeGame(uint256 sessionId) external
```

### Abandoning a Game
```solidity
function abandonGame(uint256 sessionId) external
```

## 🔒 Security Features

- **ReentrancyGuard**: Prevents reentrancy attacks
- **Pausable**: Emergency pause functionality
- **Access Control**: Owner-only administrative functions
- **Input Validation**: Comprehensive parameter validation
- **Time Limits**: Prevents indefinite game sessions
- **Balance Checks**: Ensures sufficient funds before operations

## 📈 Statistics Tracking

The system tracks:
- Total games played
- Total tokens wagered
- Total rewards distributed
- Total fees collected
- Per-player statistics (games played, won, total wagered)

## 🛠️ Administration

### Owner Functions
- Update distance targets for difficulty levels
- Force complete expired games
- Pause/unpause contracts
- Emergency withdraw from vault

### Game Contract Functions
- Start new game sessions
- Update player distances
- Complete successful games
- Handle abandoned games

## 💡 Usage Examples

### Starting a Game
```javascript
// Start easy difficulty game with 100 tokens
const sessionId = await game.startGame(
    ethers.utils.parseEther("100"),
    DifficultyLevel.Easy
);
```

### Updating Distance
```javascript
// Update distance to 500 meters
await game.updateDistance(sessionId, 500);
```

### Checking Game Status
```javascript
// Get game session details
const session = await game.getGameSession(sessionId);
console.log("Current distance:", session.currentDistance);
console.log("Target distance:", session.targetDistance);
console.log("Status:", session.status);
```

## 🔧 Configuration

### Environment Variables
- `PRIVATE_KEY`: Deployer private key
- `RPC_URL`: Ethereum RPC endpoint
- `ETHERSCAN_API_KEY`: For contract verification

### Network Support
- Ethereum Mainnet
- Ethereum Sepolia Testnet
- Polygon
- Arbitrum
- Any EVM-compatible network

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## ⚠️ Disclaimer

This is a smart contract system for educational and experimental purposes. Use at your own risk. The developers are not responsible for any financial losses.

## 📞 Support

For questions or support, please open an issue in the repository or contact the development team.

---

**Happy Gaming! 🎮**