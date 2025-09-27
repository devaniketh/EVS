// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IOneInchRouter
 * @dev Interface for 1inch router integration
 */
interface IOneInchRouter {
    function swap(address executor, SwapDescription calldata desc, bytes calldata permit, bytes calldata data)
        external
        payable
        returns (uint256 returnAmount, uint256 spentAmount);

    function unoswap(address srcToken, uint256 amount, uint256 minReturn, uint256[] calldata pools)
        external
        payable
        returns (uint256 returnAmount);

    function uniswapV3Swap(uint256 amount, uint256 minReturn, uint256[] calldata pools)
        external
        payable
        returns (uint256 returnAmount);
}

struct SwapDescription {
    address srcToken;
    address dstToken;
    address srcReceiver;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
}
