// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ZathuraLiquidityManager.sol";
import "../src/ZathuraCore.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Mock ERC20 token for testing
contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Mock Hyperliquid vault for testing
contract MockHyperliquidVault {
    mapping(address => uint256) public balances;

    function deposit(address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balances[token] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        require(balances[token] >= amount, "Insufficient balance");
        balances[token] -= amount;
        IERC20(token).transfer(msg.sender, amount);
    }
}

contract ZathuraLiquidityManagerTest is Test {
    ZathuraLiquidityManager public liquidityManager;
    ZathuraCore public zathuraCore;
    MockToken public usdc;
    MockToken public weth;
    MockHyperliquidVault public hyperliquidVault;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public owner = address(0x3);

    function setUp() public {
        // Deploy mock tokens
        usdc = new MockToken("USD Coin", "USDC");
        weth = new MockToken("Wrapped Ether", "WETH");

        // Deploy mock contracts
        hyperliquidVault = new MockHyperliquidVault();

        // Deploy ZathuraCore
        zathuraCore = new ZathuraCore(address(0x1111), address(weth));

        // Deploy ZathuraLiquidityManager
        liquidityManager = new ZathuraLiquidityManager(address(zathuraCore), address(weth));

        // Transfer ownership
        liquidityManager.transferOwnership(owner);

        // Mint tokens to test users
        usdc.mint(alice, 10000 * 10 ** 18);
        usdc.mint(bob, 10000 * 10 ** 18);
        weth.mint(alice, 10 * 10 ** 18);
        weth.mint(bob, 10 * 10 ** 18);
    }

    function testAddLiquidity() public {
        vm.startPrank(alice);

        // Approve tokens
        usdc.approve(address(liquidityManager), 1000 * 10 ** 18);

        // Add liquidity
        liquidityManager.addLiquidity(address(usdc), 1000 * 10 ** 18);

        vm.stopPrank();

        // Verify liquidity position
        ZathuraLiquidityManager.LiquidityPosition memory position = liquidityManager.getLiquidityPosition(address(usdc));
        assertEq(position.provider, alice);
        assertEq(position.token, address(usdc));
        assertEq(position.amount, 1000 * 10 ** 18);
        assertEq(position.shares, 1000 * 10 ** 18);
        assertTrue(position.isActive);

        // Verify total liquidity
        assertEq(liquidityManager.getTotalLiquidity(address(usdc)), 1000 * 10 ** 18);
    }

    function testRemoveLiquidity() public {
        // First add liquidity
        testAddLiquidity();

        vm.startPrank(alice);

        // Remove half of the liquidity
        liquidityManager.removeLiquidity(address(usdc), 500 * 10 ** 18);

        vm.stopPrank();

        // Verify updated position
        ZathuraLiquidityManager.LiquidityPosition memory position = liquidityManager.getLiquidityPosition(address(usdc));
        assertEq(position.amount, 500 * 10 ** 18);
        assertEq(position.shares, 500 * 10 ** 18);

        // Verify total liquidity
        assertEq(liquidityManager.getTotalLiquidity(address(usdc)), 500 * 10 ** 18);
    }

    function testConfigureHyperliquid() public {
        vm.startPrank(owner);

        // Configure Hyperliquid
        liquidityManager.configureHyperliquid(
            address(hyperliquidVault),
            5000, // 50% max allocation
            1000 // 10% rebalance threshold
        );

        vm.stopPrank();

        // Verify configuration
        ZathuraLiquidityManager.HyperliquidConfig memory config = liquidityManager.getHyperliquidConfig();
        assertEq(config.hyperliquidVault, address(hyperliquidVault));
        assertEq(config.maxAllocation, 5000);
        assertEq(config.rebalanceThreshold, 1000);
        assertTrue(config.isActive);
    }

    function testDistributeFees() public {
        // Add liquidity first
        testAddLiquidity();

        vm.startPrank(owner);

        // Distribute fees
        liquidityManager.distributeFees(
            address(usdc),
            100 * 10 ** 18, // 100 USDC trading fees
            50 * 10 ** 18 // 50 USDC Hyperliquid rewards
        );

        vm.stopPrank();

        // Verify fee distribution
        ZathuraLiquidityManager.FeeDistribution memory fees = liquidityManager.getFeeDistribution(address(usdc));
        assertEq(fees.tradingFees, 100 * 10 ** 18);
        assertEq(fees.hyperliquidRewards, 50 * 10 ** 18);
        assertEq(fees.totalDistributed, 150 * 10 ** 18);
    }

    function testNeutralizeLoss() public {
        // Add liquidity first
        testAddLiquidity();

        vm.startPrank(owner);

        // Neutralize loss
        liquidityManager.neutralizeLoss(address(usdc), 50 * 10 ** 18);

        vm.stopPrank();

        // Verify total liquidity decreased
        assertEq(liquidityManager.getTotalLiquidity(address(usdc)), 950 * 10 ** 18);
    }

    function testEmergencyMode() public {
        // Add liquidity first
        testAddLiquidity();

        vm.startPrank(owner);

        // Trigger emergency mode with large loss
        liquidityManager.neutralizeLoss(address(usdc), 1000 * 10 ** 18); // 100% loss

        vm.stopPrank();

        // Verify emergency mode is active
        assertTrue(liquidityManager.isEmergencyMode());
    }

    function testInvalidLiquidityOperations() public {
        vm.startPrank(alice);

        usdc.approve(address(liquidityManager), 1000 * 10 ** 18);

        // Try to add zero liquidity
        vm.expectRevert(ZathuraLiquidityManager.InvalidAmount.selector);
        liquidityManager.addLiquidity(address(usdc), 0);

        // Try to remove liquidity without having any
        vm.expectRevert(ZathuraLiquidityManager.LiquidityPositionNotFound.selector);
        liquidityManager.removeLiquidity(address(usdc), 100 * 10 ** 18);

        vm.stopPrank();
    }

    function testUnauthorizedOperations() public {
        vm.startPrank(alice);

        usdc.approve(address(liquidityManager), 1000 * 10 ** 18);
        liquidityManager.addLiquidity(address(usdc), 1000 * 10 ** 18);

        vm.stopPrank();

        // Bob tries to remove Alice's liquidity
        vm.startPrank(bob);

        vm.expectRevert(ZathuraLiquidityManager.LiquidityPositionNotFound.selector);
        liquidityManager.removeLiquidity(address(usdc), 100 * 10 ** 18);

        vm.stopPrank();
    }

    function testPausedContract() public {
        // Pause the contract
        vm.startPrank(owner);
        liquidityManager.pause();
        vm.stopPrank();

        vm.startPrank(alice);

        usdc.approve(address(liquidityManager), 1000 * 10 ** 18);

        // Try to add liquidity when paused
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        liquidityManager.addLiquidity(address(usdc), 1000 * 10 ** 18);

        vm.stopPrank();
    }

    function testMultipleLiquidityProviders() public {
        // Alice adds liquidity
        vm.startPrank(alice);
        usdc.approve(address(liquidityManager), 1000 * 10 ** 18);
        liquidityManager.addLiquidity(address(usdc), 1000 * 10 ** 18);
        vm.stopPrank();

        // Bob adds liquidity for a different token (WETH)
        vm.startPrank(bob);
        weth.approve(address(liquidityManager), 5 * 10 ** 18);
        liquidityManager.addLiquidity(address(weth), 5 * 10 ** 18);
        vm.stopPrank();

        // Verify Alice's USDC position
        ZathuraLiquidityManager.LiquidityPosition memory alicePosition =
            liquidityManager.getLiquidityPosition(address(usdc));
        assertEq(alicePosition.provider, alice);
        assertEq(alicePosition.amount, 1000 * 10 ** 18);

        // Verify Bob's WETH position
        ZathuraLiquidityManager.LiquidityPosition memory bobPosition =
            liquidityManager.getLiquidityPosition(address(weth));
        assertEq(bobPosition.provider, bob);
        assertEq(bobPosition.amount, 5 * 10 ** 18);

        // Verify total liquidity for both tokens
        assertEq(liquidityManager.getTotalLiquidity(address(usdc)), 1000 * 10 ** 18);
        assertEq(liquidityManager.getTotalLiquidity(address(weth)), 5 * 10 ** 18);
    }

    function testAdminFunctions() public {
        vm.startPrank(owner);

        // Update volatility threshold
        liquidityManager.updateVolatilityThreshold(1000);
        assertEq(liquidityManager.volatilityThreshold(), 1000);

        // Update max loss percentage
        liquidityManager.updateMaxLossPercentage(500);
        assertEq(liquidityManager.maxLossPercentage(), 500);

        // Toggle emergency mode
        liquidityManager.toggleEmergencyMode();
        assertTrue(liquidityManager.isEmergencyMode());

        liquidityManager.toggleEmergencyMode();
        assertFalse(liquidityManager.isEmergencyMode());

        vm.stopPrank();
    }
}
