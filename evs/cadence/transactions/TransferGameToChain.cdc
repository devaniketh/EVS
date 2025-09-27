import Evs from 0x0000000000000007

/// Transaction to transfer a game session to another blockchain
transaction(gameId: UInt64, targetChain: String, targetAddress: String) {
    
    execute {
        // Transfer the game to another chain
        let bridgeId = Evs.transferGameToChain(
            gameId: gameId,
            targetChain: targetChain,
            targetAddress: targetAddress
        )
        
        log("Game transferred to chain: ".concat(targetChain))
        log("Target address: ".concat(targetAddress))
        log("Bridge ID: ".concat(bridgeId.toString()))
        log("Game ID: ".concat(gameId.toString()))
    }
}
