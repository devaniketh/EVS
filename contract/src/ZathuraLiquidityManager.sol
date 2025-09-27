// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./ZathuraCore.sol";
import "./interfaces/IHyperliquidIntegration.sol";

/**
 * @title ZathuraLiquidityManager
 * @dev Manages liquidity provision for Zathura platform with Hyperliquid integration
 * @notice Handles LP rewards, fee distribution, and loss neutralization
 */
contract ZathuraLiquidityManager is ReentrancyGuard, Ownable, Pausable, IHyperliquidIntegration {
    using SafeERC20 for IERC20;

    // ============ STRUCTS ============

    struct LiquidityPosition {
        address provider;
        address token;
        uint256 amount;
        uint256 shares;
        uint256 lastUpdateTime;
        uint256 totalFeesEarned;
        bool isActive;
    }

    struct HyperliquidConfig {
        address hyperliquidVault;
        uint256 maxAllocation; // Max percentage of liquidity to allocate to Hyperliquid
        uint256 rebalanceThreshold; // Threshold for rebalancing
        bool isActive;
    }

    struct FeeDistribution {
        uint256 tradingFees; // Fees from Zathura trading
        uint256 hyperliquidRewards; // Rewards from Hyperliquid
        uint256 totalDistributed;
        uint256 lastDistributionTime;
    }

    // ============ STATE VARIABLES ============

    ZathuraCore public immutable zathuraCore;
    address public immutable weth;

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MAX_FEE_RATE = 1000; // 10% max fee rate

    // Liquidity management
    mapping(address => LiquidityPosition) public liquidityPositions;
    mapping(address => uint256) public totalLiquidityByToken;
    mapping(address => uint256) public totalSharesByToken;

    // Fee and reward management
    mapping(address => FeeDistribution) public feeDistributions;
    uint256 public totalFeesCollected;
    uint256 public totalRewardsDistributed;

    // Hyperliquid integration
    HyperliquidConfig public hyperliquidConfig;
    mapping(address => uint256) public hyperliquidAllocations;

    // Risk management
    uint256 public volatilityThreshold = 500; // 5% volatility threshold
    uint256 public maxLossPercentage = 200; // 2% max loss before neutralization
    bool public emergencyMode = false;

    // Events
    event LiquidityAdded(address indexed provider, address indexed token, uint256 amount, uint256 shares);

    event LiquidityRemoved(address indexed provider, address indexed token, uint256 amount, uint256 shares);

    event FeesDistributed(address indexed token, uint256 totalFees, uint256 totalRewards);

    event HyperliquidAllocationUpdated(address indexed token, uint256 oldAllocation, uint256 newAllocation);

    event LossNeutralized(address indexed token, uint256 lossAmount, uint256 neutralizedAmount);

    event EmergencyModeToggled(bool enabled);

    // Errors
    error InsufficientLiquidity();
    error InvalidToken();
    error InvalidAmount();
    error LiquidityPositionNotFound();
    error HyperliquidNotConfigured();
    error EmergencyModeActive();
    error ExceedsMaxAllocation();
    error InsufficientShares();

    // ============ CONSTRUCTOR ============

    constructor(address _zathuraCore, address _weth) Ownable(msg.sender) {
        zathuraCore = ZathuraCore(_zathuraCore);
        weth = _weth;
    }

    // ============ MODIFIERS ============

    modifier onlyLiquidityProvider(address token) {
        if (liquidityPositions[token].provider != msg.sender) revert LiquidityPositionNotFound();
        _;
    }

    modifier notInEmergency() {
        if (emergencyMode) revert EmergencyModeActive();
        _;
    }

    // ============ CORE FUNCTIONS ============

    /**
     * @dev Add liquidity to the platform
     * @param token Token to provide liquidity for
     * @param amount Amount of tokens to provide
     */
    function addLiquidity(address token, uint256 amount) external nonReentrant whenNotPaused notInEmergency {
        if (amount == 0) revert InvalidAmount();

        // Transfer tokens from user
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Calculate shares based on current total liquidity
        uint256 shares = _calculateShares(token, amount);

        // Update or create liquidity position
        if (liquidityPositions[token].isActive) {
            liquidityPositions[token].amount += amount;
            liquidityPositions[token].shares += shares;
        } else {
            liquidityPositions[token] = LiquidityPosition({
                provider: msg.sender,
                token: token,
                amount: amount,
                shares: shares,
                lastUpdateTime: block.timestamp,
                totalFeesEarned: 0,
                isActive: true
            });
        }

        // Update global state
        totalLiquidityByToken[token] += amount;
        totalSharesByToken[token] += shares;

        // Allocate to Hyperliquid if configured
        if (hyperliquidConfig.isActive) {
            _allocateToHyperliquid(token, amount);
        }

        emit LiquidityAdded(msg.sender, token, amount, shares);
    }

    /**
     * @dev Remove liquidity from the platform
     * @param token Token to remove liquidity for
     * @param shares Number of shares to remove
     */
    function removeLiquidity(address token, uint256 shares) external nonReentrant onlyLiquidityProvider(token) {
        if (shares > liquidityPositions[token].shares) revert InsufficientShares();

        // Calculate amount to return
        uint256 amount = _calculateAmountFromShares(token, shares);

        // Update position
        liquidityPositions[token].amount -= amount;
        liquidityPositions[token].shares -= shares;

        // If all shares removed, deactivate position
        if (liquidityPositions[token].shares == 0) {
            liquidityPositions[token].isActive = false;
        }

        // Update global state
        totalLiquidityByToken[token] -= amount;
        totalSharesByToken[token] -= shares;

        // Deallocate from Hyperliquid
        if (hyperliquidConfig.isActive) {
            _deallocateFromHyperliquid(token, amount);
        }

        // Transfer tokens back to user
        IERC20(token).safeTransfer(msg.sender, amount);

        emit LiquidityRemoved(msg.sender, token, amount, shares);
    }

    /**
     * @dev Distribute fees to liquidity providers
     * @param token Token to distribute fees for
     * @param tradingFees Trading fees from Zathura
     * @param hyperliquidRewards Rewards from Hyperliquid
     */
    function distributeFees(address token, uint256 tradingFees, uint256 hyperliquidRewards) external onlyOwner {
        if (totalSharesByToken[token] == 0) revert InsufficientLiquidity();

        uint256 totalFees = tradingFees + hyperliquidRewards;

        // Update fee distribution tracking
        feeDistributions[token].tradingFees += tradingFees;
        feeDistributions[token].hyperliquidRewards += hyperliquidRewards;
        feeDistributions[token].totalDistributed += totalFees;
        feeDistributions[token].lastDistributionTime = block.timestamp;

        // Update global tracking
        totalFeesCollected += tradingFees;
        totalRewardsDistributed += hyperliquidRewards;

        emit FeesDistributed(token, tradingFees, hyperliquidRewards);
    }

    /**
     * @dev Neutralize losses during high volatility
     * @param token Token to neutralize losses for
     * @param lossAmount Amount of loss to neutralize
     */
    function neutralizeLoss(address token, uint256 lossAmount) external onlyOwner {
        if (lossAmount > totalLiquidityByToken[token] * maxLossPercentage / BASIS_POINTS) {
            // Activate emergency mode if loss exceeds threshold
            emergencyMode = true;
            emit EmergencyModeToggled(true);
        }

        // Use available liquidity to neutralize loss
        uint256 neutralizedAmount = _neutralizeLoss(token, lossAmount);

        emit LossNeutralized(token, lossAmount, neutralizedAmount);
    }

    // ============ HYPERLIQUID INTEGRATION ============

    /**
     * @dev Configure Hyperliquid integration
     * @param vault Hyperliquid vault address
     * @param maxAllocation Maximum allocation percentage
     * @param rebalanceThreshold Rebalancing threshold
     */
    function configureHyperliquid(address vault, uint256 maxAllocation, uint256 rebalanceThreshold)
        external
        onlyOwner
    {
        if (maxAllocation > BASIS_POINTS) revert ExceedsMaxAllocation();

        hyperliquidConfig = HyperliquidConfig({
            hyperliquidVault: vault,
            maxAllocation: maxAllocation,
            rebalanceThreshold: rebalanceThreshold,
            isActive: true
        });
    }

    /**
     * @dev Allocate liquidity to Hyperliquid
     * @param token Token to allocate
     * @param amount Amount to allocate
     */
    function _allocateToHyperliquid(address token, uint256 amount) internal {
        if (!hyperliquidConfig.isActive) return;

        uint256 currentAllocation = hyperliquidAllocations[token];
        uint256 maxAllocationAmount = totalLiquidityByToken[token] * hyperliquidConfig.maxAllocation / BASIS_POINTS;

        if (currentAllocation + amount > maxAllocationAmount) {
            amount = maxAllocationAmount - currentAllocation;
        }

        if (amount > 0) {
            // Transfer tokens to Hyperliquid vault
            IERC20(token).safeTransfer(hyperliquidConfig.hyperliquidVault, amount);
            hyperliquidAllocations[token] += amount;

            emit HyperliquidAllocationUpdated(token, currentAllocation, hyperliquidAllocations[token]);
        }
    }

    /**
     * @dev Deallocate liquidity from Hyperliquid
     * @param token Token to deallocate
     * @param amount Amount to deallocate
     */
    function _deallocateFromHyperliquid(address token, uint256 amount) internal {
        if (!hyperliquidConfig.isActive) return;

        uint256 currentAllocation = hyperliquidAllocations[token];
        if (amount > currentAllocation) {
            amount = currentAllocation;
        }

        if (amount > 0) {
            // Request withdrawal from Hyperliquid vault
            // In real implementation, this would call Hyperliquid's withdrawal function
            hyperliquidAllocations[token] -= amount;

            emit HyperliquidAllocationUpdated(token, currentAllocation, hyperliquidAllocations[token]);
        }
    }

    // ============ INTERNAL FUNCTIONS ============

    function _calculateShares(address token, uint256 amount) internal view returns (uint256) {
        if (totalSharesByToken[token] == 0) {
            return amount; // First liquidity provider gets 1:1 shares
        }

        return (amount * totalSharesByToken[token]) / totalLiquidityByToken[token];
    }

    function _calculateAmountFromShares(address token, uint256 shares) internal view returns (uint256) {
        if (totalSharesByToken[token] == 0) return 0;

        return (shares * totalLiquidityByToken[token]) / totalSharesByToken[token];
    }

    function _neutralizeLoss(address token, uint256 lossAmount) internal returns (uint256) {
        uint256 availableLiquidity = totalLiquidityByToken[token] - hyperliquidAllocations[token];

        if (availableLiquidity >= lossAmount) {
            // Use available liquidity to neutralize loss
            totalLiquidityByToken[token] -= lossAmount;
            return lossAmount;
        } else {
            // Use all available liquidity
            uint256 neutralizedAmount = availableLiquidity;
            totalLiquidityByToken[token] -= neutralizedAmount;
            return neutralizedAmount;
        }
    }

    // ============ ADMIN FUNCTIONS ============

    function updateVolatilityThreshold(uint256 newThreshold) external onlyOwner {
        volatilityThreshold = newThreshold;
    }

    function updateMaxLossPercentage(uint256 newPercentage) external onlyOwner {
        maxLossPercentage = newPercentage;
    }

    function toggleEmergencyMode() external onlyOwner {
        emergencyMode = !emergencyMode;
        emit EmergencyModeToggled(emergencyMode);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ VIEW FUNCTIONS ============

    function getLiquidityPosition(address token) external view returns (LiquidityPosition memory) {
        return liquidityPositions[token];
    }

    function getTotalLiquidity(address token) external view returns (uint256) {
        return totalLiquidityByToken[token];
    }

    function getHyperliquidAllocation(address token) external view returns (uint256) {
        return hyperliquidAllocations[token];
    }

    function getFeeDistribution(address token) external view returns (FeeDistribution memory) {
        return feeDistributions[token];
    }

    function isEmergencyMode() external view returns (bool) {
        return emergencyMode;
    }

    function getHyperliquidConfig() external view returns (HyperliquidConfig memory) {
        return hyperliquidConfig;
    }

    // ============ TYPESCRIPT INTEGRATION FUNCTIONS ============

    /**
     * @dev Request Hyperliquid allocation (called by TypeScript layer)
     * @param token Token to allocate
     * @param amount Amount to allocate
     */
    function requestHyperliquidAllocation(address token, uint256 amount) external onlyOwner {
        if (!hyperliquidConfig.isActive) revert HyperliquidNotConfigured();

        uint256 currentAllocation = hyperliquidAllocations[token];
        uint256 maxAllocationAmount = totalLiquidityByToken[token] * hyperliquidConfig.maxAllocation / BASIS_POINTS;

        if (currentAllocation + amount > maxAllocationAmount) {
            amount = maxAllocationAmount - currentAllocation;
        }

        if (amount > 0) {
            hyperliquidAllocations[token] += amount;
            emit HyperliquidAllocationRequested(token, amount, block.timestamp);
        }
    }

    /**
     * @dev Request Hyperliquid deallocation (called by TypeScript layer)
     * @param token Token to deallocate
     * @param amount Amount to deallocate
     */
    function requestHyperliquidDeallocation(address token, uint256 amount) external onlyOwner {
        if (!hyperliquidConfig.isActive) revert HyperliquidNotConfigured();

        uint256 currentAllocation = hyperliquidAllocations[token];
        if (amount > currentAllocation) {
            amount = currentAllocation;
        }

        if (amount > 0) {
            hyperliquidAllocations[token] -= amount;
            emit HyperliquidDeallocationRequested(token, amount, block.timestamp);
        }
    }

    /**
     * @dev Report Hyperliquid rewards (called by TypeScript layer)
     * @param token Token for which rewards were received
     * @param amount Amount of rewards received
     */
    function reportHyperliquidRewards(address token, uint256 amount) external onlyOwner {
        if (amount > 0) {
            // Update fee distribution for the token
            feeDistributions[token].hyperliquidRewards += amount;
            feeDistributions[token].totalDistributed += amount;
            feeDistributions[token].lastDistributionTime = block.timestamp;

            // Update global tracking
            totalRewardsDistributed += amount;

            emit HyperliquidRewardsReceived(token, amount, block.timestamp);
        }
    }

    /**
     * @dev Report Hyperliquid loss (called by TypeScript layer)
     * @param token Token for which loss occurred
     * @param lossAmount Amount of loss
     */
    function reportHyperliquidLoss(address token, uint256 lossAmount) external onlyOwner {
        if (lossAmount > 0) {
            // Check if loss exceeds threshold
            if (lossAmount > totalLiquidityByToken[token] * maxLossPercentage / BASIS_POINTS) {
                // Activate emergency mode
                emergencyMode = true;
                emit EmergencyModeToggled(true);
            }

            // Neutralize the loss
            uint256 neutralizedAmount = _neutralizeLoss(token, lossAmount);

            emit HyperliquidLossDetected(token, lossAmount, block.timestamp);
            emit LossNeutralized(token, lossAmount, neutralizedAmount);
        }
    }
}
