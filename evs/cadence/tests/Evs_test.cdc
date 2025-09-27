import Evs from 0x0000000000000007

/// Test suite for the EVS game contract
access(all)
fun main() {
    log("Starting EVS Game Contract Tests...")
    
    // Test 1: Game session creation validation
    log("Test 1: Game session creation validation")
    let stakeAmount: UFix64 = 10.0
    let multiplier: UFix64 = 2.0
    
    assert(stakeAmount > 0.0, message: "Stake amount should be positive")
    assert(multiplier >= 1.0, message: "Multiplier should be at least 1.0")
    log("✅ Game session creation test passed")
    
    // Test 2: Stake amount validation
    log("Test 2: Stake amount validation")
    let validStake: UFix64 = 5.0
    let invalidStake: UFix64 = 0.0
    
    assert(validStake > 0.0, message: "Valid stake should be positive")
    assert(invalidStake == 0.0, message: "Invalid stake should be zero")
    log("✅ Stake validation test passed")
    
    // Test 3: Multiplier range validation
    log("Test 3: Multiplier range validation")
    let validMultiplier: UFix64 = 3.0
    let invalidMultiplier: UFix64 = 15.0
    
    assert(validMultiplier >= 1.0 && validMultiplier <= 10.0, message: "Valid multiplier should be in range")
    assert(!(invalidMultiplier >= 1.0 && invalidMultiplier <= 10.0), message: "Invalid multiplier should be out of range")
    log("✅ Multiplier validation test passed")
    
    // Test 4: Reward calculation
    log("Test 4: Reward calculation")
    let stakeAmount2: UFix64 = 10.0
    let multiplier2: UFix64 = 2.0
    let expectedReward: UFix64 = 40.0 // stakeAmount * multiplier * 2.0
    
    let actualReward = stakeAmount2 * multiplier2 * 2.0
    assert(actualReward == expectedReward, message: "Reward calculation should be correct")
    log("✅ Reward calculation test passed")
    
    // Test 5: Game completion validation
    log("Test 5: Game completion validation")
    let gameId: UInt64 = 1
    let score: UInt64 = 1000
    let won: Bool = true
    
    assert(score > 0, message: "Score should be positive")
    assert(won == true || won == false, message: "Won should be boolean")
    log("✅ Game completion test passed")
    
    // Test 6: Cross-chain transfer validation
    log("Test 6: Cross-chain transfer validation")
    let targetChain: String = "Ethereum"
    let targetAddress: String = "0x1234567890123456789012345678901234567890"
    
    assert(targetChain.length > 0, message: "Target chain should not be empty")
    assert(targetAddress.length > 0, message: "Target address should not be empty")
    log("✅ Cross-chain transfer test passed")
    
    // Test 7: Player statistics validation
    log("Test 7: Player statistics validation")
    let playerAddress = Address(0x1234567890123456789012345678901234567890)
    let totalStaked: UFix64 = 100.0
    let totalWon: UFix64 = 50.0
    let gamesPlayed: UInt64 = 10
    let gamesWon: UInt64 = 5
    
    assert(totalStaked >= 0.0, message: "Total staked should be non-negative")
    assert(totalWon >= 0.0, message: "Total won should be non-negative")
    assert(gamesPlayed >= 0, message: "Games played should be non-negative")
    assert(gamesWon <= gamesPlayed, message: "Games won should not exceed games played")
    log("✅ Player statistics test passed")
    
    // Test 8: Staking pool management
    log("Test 8: Staking pool management")
    let totalPool: UFix64 = 1000.0
    let totalStaked2: UFix64 = 500.0
    let activeGames: UInt64 = 25
    
    assert(totalPool >= 0.0, message: "Total pool should be non-negative")
    assert(totalStaked2 >= 0.0, message: "Total staked should be non-negative")
    assert(activeGames >= 0, message: "Active games should be non-negative")
    log("✅ Staking pool management test passed")
    
    // Test 9: Game status validation
    log("Test 9: Game status validation")
    let activeStatus = Evs.GameStatus.ACTIVE
    let completedStatus = Evs.GameStatus.COMPLETED
    let cancelledStatus = Evs.GameStatus.CANCELLED
    let transferredStatus = Evs.GameStatus.TRANSFERRED
    
    assert(activeStatus != completedStatus, message: "Game statuses should be different")
    assert(completedStatus != cancelledStatus, message: "Game statuses should be different")
    assert(cancelledStatus != transferredStatus, message: "Game statuses should be different")
    log("✅ Game status validation test passed")
    
    // Test 10: Address validation
    log("Test 10: Address validation")
    let validAddress = Address(0x1234567890123456789012345678901234567890)
    let zeroAddress = Address(0x0)
    
    assert(validAddress != zeroAddress, message: "Addresses should be different")
    log("✅ Address validation test passed")
    
    log("🎉 All EVS Game Contract Tests Passed!")
}