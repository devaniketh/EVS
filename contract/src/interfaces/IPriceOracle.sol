// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPriceOracle
 * @dev Interface for price oracle integration
 */
interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);
    function getPriceWithDecimals(address token) external view returns (uint256, uint8);
    function isPriceValid(address token) external view returns (bool);
    function getLastUpdateTime(address token) external view returns (uint256);
}
