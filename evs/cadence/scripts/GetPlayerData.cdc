import Evs from 0x0000000000000007

/// Script to get player statistics and data
access(all)
fun main(player: Address): Evs.PlayerData? {
    return Evs.getPlayerData(player: player)
}
