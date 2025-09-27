import Evs from 0x0000000000000007

/// Transaction to set the admin address for the contract
transaction(adminAddress: Address) {
    
    execute {
        Evs.setAdmin(admin: adminAddress)
        
        log("Admin set to: ".concat(adminAddress.toString()))
    }
}
