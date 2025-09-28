// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GameToken.sol";
import "../src/GameVault.sol";

contract GameVaultTest is Test {
    GameToken public gameToken;
    GameVault public gameVault;
    
    address public owner = address(0x1);
    address public player = address(0x2);
    address public gameContract = address(0x3);
    
    uint256 public constant INITIAL_BALANCE = 10000 * 10**18;
    uint256 public constant WAGER_AMOUNT = 100 * 10**18;
    
    function setUp() public {
        vm.startPrank(owner);
        gameToken = new GameToken();
        gameVault = new GameVault(address(gameToken));
        vm.stopPrank();
        
        // Mint tokens to player and game contract
        vm.startPrank(owner);
        gameToken.mint(player, INITIAL_BALANCE);
        gameToken.mint(gameContract, INITIAL_BALANCE);
        vm.stopPrank();
        
        // Set game contract for vault
        vm.startPrank(owner);
        gameVault.setGameContract(gameContract);
        vm.stopPrank();
        
        // Approve vault to spend tokens
        vm.startPrank(player);
        gameToken.approve(address(gameVault), type(uint256).max);
        vm.stopPrank();
        
        vm.startPrank(gameContract);
        gameToken.approve(address(gameVault), type(uint256).max);
        vm.stopPrank();
    }
    
    function testDepositTokens() public {
        vm.startPrank(gameContract);
        
        gameVault.depositTokens(player, WAGER_AMOUNT);
        
        assertEq(gameVault.getPlayerBalance(player), WAGER_AMOUNT);
        assertEq(gameVault.totalRewards(), WAGER_AMOUNT);
        assertEq(gameToken.balanceOf(address(gameVault)), WAGER_AMOUNT);
        
        vm.stopPrank();
    }
    
    function testDistributeRewards() public {
        vm.startPrank(gameContract);
        
        // First deposit tokens (this transfers from gameContract to vault)
        uint256 balanceBeforeDeposit = gameToken.balanceOf(player);
        gameVault.depositTokens(player, WAGER_AMOUNT);
        
        // Transfer additional tokens to vault for rewards
        gameToken.transfer(address(gameVault), WAGER_AMOUNT);
        
        uint256 balanceAfterDeposit = gameToken.balanceOf(player);
        
        // Distribute rewards (2x) - this gives player 2x the wager amount
        gameVault.distributeRewards(player, WAGER_AMOUNT);
        
        uint256 finalBalance = gameToken.balanceOf(player);
        // Player should have balance after deposit + WAGER_AMOUNT (net gain of WAGER_AMOUNT)
        // The distributeRewards function gives 2x the wager amount, so net gain is WAGER_AMOUNT
        uint256 expectedBalance = balanceAfterDeposit + (WAGER_AMOUNT * 2);
        
        assertEq(finalBalance, expectedBalance);
        assertEq(gameVault.getPlayerBalance(player), 0);
        assertEq(gameVault.totalRewards(), 0);
        
        vm.stopPrank();
    }
    
    function testCollectFees() public {
        vm.startPrank(gameContract);
        
        // First deposit tokens
        gameVault.depositTokens(player, WAGER_AMOUNT);
        
        uint256 initialBalance = gameToken.balanceOf(player);
        
        // Collect fees (5% fee)
        gameVault.collectFees(player, WAGER_AMOUNT);
        
        uint256 finalBalance = gameToken.balanceOf(player);
        uint256 expectedBalance = initialBalance; // No change in player balance
        
        assertEq(finalBalance, expectedBalance);
        assertEq(gameVault.getPlayerBalance(player), 0);
        assertEq(gameVault.totalFees(), WAGER_AMOUNT * 5 / 100);
        assertEq(gameVault.totalRewards(), WAGER_AMOUNT * 95 / 100); // Remaining goes to rewards
        
        vm.stopPrank();
    }
    
    function testOnlyGameContractCanCall() public {
        vm.startPrank(player);
        
        vm.expectRevert("Only game contract can call this");
        gameVault.depositTokens(player, WAGER_AMOUNT);
        
        vm.expectRevert("Only game contract can call this");
        gameVault.distributeRewards(player, WAGER_AMOUNT);
        
        vm.expectRevert("Only game contract can call this");
        gameVault.collectFees(player, WAGER_AMOUNT);
        
        vm.stopPrank();
    }
    
    function testInsufficientBalanceForRewards() public {
        vm.startPrank(gameContract);
        
        // Try to distribute rewards without depositing first
        vm.expectRevert("Insufficient player balance");
        gameVault.distributeRewards(player, WAGER_AMOUNT);
        
        vm.stopPrank();
    }
    
    function testInsufficientVaultBalance() public {
        vm.startPrank(gameContract);
        
        // Deposit small amount
        gameVault.depositTokens(player, WAGER_AMOUNT);
        
        // Try to distribute more than available
        vm.expectRevert("Insufficient player balance");
        gameVault.distributeRewards(player, WAGER_AMOUNT * 2);
        
        vm.stopPrank();
    }
    
    function testEmergencyWithdraw() public {
        vm.startPrank(gameContract);
        
        // Deposit tokens
        gameVault.depositTokens(player, WAGER_AMOUNT);
        vm.stopPrank();
        
        uint256 withdrawAmount = WAGER_AMOUNT / 2;
        uint256 initialOwnerBalance = gameToken.balanceOf(owner);
        
        vm.startPrank(owner);
        gameVault.emergencyWithdraw(withdrawAmount);
        vm.stopPrank();
        
        assertEq(gameToken.balanceOf(owner), initialOwnerBalance + withdrawAmount);
        assertEq(gameToken.balanceOf(address(gameVault)), WAGER_AMOUNT - withdrawAmount);
    }
    
    function testPauseUnpause() public {
        vm.startPrank(owner);
        
        // Pause vault
        gameVault.pause();
        
        // Try to deposit while paused (should fail)
        vm.startPrank(gameContract);
        vm.expectRevert();
        gameVault.depositTokens(player, WAGER_AMOUNT);
        vm.stopPrank();
        
        // Unpause vault
        vm.startPrank(owner);
        gameVault.unpause();
        vm.stopPrank();
        
        // Now deposit should work
        vm.startPrank(gameContract);
        gameVault.depositTokens(player, WAGER_AMOUNT);
        vm.stopPrank();
        
        assertEq(gameVault.getPlayerBalance(player), WAGER_AMOUNT);
    }
    
    function testVaultBalance() public {
        vm.startPrank(gameContract);
        
        gameVault.depositTokens(player, WAGER_AMOUNT);
        
        assertEq(gameVault.getVaultBalance(), WAGER_AMOUNT);
        
        vm.stopPrank();
    }
}
