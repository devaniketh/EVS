// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IHyperliquidVault
 * @dev Interface for Hyperliquid vault integration
 */
interface IHyperliquidVault {
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint256 amount) external;
    function getBalance(address token) external view returns (uint256);
    function getTotalValue() external view returns (uint256);
    function getRewards(address token) external view returns (uint256);
    function claimRewards(address token) external;
}
