import Evs from 0x0000000000000007

/// Script to get all active games for a player
access(all)
fun main(player: Address): [UInt64] {
    return Evs.getActiveGames(player: player)
}
