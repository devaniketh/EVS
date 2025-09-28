// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title GameVault
 * @dev Vault contract for managing game rewards and fees
 */
contract GameVault is Ownable, ReentrancyGuard, Pausable {
    IERC20 public gameToken;
    
    uint256 public totalRewards;
    uint256 public totalFees;
    uint256 public constant FEE_PERCENTAGE = 5; // 5% fee on failed games
    uint256 public constant REWARD_MULTIPLIER = 2; // 2x reward for successful games
    
    mapping(address => uint256) public playerRewards;
    mapping(address => uint256) public playerFees;
    
    event TokensDeposited(address indexed player, uint256 amount);
    event RewardsDistributed(address indexed player, uint256 amount);
    event FeesCollected(address indexed player, uint256 amount);
    event EmergencyWithdraw(address indexed owner, uint256 amount);
    
    constructor(address _gameToken) Ownable(msg.sender) {
        gameToken = IERC20(_gameToken);
    }
    
    address public gameContract;
    
    modifier onlyGameContract() {
        require(msg.sender == gameContract || msg.sender == owner(), "Only game contract can call this");
        _;
    }
    
    function setGameContract(address _gameContract) external onlyOwner {
        gameContract = _gameContract;
    }
    
    /**
     * @dev Deposit tokens from a player (called when they start a game)
     * @param player Address of the player
     * @param amount Amount of tokens to deposit
     */
    function depositTokens(address player, uint256 amount) external onlyGameContract whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(gameToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        playerRewards[player] += amount;
        totalRewards += amount;
        
        emit TokensDeposited(player, amount);
    }
    
    /**
     * @dev Distribute rewards to a winning player
     * @param player Address of the winning player
     * @param wagerAmount Original wager amount
     */
    function distributeRewards(address player, uint256 wagerAmount) external onlyGameContract whenNotPaused nonReentrant {
        uint256 rewardAmount = wagerAmount * REWARD_MULTIPLIER;
        require(playerRewards[player] >= wagerAmount, "Insufficient player balance");
        require(gameToken.balanceOf(address(this)) >= rewardAmount, "Insufficient vault balance");
        
        // Deduct the original wager from player's balance
        playerRewards[player] -= wagerAmount;
        totalRewards -= wagerAmount;
        
        // Transfer 2x reward to player
        require(gameToken.transfer(player, rewardAmount), "Reward transfer failed");
        
        emit RewardsDistributed(player, rewardAmount);
    }
    
    /**
     * @dev Collect fees from a losing player
     * @param player Address of the losing player
     * @param wagerAmount Original wager amount
     */
    function collectFees(address player, uint256 wagerAmount) external onlyGameContract whenNotPaused nonReentrant {
        uint256 feeAmount = (wagerAmount * FEE_PERCENTAGE) / 100;
        uint256 remainingAmount = wagerAmount - feeAmount;
        
        require(playerRewards[player] >= wagerAmount, "Insufficient player balance");
        
        // Deduct the wager from player's balance
        playerRewards[player] -= wagerAmount;
        totalRewards -= wagerAmount;
        
        // Add fee to total fees
        playerFees[player] += feeAmount;
        totalFees += feeAmount;
        
        // The remaining amount stays in the vault for future rewards
        totalRewards += remainingAmount;
        
        emit FeesCollected(player, feeAmount);
    }
    
    /**
     * @dev Get the total balance available for rewards
     * @return Total balance in the vault
     */
    function getVaultBalance() external view returns (uint256) {
        return gameToken.balanceOf(address(this));
    }
    
    /**
     * @dev Get player's current reward balance
     * @param player Address of the player
     * @return Player's reward balance
     */
    function getPlayerBalance(address player) external view returns (uint256) {
        return playerRewards[player];
    }
    
    /**
     * @dev Emergency withdraw function for owner
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount <= gameToken.balanceOf(address(this)), "Insufficient balance");
        require(gameToken.transfer(owner(), amount), "Transfer failed");
        
        emit EmergencyWithdraw(owner(), amount);
    }
    
    /**
     * @dev Pause the vault
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the vault
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
