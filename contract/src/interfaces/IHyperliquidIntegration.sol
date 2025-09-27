// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IHyperliquidIntegration
 * @dev Interface for TypeScript Hyperliquid integration
 * @notice This interface defines the contract methods that will be called by the TypeScript layer
 */
interface IHyperliquidIntegration {
    // Events for TypeScript integration
    event HyperliquidAllocationRequested(address indexed token, uint256 amount, uint256 timestamp);

    event HyperliquidDeallocationRequested(address indexed token, uint256 amount, uint256 timestamp);

    event HyperliquidRewardsReceived(address indexed token, uint256 amount, uint256 timestamp);

    event HyperliquidLossDetected(address indexed token, uint256 lossAmount, uint256 timestamp);

    // Functions to be called by TypeScript layer
    function requestHyperliquidAllocation(address token, uint256 amount) external;
    function requestHyperliquidDeallocation(address token, uint256 amount) external;
    function reportHyperliquidRewards(address token, uint256 amount) external;
    function reportHyperliquidLoss(address token, uint256 lossAmount) external;
}
