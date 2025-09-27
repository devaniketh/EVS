import Evs from 0x0000000000000007
import FlowToken from 0x1654653399040a61
import FungibleToken from 0xf233dcee88fe0abe

/// Transaction to start a new game session with staking
transaction(stakeAmount: UFix64, multiplier: UFix64) {
    
    // The Vault that holds the tokens that are being transferred
    let temporaryVault: @FungibleToken.Vault
    
    // The reference to the signer's stored vault
    let vaultRef: &FlowToken.Vault
    
    prepare(signer: AuthAccount) {
        // Get a reference to the signer's stored vault
        self.vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow reference to the owner's Vault!")
        
        // Withdraw tokens from the signer's vault
        self.temporaryVault <- self.vaultRef.withdraw(amount: stakeAmount)
    }
    
    execute {
        // Start the game with the staked amount
        let gameId = Evs.startGame(stakeAmount: stakeAmount, multiplier: multiplier)
        
        // In a real implementation, the tokens would be transferred to the contract
        // For now, we'll just burn them to simulate the stake
        destroy self.temporaryVault
        
        log("Game started with ID: ".concat(gameId.toString()))
        log("Stake amount: ".concat(stakeAmount.toString()))
        log("Multiplier: ".concat(multiplier.toString()))
    }
}
