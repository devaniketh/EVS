import Evs from 0x0000000000000007

/// Script to get staking pool information
access(all)
fun main(): Evs.StakingPool {
    return Evs.getStakingPool()
}
