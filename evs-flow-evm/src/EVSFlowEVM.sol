// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract EVSCore {
    struct Game {
        address player;
        uint256 amountWaged;
        uint256 reqDistance;
        bool completed;
    }
}
