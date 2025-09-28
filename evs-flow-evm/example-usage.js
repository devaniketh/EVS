/**
 * Example Usage of Subway Surfers Game on Flow EVM
 * This file demonstrates how to interact with the deployed contracts
 */

const { ethers } = require('ethers');

// Flow EVM Configuration
const FLOW_TESTNET_RPC = 'https://testnet.evm.nodes.onflow.org';
const FLOW_MAINNET_RPC = 'https://mainnet.evm.nodes.onflow.org';

// Contract ABIs (simplified for example)
const GAME_TOKEN_ABI = [
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
  "function totalSupply() view returns (uint256)",
  "function balanceOf(address) view returns (uint256)",
  "function approve(address,uint256) returns (bool)",
  "function transfer(address,uint256) returns (bool)",
  "function mint(address,uint256) external"
];

const GAME_ABI = [
  "function startGame(uint256,uint8) returns (uint256)",
  "function updateDistance(uint256,uint256)",
  "function completeGame(uint256)",
  "function abandonGame(uint256)",
  "function getGameSession(uint256) view returns (tuple(address,uint256,uint256,uint256,uint256,uint256,uint8,uint8,bool))",
  "function getGameStats() view returns (uint256,uint256,uint256,uint256)",
  "function getPlayerStats(address) view returns (uint256,uint256,uint256)",
  "event GameStarted(address indexed player, uint256 indexed sessionId, uint256 wagerAmount, uint256 targetDistance, uint8 difficulty)",
  "event GameCompleted(address indexed player, uint256 indexed sessionId, uint256 finalDistance, uint256 rewardAmount)",
  "event GameFailed(address indexed player, uint256 indexed sessionId, uint256 finalDistance, uint256 feeAmount)"
];

// Example contract addresses (replace with your deployed addresses)
const CONTRACT_ADDRESSES = {
  testnet: {
    gameToken: '0x0000000000000000000000000000000000000000', // Replace with actual address
    gameVault: '0x0000000000000000000000000000000000000000', // Replace with actual address
    game: '0x0000000000000000000000000000000000000000'       // Replace with actual address
  },
  mainnet: {
    gameToken: '0x0000000000000000000000000000000000000000', // Replace with actual address
    gameVault: '0x0000000000000000000000000000000000000000', // Replace with actual address
    game: '0x0000000000000000000000000000000000000000'       // Replace with actual address
  }
};

class SubwaySurfersExample {
  constructor(network = 'testnet') {
    this.network = network;
    this.rpcUrl = network === 'testnet' ? FLOW_TESTNET_RPC : FLOW_MAINNET_RPC;
    this.provider = new ethers.providers.JsonRpcProvider(this.rpcUrl);
    this.addresses = CONTRACT_ADDRESSES[network];
    
    // Initialize contracts
    this.gameToken = new ethers.Contract(
      this.addresses.gameToken,
      GAME_TOKEN_ABI,
      this.provider
    );
    
    this.game = new ethers.Contract(
      this.addresses.game,
      GAME_ABI,
      this.provider
    );
  }

  /**
   * Connect with a wallet for transactions
   */
  connectWallet(privateKey) {
    this.wallet = new ethers.Wallet(privateKey, this.provider);
    this.gameToken = this.gameToken.connect(this.wallet);
    this.game = this.game.connect(this.wallet);
    console.log('Wallet connected:', this.wallet.address);
  }

  /**
   * Get contract information
   */
  async getContractInfo() {
    console.log('\n=== Contract Information ===');
    
    try {
      const tokenName = await this.gameToken.name();
      const tokenSymbol = await this.gameToken.symbol();
      const tokenDecimals = await this.gameToken.decimals();
      const totalSupply = await this.gameToken.totalSupply();
      
      console.log('Token Name:', tokenName);
      console.log('Token Symbol:', tokenSymbol);
      console.log('Token Decimals:', tokenDecimals);
      console.log('Total Supply:', ethers.utils.formatEther(totalSupply), 'tokens');
      
      const stats = await this.game.getGameStats();
      console.log('\nGame Statistics:');
      console.log('Total Games:', stats.totalGames.toString());
      console.log('Total Wagered:', ethers.utils.formatEther(stats.totalWagered), 'tokens');
      console.log('Total Rewards:', ethers.utils.formatEther(stats.totalRewards), 'tokens');
      console.log('Total Fees:', ethers.utils.formatEther(stats.totalFees), 'tokens');
      
    } catch (error) {
      console.error('Error getting contract info:', error.message);
    }
  }

  /**
   * Get player information
   */
  async getPlayerInfo(playerAddress) {
    console.log('\n=== Player Information ===');
    
    try {
      const balance = await this.gameToken.balanceOf(playerAddress);
      const stats = await this.game.getPlayerStats(playerAddress);
      
      console.log('Player Address:', playerAddress);
      console.log('Token Balance:', ethers.utils.formatEther(balance), 'tokens');
      console.log('Games Played:', stats[0].toString());
      console.log('Games Won:', stats[1].toString());
      console.log('Total Wagered:', ethers.utils.formatEther(stats[2]), 'tokens');
      
    } catch (error) {
      console.error('Error getting player info:', error.message);
    }
  }

  /**
   * Start a new game
   */
  async startGame(wagerAmount, difficulty) {
    console.log('\n=== Starting Game ===');
    
    try {
      // Check if player has enough tokens
      const balance = await this.gameToken.balanceOf(this.wallet.address);
      if (balance.lt(wagerAmount)) {
        console.log('Insufficient token balance. Minting tokens...');
        // Note: In a real scenario, you would need to mint tokens or get them from somewhere
        console.log('Please ensure you have enough tokens to start the game');
        return null;
      }

      // Approve tokens
      console.log('Approving tokens...');
      const approveTx = await this.gameToken.approve(this.addresses.game, wagerAmount);
      await approveTx.wait();
      console.log('Tokens approved');

      // Start the game
      console.log('Starting game...');
      const tx = await this.game.startGame(wagerAmount, difficulty);
      const receipt = await tx.wait();
      
      // Extract game session ID from event
      const event = receipt.events.find(e => e.event === 'GameStarted');
      const sessionId = event.args.sessionId;
      
      console.log('Game started successfully!');
      console.log('Session ID:', sessionId.toString());
      console.log('Wager Amount:', ethers.utils.formatEther(wagerAmount), 'tokens');
      console.log('Difficulty:', difficulty);
      
      return sessionId;
      
    } catch (error) {
      console.error('Error starting game:', error.message);
      return null;
    }
  }

  /**
   * Update game distance
   */
  async updateDistance(sessionId, newDistance) {
    console.log(`\n=== Updating Distance to ${newDistance}m ===`);
    
    try {
      const tx = await this.game.updateDistance(sessionId, newDistance);
      await tx.wait();
      console.log('Distance updated successfully!');
      return tx.hash;
    } catch (error) {
      console.error('Error updating distance:', error.message);
      return null;
    }
  }

  /**
   * Complete a game
   */
  async completeGame(sessionId) {
    console.log('\n=== Completing Game ===');
    
    try {
      const tx = await this.game.completeGame(sessionId);
      const receipt = await tx.wait();
      
      // Check if game was completed successfully
      const event = receipt.events.find(e => e.event === 'GameCompleted');
      if (event) {
        console.log('Game completed successfully!');
        console.log('Final Distance:', event.args.finalDistance.toString(), 'm');
        console.log('Reward Amount:', ethers.utils.formatEther(event.args.rewardAmount), 'tokens');
        return { success: true, reward: event.args.rewardAmount };
      } else {
        console.log('Game may have failed or been abandoned');
        return { success: false };
      }
    } catch (error) {
      console.error('Error completing game:', error.message);
      return null;
    }
  }

  /**
   * Abandon a game
   */
  async abandonGame(sessionId) {
    console.log('\n=== Abandoning Game ===');
    
    try {
      const tx = await this.game.abandonGame(sessionId);
      const receipt = await tx.wait();
      
      const event = receipt.events.find(e => e.event === 'GameFailed');
      if (event) {
        console.log('Game abandoned');
        console.log('Final Distance:', event.args.finalDistance.toString(), 'm');
        console.log('Fee Amount:', ethers.utils.formatEther(event.args.feeAmount), 'tokens');
        return { fee: event.args.feeAmount };
      }
    } catch (error) {
      console.error('Error abandoning game:', error.message);
      return null;
    }
  }

  /**
   * Get game session details
   */
  async getGameSession(sessionId) {
    try {
      const session = await this.game.getGameSession(sessionId);
      return {
        player: session.player,
        wagerAmount: session.wagerAmount,
        targetDistance: session.targetDistance,
        currentDistance: session.currentDistance,
        startTime: session.startTime,
        endTime: session.endTime,
        status: session.status,
        difficulty: session.difficulty,
        isActive: session.isActive
      };
    } catch (error) {
      console.error('Error getting game session:', error.message);
      return null;
    }
  }

  /**
   * Simulate a complete game
   */
  async simulateGame() {
    console.log('\n=== Simulating Complete Game ===');
    
    try {
      // Get initial balance
      const initialBalance = await this.gameToken.balanceOf(this.wallet.address);
      console.log('Initial Balance:', ethers.utils.formatEther(initialBalance), 'tokens');
      
      // Start game with 100 tokens wager, Easy difficulty
      const wagerAmount = ethers.utils.parseEther('100');
      const difficulty = 0; // Easy
      
      const sessionId = await this.startGame(wagerAmount, difficulty);
      if (!sessionId) {
        console.log('Failed to start game');
        return;
      }
      
      // Simulate distance updates
      const distances = [250, 500, 750, 1000]; // Easy target is 1000m
      
      for (const distance of distances) {
        await this.updateDistance(sessionId, distance);
        await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second
      }
      
      // Complete the game
      const result = await this.completeGame(sessionId);
      
      // Get final balance
      const finalBalance = await this.gameToken.balanceOf(this.wallet.address);
      console.log('Final Balance:', ethers.utils.formatEther(finalBalance), 'tokens');
      console.log('Net Change:', ethers.utils.formatEther(finalBalance.sub(initialBalance)), 'tokens');
      
      return result;
      
    } catch (error) {
      console.error('Error simulating game:', error.message);
    }
  }
}

// Example usage
async function main() {
  console.log('Subway Surfers Game - Flow EVM Example');
  console.log('=====================================');
  
  // Initialize the example
  const subwaySurfers = new SubwaySurfersExample('testnet');
  
  // Connect with a wallet (replace with your private key)
  const privateKey = process.env.PRIVATE_KEY || 'your_private_key_here';
  if (privateKey === 'your_private_key_here') {
    console.log('Please set your PRIVATE_KEY environment variable');
    return;
  }
  
  subwaySurfers.connectWallet(privateKey);
  
  try {
    // Get contract information
    await subwaySurfers.getContractInfo();
    
    // Get player information
    await subwaySurfers.getPlayerInfo(subwaySurfers.wallet.address);
    
    // Simulate a complete game
    await subwaySurfers.simulateGame();
    
  } catch (error) {
    console.error('Example failed:', error.message);
  }
}

// Run the example
if (require.main === module) {
  main().catch(console.error);
}

module.exports = SubwaySurfersExample;
