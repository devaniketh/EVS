import Evs from 0x0000000000000007

/// Script to get game session details
access(all)
fun main(gameId: UInt64): Evs.GameSession? {
    return Evs.getGameSession(gameId: gameId)
}
