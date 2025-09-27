# Flow EVM Deployment Guide

This guide explains how to deploy the Subway Surfers Game contracts on Flow EVM.

## Prerequisites

1. **Flow CLI** (optional but recommended)
   ```bash
   sh -ci "$(curl -fsSL https://storage.googleapis.com/flow-cli/install.sh)"
   ```

2. **Foundry** (already installed)
   ```bash
   forge --version
   ```

3. **Private Key** for deployment account

## Flow EVM Network Information

### Testnet
- **RPC URL**: `https://testnet.evm.nodes.onflow.org`
- **Chain ID**: `545`
- **Block Explorer**: https://testnet.flowscan.org

### Mainnet
- **RPC URL**: `https://mainnet.evm.nodes.onflow.org`
- **Chain ID**: `747`
- **Block Explorer**: https://flowscan.org

## Deployment Steps

### 1. Set Environment Variables

Create a `.env` file with your configuration:

```bash
# Flow EVM Testnet
export FLOW_TESTNET_RPC_URL="https://testnet.evm.nodes.onflow.org"
export FLOW_TESTNET_CHAIN_ID="545"

# Flow EVM Mainnet
export FLOW_MAINNET_RPC_URL="https://mainnet.evm.nodes.onflow.org"
export FLOW_MAINNET_CHAIN_ID="747"

# Your private key (replace with actual key)
export PRIVATE_KEY="your_private_key_here"
```

### 2. Deploy to Flow EVM Testnet

```bash
# Deploy to Flow EVM Testnet
forge script script/DeployFlowEVM.s.sol \
  --rpc-url $FLOW_TESTNET_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key "your_etherscan_api_key" \
  --chain-id $FLOW_TESTNET_CHAIN_ID
```

### 3. Deploy to Flow EVM Mainnet

```bash
# Deploy to Flow EVM Mainnet
forge script script/DeployFlowEVM.s.sol \
  --rpc-url $FLOW_MAINNET_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key "your_etherscan_api_key" \
  --chain-id $FLOW_MAINNET_CHAIN_ID
```

## Contract Verification

After deployment, verify your contracts on Flow EVM:

```bash
# Verify GameToken
forge verify-contract <GAME_TOKEN_ADDRESS> \
  src/GameToken.sol:GameToken \
  --rpc-url $FLOW_TESTNET_RPC_URL \
  --etherscan-api-key "your_api_key"

# Verify GameVault
forge verify-contract <GAME_VAULT_ADDRESS> \
  src/GameVault.sol:GameVault \
  --rpc-url $FLOW_TESTNET_RPC_URL \
  --etherscan-api-key "your_api_key"

# Verify SubwaySurfersGame
forge verify-contract <GAME_ADDRESS> \
  src/SubwaySurfersGame.sol:SubwaySurfersGame \
  --rpc-url $FLOW_TESTNET_RPC_URL \
  --etherscan-api-key "your_api_key"
```

## Flow EVM Specific Features

### 1. Sponsored Transactions
Flow EVM supports sponsored transactions, allowing users to interact with your contracts without paying gas fees:

```javascript
// Example: Sponsored transaction for starting a game
const sponsoredTx = await flowEVM.sendTransaction({
  to: gameContractAddress,
  data: gameContract.interface.encodeFunctionData('startGame', [wagerAmount, difficulty]),
  // No gas price needed for sponsored transactions
});
```

### 2. Cross-VM Integration
Your contracts can interact with Flow's native Cadence contracts:

```solidity
// Example: Querying Flow account balance
interface IFlowAccount {
    function getBalance() external view returns (uint256);
}
```

### 3. Flow Data Sources Integration
Access Flow's real-time data sources:

```javascript
// Example: Using Flow data sources for game events
const gameEvents = await flowEVM.getEvents({
  address: gameContractAddress,
  topics: ['GameStarted', 'GameCompleted', 'GameFailed']
});
```

## Testing on Flow EVM

### 1. Run Tests
```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-contract SubwaySurfersGameTest
```

### 2. Local Testing
```bash
# Start local Flow EVM node (if available)
forge test --fork-url $FLOW_TESTNET_RPC_URL
```

## Monitoring and Analytics

### 1. Flow EVM Explorer
- Testnet: https://testnet.flowscan.org
- Mainnet: https://flowscan.org

### 2. Flow Data Sources
Monitor your contracts using Flow's data sources:
- Real-time transaction monitoring
- Event filtering and analysis
- Performance metrics

### 3. Flow Analytics
Track game statistics and user engagement:
- Total games played
- Success/failure rates
- Token distribution patterns
- User retention metrics

## Security Considerations

1. **Access Control**: Ensure proper ownership and permission management
2. **Reentrancy**: Use ReentrancyGuard for critical functions
3. **Pausable**: Implement emergency pause functionality
4. **Upgradeability**: Consider proxy patterns for future upgrades

## Gas Optimization

Flow EVM has different gas characteristics:
- Optimize for Flow EVM's gas model
- Use batch operations when possible
- Consider sponsored transactions for user interactions

## Support and Resources

- **Flow Documentation**: https://docs.onflow.org
- **Flow EVM Guide**: https://docs.onflow.org/evm
- **Flow Discord**: https://discord.gg/flow
- **Flow Forum**: https://forum.onflow.org

## Example Usage

After deployment, users can interact with your contracts:

```javascript
// Connect to Flow EVM
const flowEVM = new ethers.providers.JsonRpcProvider(FLOW_TESTNET_RPC_URL);

// Get contract instances
const gameToken = new ethers.Contract(gameTokenAddress, gameTokenABI, signer);
const game = new ethers.Contract(gameAddress, gameABI, signer);

// Start a game
const tx = await game.startGame(
  ethers.utils.parseEther("100"), // 100 tokens wager
  0 // Easy difficulty
);

// Update distance
await game.updateDistance(sessionId, 500); // 500 meters

// Complete game
await game.completeGame(sessionId);
```

## Troubleshooting

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
