/**
 * Flow EVM Integration Example
 * This file demonstrates how to integrate the Subway Surfers Game with Flow EVM
 * using Flow's data sources and sponsored transactions.
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
  "function transfer(address,uint256) returns (bool)"
];

const GAME_ABI = [
  "function startGame(uint256,uint8) returns (uint256)",
  "function updateDistance(uint256,uint256)",
  "function completeGame(uint256)",
  "function abandonGame(uint256)",
  "function getGameSession(uint256) view returns (tuple(address,uint256,uint256,uint256,uint256,uint256,uint8,uint8,bool))",
  "function getGameStats() view returns (uint256,uint256,uint256,uint256)",
  "event GameStarted(address indexed player, uint256 indexed sessionId, uint256 wagerAmount, uint256 targetDistance, uint8 difficulty)",
  "event GameCompleted(address indexed player, uint256 indexed sessionId, uint256 finalDistance, uint256 rewardAmount)",
  "event GameFailed(address indexed player, uint256 indexed sessionId, uint256 finalDistance, uint256 feeAmount)"
];

class FlowEVMSubwaySurfers {
  constructor(contractAddresses, isTestnet = true) {
    this.rpcUrl = isTestnet ? FLOW_TESTNET_RPC : FLOW_MAINNET_RPC;
    this.provider = new ethers.providers.JsonRpcProvider(this.rpcUrl);
    this.contractAddresses = contractAddresses;
    
    // Initialize contracts
    this.gameToken = new ethers.Contract(
      contractAddresses.gameToken,
      GAME_TOKEN_ABI,
      this.provider
    );
    
    this.game = new ethers.Contract(
      contractAddresses.game,
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
  }

  /**
   * Start a new game with sponsored transaction support
   */
  async startGame(wagerAmount, difficulty, useSponsoredTx = false) {
    try {
      // Approve tokens if not using sponsored transaction
      if (!useSponsoredTx) {
        const approveTx = await this.gameToken.approve(
          this.contractAddresses.game,
          wagerAmount
        );
        await approveTx.wait();
      }

      // Start the game
      const tx = await this.game.startGame(wagerAmount, difficulty);
      const receipt = await tx.wait();
      
      // Extract game session ID from event
      const event = receipt.events.find(e => e.event === 'GameStarted');
      const sessionId = event.args.sessionId;
      
      console.log(`Game started with session ID: ${sessionId}`);
      return { sessionId, txHash: tx.hash };
    } catch (error) {
      console.error('Error starting game:', error);
      throw error;
    }
  }

  /**
   * Update game distance
   */
  async updateDistance(sessionId, newDistance) {
    try {
      const tx = await this.game.updateDistance(sessionId, newDistance);
      await tx.wait();
      console.log(`Distance updated to ${newDistance}m for session ${sessionId}`);
      return tx.hash;
    } catch (error) {
      console.error('Error updating distance:', error);
      throw error;
    }
  }

  /**
   * Complete a game
   */
  async completeGame(sessionId) {
    try {
      const tx = await this.game.completeGame(sessionId);
      const receipt = await tx.wait();
      
      // Check if game was completed successfully
      const event = receipt.events.find(e => e.event === 'GameCompleted');
      if (event) {
        console.log(`Game completed! Reward: ${ethers.utils.formatEther(event.args.rewardAmount)} tokens`);
        return { success: true, reward: event.args.rewardAmount };
      } else {
        console.log('Game may have failed or been abandoned');
        return { success: false };
      }
    } catch (error) {
      console.error('Error completing game:', error);
      throw error;
    }
  }

  /**
   * Abandon a game
   */
  async abandonGame(sessionId) {
    try {
      const tx = await this.game.abandonGame(sessionId);
      const receipt = await tx.wait();
      
      const event = receipt.events.find(e => e.event === 'GameFailed');
      if (event) {
        console.log(`Game abandoned. Fee: ${ethers.utils.formatEther(event.args.feeAmount)} tokens`);
        return { fee: event.args.feeAmount };
      }
    } catch (error) {
      console.error('Error abandoning game:', error);
      throw error;
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
      console.error('Error getting game session:', error);
      throw error;
    }
  }

  /**
   * Get game statistics
   */
  async getGameStats() {
    try {
      const stats = await this.game.getGameStats();
      return {
        totalGames: stats.totalGames,
        totalWagered: ethers.utils.formatEther(stats.totalWagered),
        totalRewards: ethers.utils.formatEther(stats.totalRewards),
        totalFees: ethers.utils.formatEther(stats.totalFees)
      };
    } catch (error) {
      console.error('Error getting game stats:', error);
      throw error;
    }
  }

  /**
   * Monitor game events using Flow data sources
   */
  async monitorGameEvents(fromBlock = 'latest', toBlock = 'latest') {
    try {
      const filter = {
        address: this.contractAddresses.game,
        topics: [
          [
            ethers.utils.id('GameStarted(address,uint256,uint256,uint256,uint8)'),
            ethers.utils.id('GameCompleted(address,uint256,uint256,uint256)'),
            ethers.utils.id('GameFailed(address,uint256,uint256,uint256)')
          ]
        ],
        fromBlock,
        toBlock
      };

      const logs = await this.provider.getLogs(filter);
      
      return logs.map(log => {
        const parsed = this.game.interface.parseLog(log);
        return {
          event: parsed.name,
          args: parsed.args,
          blockNumber: log.blockNumber,
          transactionHash: log.transactionHash
        };
      });
    } catch (error) {
      console.error('Error monitoring events:', error);
      throw error;
    }
  }

  /**
   * Get player statistics
   */
  async getPlayerStats(playerAddress) {
    try {
      const balance = await this.gameToken.balanceOf(playerAddress);
      return {
        tokenBalance: ethers.utils.formatEther(balance),
        address: playerAddress
      };
    } catch (error) {
      console.error('Error getting player stats:', error);
      throw error;
    }
  }

  /**
   * Create a sponsored transaction (Flow EVM specific)
   * This would typically be handled by Flow's sponsored transaction service
   */
  async createSponsoredTransaction(transactionData) {
    // This is a placeholder for Flow's sponsored transaction implementation
    // In practice, you would integrate with Flow's sponsored transaction service
    console.log('Creating sponsored transaction:', transactionData);
    
    // Example sponsored transaction payload
    return {
      type: 'sponsored',
      data: transactionData,
      gasLimit: '30000000',
      // No gas price for sponsored transactions
    };
  }
}

// Example usage
async function example() {
  // Contract addresses (replace with your deployed addresses)
  const contractAddresses = {
    gameToken: '0x...', // Replace with actual GameToken address
    gameVault: '0x...', // Replace with actual GameVault address
    game: '0x...'       // Replace with actual SubwaySurfersGame address
  };

  // Initialize the integration
  const subwaySurfers = new FlowEVMSubwaySurfers(contractAddresses, true); // true for testnet

  // Connect with a wallet (replace with actual private key)
  const privateKey = 'your_private_key_here';
  subwaySurfers.connectWallet(privateKey);

  try {
    // Get initial stats
    console.log('Initial game stats:', await subwaySurfers.getGameStats());

    // Start a game
    const wagerAmount = ethers.utils.parseEther('100'); // 100 tokens
    const difficulty = 0; // Easy
    const { sessionId } = await subwaySurfers.startGame(wagerAmount, difficulty);

    // Simulate distance updates
    await subwaySurfers.updateDistance(sessionId, 250);
    await subwaySurfers.updateDistance(sessionId, 500);
    await subwaySurfers.updateDistance(sessionId, 750);
    await subwaySurfers.updateDistance(sessionId, 1000); // Target reached

    // Complete the game
    const result = await subwaySurfers.completeGame(sessionId);
    console.log('Game result:', result);

    // Monitor events
    const events = await subwaySurfers.monitorGameEvents();
    console.log('Recent events:', events);

  } catch (error) {
    console.error('Example failed:', error);
  }
}

// Export for use in other modules
module.exports = {
  FlowEVMSubwaySurfers,
  FLOW_TESTNET_RPC,
  FLOW_MAINNET_RPC
};

// Run example if this file is executed directly
if (require.main === module) {
  example();
}
