// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GameToken.sol";

contract GameTokenTest is Test {
    GameToken public gameToken;
    
    address public owner = address(0x1);
    address public minter = address(0x2);
    address public user = address(0x3);
    
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**18;
    uint256 public constant MAX_SUPPLY = 10000000 * 10**18;
    
    function setUp() public {
        vm.startPrank(owner);
        gameToken = new GameToken();
        vm.stopPrank();
    }
    
    function testInitialSupply() public {
        assertEq(gameToken.totalSupply(), INITIAL_SUPPLY);
        assertEq(gameToken.balanceOf(owner), INITIAL_SUPPLY);
    }
    
    function testAddMinter() public {
        vm.startPrank(owner);
        
        gameToken.addMinter(minter);
        assertTrue(gameToken.minters(minter));
        
        vm.stopPrank();
    }
    
    function testRemoveMinter() public {
        vm.startPrank(owner);
        
        gameToken.addMinter(minter);
        assertTrue(gameToken.minters(minter));
        
        gameToken.removeMinter(minter);
        assertFalse(gameToken.minters(minter));
        
        vm.stopPrank();
    }
    
    function testMint() public {
        vm.startPrank(owner);
        
        gameToken.addMinter(minter);
        vm.stopPrank();
        
        uint256 mintAmount = 1000 * 10**18;
        uint256 initialSupply = gameToken.totalSupply();
        
        vm.startPrank(minter);
        gameToken.mint(user, mintAmount);
        vm.stopPrank();
        
        assertEq(gameToken.balanceOf(user), mintAmount);
        assertEq(gameToken.totalSupply(), initialSupply + mintAmount);
    }
    
    function testMintByOwner() public {
        uint256 mintAmount = 1000 * 10**18;
        uint256 initialSupply = gameToken.totalSupply();
        
        vm.startPrank(owner);
        gameToken.mint(user, mintAmount);
        vm.stopPrank();
        
        assertEq(gameToken.balanceOf(user), mintAmount);
        assertEq(gameToken.totalSupply(), initialSupply + mintAmount);
    }
    
    function testMintExceedsMaxSupply() public {
        vm.startPrank(owner);
        
        gameToken.addMinter(minter);
        vm.stopPrank();
        
        uint256 mintAmount = MAX_SUPPLY + 1;
        
        vm.startPrank(minter);
        vm.expectRevert("Exceeds max supply");
        gameToken.mint(user, mintAmount);
        vm.stopPrank();
    }
    
    function testUnauthorizedMint() public {
        uint256 mintAmount = 1000 * 10**18;
        
        vm.startPrank(user);
        vm.expectRevert("Not authorized to mint");
        gameToken.mint(user, mintAmount);
        vm.stopPrank();
    }
    
    function testPauseUnpause() public {
        vm.startPrank(owner);
        
        // Pause token
        gameToken.pause();
        
        // Try to transfer while paused (should fail)
        vm.startPrank(owner);
        vm.expectRevert();
        gameToken.transfer(user, 1000 * 10**18);
        vm.stopPrank();
        
        // Unpause token
        vm.startPrank(owner);
        gameToken.unpause();
        vm.stopPrank();
        
        // Now transfer should work
        vm.startPrank(owner);
        gameToken.transfer(user, 1000 * 10**18);
        vm.stopPrank();
        
        assertEq(gameToken.balanceOf(user), 1000 * 10**18);
    }
    
    function testTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        uint256 initialOwnerBalance = gameToken.balanceOf(owner);
        uint256 initialUserBalance = gameToken.balanceOf(user);
        
        vm.startPrank(owner);
        gameToken.transfer(user, transferAmount);
        vm.stopPrank();
        
        assertEq(gameToken.balanceOf(owner), initialOwnerBalance - transferAmount);
        assertEq(gameToken.balanceOf(user), initialUserBalance + transferAmount);
    }
    
    function testApproveAndTransferFrom() public {
        uint256 transferAmount = 1000 * 10**18;
        uint256 initialOwnerBalance = gameToken.balanceOf(owner);
        uint256 initialUserBalance = gameToken.balanceOf(user);
        
        // Owner approves user to spend tokens
        vm.startPrank(owner);
        gameToken.approve(user, transferAmount);
        vm.stopPrank();
        
        // User transfers from owner to themselves
        vm.startPrank(user);
        gameToken.transferFrom(owner, user, transferAmount);
        vm.stopPrank();
        
        assertEq(gameToken.balanceOf(owner), initialOwnerBalance - transferAmount);
        assertEq(gameToken.balanceOf(user), initialUserBalance + transferAmount);
    }
    
    function testTokenMetadata() public {
        assertEq(gameToken.name(), "Subway Surfers Token");
        assertEq(gameToken.symbol(), "SST");
        assertEq(gameToken.decimals(), 18);
    }
    
    function testOnlyOwnerFunctions() public {
        vm.startPrank(user);
        
        vm.expectRevert();
        gameToken.addMinter(minter);
        
        vm.expectRevert();
        gameToken.removeMinter(minter);
        
        vm.expectRevert();
        gameToken.pause();
        
        vm.expectRevert();
        gameToken.unpause();
        
        vm.stopPrank();
    }
}
