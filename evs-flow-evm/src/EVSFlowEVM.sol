// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract EVSCore {
    struct Game {
        address player;
        uint256 amountWaged;
        uint256 reqDistance;
        bool completed;
    }

    mapping(uint256 => Game) public games;
    uint256 public gameId;

    function startGame(uint256 amountWaged, uint256 reqDistance) public {
        games[gameId] = Game(msg.sender, amountWaged, reqDistance, false);
        gameId++;
    }
    
    function completeGame(uint256 gameId) public {
        games[gameId].completed = true;
    }

    function getGame(uint256 gameId) public view returns (Game memory) {
        return games[gameId];
    }
}
