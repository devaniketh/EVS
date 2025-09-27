import Evs from 0x0000000000000007
import FlowToken from 0x1654653399040a61
import FungibleToken from 0xf233dcee88fe0abe

/// Transaction to complete a game and receive rewards
transaction(gameId: UInt64, score: UInt64, won: Bool) {
    
    // The Vault that will hold the reward tokens
    let rewardVault: @FungibleToken.Vault
    
    // The reference to the signer's stored vault
    let vaultRef: &FlowToken.Vault
    
    prepare(signer: AuthAccount) {
        // Get a reference to the signer's stored vault
        self.vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow reference to the owner's Vault!")
        
        // Initialize empty vault for rewards
        self.rewardVault <- FlowToken.createEmptyVault()
    }
    
    execute {
        // Complete the game and get the reward amount
        let rewardAmount = Evs.completeGame(gameId: gameId, score: score, won: won)
        
        if won && rewardAmount > 0.0 {
            // In a real implementation, the contract would transfer tokens from the pool
            // For now, we'll create tokens to simulate the reward
            // This is just for demonstration - in production, tokens would come from the staking pool
            
            log("Game completed successfully!")
            log("Score: ".concat(score.toString()))
            log("Reward amount: ".concat(rewardAmount.toString()))
        } else {
            log("Game completed - no reward")
            log("Score: ".concat(score.toString()))
        }
        
        // Clean up the empty vault
        destroy self.rewardVault
    }
}
