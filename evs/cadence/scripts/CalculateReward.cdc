import Evs from 0x0000000000000007

/// Script to calculate potential reward for a stake amount
access(all)
fun main(stakeAmount: UFix64, multiplier: UFix64): UFix64 {
    return Evs.calculatePotentialReward(stakeAmount: stakeAmount, multiplier: multiplier)
}
