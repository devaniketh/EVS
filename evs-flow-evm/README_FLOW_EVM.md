# Subway Surfers Game - Flow EVM Deployment

This project deploys the Subway Surfers Game smart contracts on Flow EVM, leveraging Flow's unique features like sponsored transactions and data sources.

## 🚀 Quick Start

### Prerequisites

1. **Foundry** (already installed)
2. **Private Key** for deployment
3. **Etherscan API Key** (for contract verification)

### Environment Setup

```bash
# Set your private key
export PRIVATE_KEY="your_private_key_here"

# Set Etherscan API key for verification
export ETHERSCAN_API_KEY="your_etherscan_api_key_here"
```

### Deploy to Flow EVM

```bash
# Deploy to Flow EVM Testnet
./deploy-flow.sh testnet

# Deploy to Flow EVM Mainnet
./deploy-flow.sh mainnet
```

## 📋 Flow EVM Features

### 1. Sponsored Transactions
Flow EVM supports sponsored transactions, allowing users to interact with your contracts without paying gas fees:

```javascript
// Example sponsored transaction
const sponsoredTx = await flowEVM.sendTransaction({
  to: gameContractAddress,
  data: gameContract.interface.encodeFunctionData('startGame', [wagerAmount, difficulty]),
  // No gas price needed for sponsored transactions
});
```

### 2. Flow Data Sources
Access real-time blockchain data and events:

```javascript
// Monitor game events
const events = await flowEVM.getEvents({
  address: gameContractAddress,
  topics: ['GameStarted', 'GameCompleted', 'GameFailed']
});
```

### 3. Cross-VM Integration
Interact with Flow's native Cadence contracts from EVM:

```solidity
// Example: Querying Flow account balance
interface IFlowAccount {
    function getBalance() external view returns (uint256);
}
```

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

## 🎮 Game Mechanics

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

## 🔧 Deployment Commands

### Manual Deployment

```bash
# Deploy to Flow EVM Testnet
forge script script/DeployFlowEVM.s.sol \
  --rpc-url https://testnet.evm.nodes.onflow.org \
  --broadcast \
  --verify \
  --chain-id 545

# Deploy to Flow EVM Mainnet
forge script script/DeployFlowEVM.s.sol \
  --rpc-url https://mainnet.evm.nodes.onflow.org \
  --broadcast \
  --verify \
  --chain-id 747
```

### Test Deployment

```bash
# Test deployed contracts
forge script script/TestFlowEVM.s.sol \
  --rpc-url https://testnet.evm.nodes.onflow.org \
  --chain-id 545
```

## 📊 Flow EVM Integration

### JavaScript Integration

```javascript
const { FlowEVMSubwaySurfers } = require('./flow-integration.js');

// Initialize
const subwaySurfers = new FlowEVMSubwaySurfers({
  gameToken: '0x...',
  gameVault: '0x...',
  game: '0x...'
}, true); // true for testnet

// Connect wallet
subwaySurfers.connectWallet('your_private_key');

// Start a game
const { sessionId } = await subwaySurfers.startGame(
  ethers.utils.parseEther('100'), // 100 tokens
  0 // Easy difficulty
);

// Update distance
await subwaySurfers.updateDistance(sessionId, 500);

// Complete game
await subwaySurfers.completeGame(sessionId);
```

### Event Monitoring

```javascript
// Monitor game events using Flow data sources
const events = await subwaySurfers.monitorGameEvents();
console.log('Recent events:', events);
```

## 🔒 Security Features

- **ReentrancyGuard**: Prevents reentrancy attacks
- **Pausable**: Emergency pause functionality
- **Access Control**: Owner-only administrative functions
- **Input Validation**: Comprehensive parameter validation
- **Balance Checks**: Ensures sufficient funds before operations

## 📈 Monitoring and Analytics

### Flow EVM Explorer
- **Testnet**: https://testnet.flowscan.org
- **Mainnet**: https://flowscan.org

### Flow Data Sources
- Real-time transaction monitoring
- Event filtering and analysis
- Performance metrics
- User engagement tracking

## 🧪 Testing

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-contract SubwaySurfersGameTest
```

## 🔧 Configuration

### Environment Variables

```bash
# Flow EVM Configuration
export FLOW_TESTNET_RPC_URL="https://testnet.evm.nodes.onflow.org"
export FLOW_MAINNET_RPC_URL="https://mainnet.evm.nodes.onflow.org"
export PRIVATE_KEY="your_private_key_here"
export ETHERSCAN_API_KEY="your_etherscan_api_key_here"
```

### Network Support
- Flow EVM Testnet (Chain ID: 545)
- Flow EVM Mainnet (Chain ID: 747)
- Any EVM-compatible network

## 📝 Contract Verification

After deployment, verify your contracts:

```bash
# Verify GameToken
forge verify-contract <GAME_TOKEN_ADDRESS> \
  src/GameToken.sol:GameToken \
  --rpc-url https://testnet.evm.nodes.onflow.org \
  --etherscan-api-key "your_api_key"

# Verify GameVault
forge verify-contract <GAME_VAULT_ADDRESS> \
  src/GameVault.sol:GameVault \
  --rpc-url https://testnet.evm.nodes.onflow.org \
  --etherscan-api-key "your_api_key"

# Verify SubwaySurfersGame
forge verify-contract <GAME_ADDRESS> \
  src/SubwaySurfersGame.sol:SubwaySurfersGame \
  --rpc-url https://testnet.evm.nodes.onflow.org \
  --etherscan-api-key "your_api_key"
```

## 🚀 Flow EVM Advantages

### 1. Sponsored Transactions
- Users can interact without paying gas fees
- Improved user experience
- Lower barrier to entry

### 2. Flow Data Sources
- Real-time blockchain data access
- Advanced event filtering
- Performance analytics

### 3. Cross-VM Integration
- Interact with Flow's native Cadence contracts
- Access Flow's ecosystem
- Leverage Flow's developer tools

### 4. High Performance
- Fast transaction processing
- Low latency
- High throughput

## 📞 Support and Resources

- **Flow Documentation**: https://docs.onflow.org
- **Flow EVM Guide**: https://docs.onflow.org/evm
- **Flow Discord**: https://discord.gg/flow
- **Flow Forum**: https://forum.onflow.org

## 🔍 Troubleshooting

### Common Issues

1. **Gas Estimation Failed**: Increase gas limit
2. **Transaction Reverted**: Check contract state and parameters
3. **Verification Failed**: Ensure correct constructor arguments

### Debug Commands

```bash
# Check deployment status
forge script script/DeployFlowEVM.s.sol --rpc-url $FLOW_TESTNET_RPC_URL --dry-run

# Debug specific transaction
cast tx <TX_HASH> --rpc-url $FLOW_TESTNET_RPC_URL

# Check contract state
cast call <CONTRACT_ADDRESS> "functionName()" --rpc-url $FLOW_TESTNET_RPC_URL
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

---

**Ready to deploy on Flow EVM! 🚀**

The Subway Surfers Game is now fully integrated with Flow EVM, leveraging Flow's unique features for an enhanced gaming experience.
