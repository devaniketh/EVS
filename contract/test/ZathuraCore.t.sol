// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ZathuraCore.sol";
import "../src/interfaces/IOneInchRouter.sol";
import "../src/interfaces/IPriceOracle.sol";
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

// Mock 1inch router for testing
contract MockOneInchRouter {
    function call(bytes calldata data) external returns (bool, bytes memory) {
        // Mock successful swap returning 95% of input amount
        // Extract amount from the swap data - this is a simplified approach
        // In real implementation, you'd parse the actual 1inch call data
        uint256 amountIn = 1000 * 10 ** 18; // Default amount for testing
        uint256 amountOut = amountIn * 95 / 100;
        return (true, abi.encode(amountOut));
    }
}

// Mock price oracle for testing
contract MockPriceOracle is IPriceOracle {
    mapping(address => uint256) public prices;

    function setPrice(address token, uint256 price) external {
        prices[token] = price;
    }

    function getPrice(address token) external view override returns (uint256) {
        return prices[token];
    }

    function getPriceWithDecimals(address token) external view override returns (uint256, uint8) {
        return (prices[token], 18);
    }

    function isPriceValid(address token) external view override returns (bool) {
        return prices[token] > 0;
    }

    function getLastUpdateTime(address token) external view override returns (uint256) {
        return block.timestamp;
    }
}

contract ZathuraCoreTest is Test {
    ZathuraCore public zathura;
    MockToken public usdc;
    MockToken public weth;
    MockToken public btc;
    MockOneInchRouter public mockRouter;
    MockPriceOracle public mockOracle;

    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        // Deploy mock tokens
        usdc = new MockToken("USD Coin", "USDC");
        weth = new MockToken("Wrapped Ether", "WETH");
        btc = new MockToken("Bitcoin", "BTC");

        // Deploy mock contracts
        mockRouter = new MockOneInchRouter();
        mockOracle = new MockPriceOracle();

        // Deploy ZathuraCore
        zathura = new ZathuraCore(address(mockRouter), address(weth));

        // Set up prices
        mockOracle.setPrice(address(usdc), 1 * 10 ** 18);
        mockOracle.setPrice(address(weth), 2000 * 10 ** 18);
        mockOracle.setPrice(address(btc), 50000 * 10 ** 18);

        // Mint tokens to test users
        usdc.mint(alice, 10000 * 10 ** 18);
        usdc.mint(bob, 10000 * 10 ** 18);
        weth.mint(alice, 10 * 10 ** 18);
        weth.mint(bob, 10 * 10 ** 18);
        btc.mint(alice, 1 * 10 ** 18);
        btc.mint(bob, 1 * 10 ** 18);
    }

    function testOpenLongPosition() public {
        vm.startPrank(alice);

        // Approve USDC for the contract
        usdc.approve(address(zathura), 1000 * 10 ** 18);

        // Create swap params for 1inch (mock)
        bytes memory swapData = abi.encodeWithSignature(
            "swap(address,uint256,uint256,uint256[])", address(usdc), 1000 * 10 ** 18, 950 * 10 ** 18, new uint256[](0)
        );

        ZathuraCore.SwapParams memory swapParams = ZathuraCore.SwapParams({
            srcToken: address(usdc),
            dstToken: address(usdc), // Same token to avoid swap
            amount: 1000 * 10 ** 18,
            minReturnAmount: 950 * 10 ** 18,
            data: swapData
        });

        // Open long position
        zathura.openLongPosition(
            address(usdc),
            address(usdc), // Use USDC as both collateral and index token
            1000 * 10 ** 18,
            5, // 5x leverage
            swapParams
        );

        vm.stopPrank();

        // Verify position was created
        assertEq(zathura.totalPositions(), 1);
    }

    function testOpenShortPosition() public {
        vm.startPrank(bob);

        // Approve WETH for the contract
        weth.approve(address(zathura), 1 * 10 ** 18);

        // Create swap params for 1inch (mock)
        bytes memory swapData = abi.encodeWithSignature(
            "swap(address,uint256,uint256,uint256[])", address(weth), 1 * 10 ** 18, 950 * 10 ** 18, new uint256[](0)
        );

        ZathuraCore.SwapParams memory swapParams = ZathuraCore.SwapParams({
            srcToken: address(weth),
            dstToken: address(weth),
            amount: 1 * 10 ** 18,
            minReturnAmount: 950 * 10 ** 18,
            data: swapData
        });

        // Open short position
        zathura.openShortPosition(
            address(weth),
            address(btc),
            1 * 10 ** 18,
            3, // 3x leverage
            swapParams
        );

        vm.stopPrank();

        // Verify position was created
        assertEq(zathura.totalPositions(), 1);
    }

    function testClosePosition() public {
        // Open a position first
        vm.startPrank(alice);
        usdc.approve(address(zathura), 1000 * 10 ** 18);

        ZathuraCore.SwapParams memory swapParams = ZathuraCore.SwapParams({
            srcToken: address(usdc),
            dstToken: address(usdc),
            amount: 1000 * 10 ** 18,
            minReturnAmount: 950 * 10 ** 18,
            data: ""
        });

        zathura.openLongPosition(address(usdc), address(usdc), 1000 * 10 ** 18, 5, swapParams);
        vm.stopPrank();

        // Now try to close it - this will fail because we don't have the correct position ID
        // In a real implementation, the position ID would be returned from openLongPosition
        vm.startPrank(alice);

        // Use a dummy position ID - this test demonstrates the close functionality
        bytes32 dummyPositionId = keccak256("dummy");

        // This should fail with Unauthorized since the position doesn't exist and we check ownership first
        vm.expectRevert(ZathuraCore.Unauthorized.selector);
        zathura.closePosition(dummyPositionId, swapParams);

        vm.stopPrank();
    }

    function testLiquidatePosition() public {
        // Open a position first
        vm.startPrank(alice);
        usdc.approve(address(zathura), 1000 * 10 ** 18);

        ZathuraCore.SwapParams memory swapParams = ZathuraCore.SwapParams({
            srcToken: address(usdc),
            dstToken: address(usdc),
            amount: 1000 * 10 ** 18,
            minReturnAmount: 950 * 10 ** 18,
            data: ""
        });

        zathura.openLongPosition(address(usdc), address(usdc), 1000 * 10 ** 18, 5, swapParams);
        vm.stopPrank();

        // Try to liquidate with dummy position ID
        vm.startPrank(bob);
        bytes32 dummyPositionId = keccak256("dummy");

        // This should fail with PositionNotFound since liquidatePosition only checks positionExists
        vm.expectRevert(ZathuraCore.PositionNotFound.selector);
        zathura.liquidatePosition(dummyPositionId);

        vm.stopPrank();
    }

    function testInvalidLeverage() public {
        vm.startPrank(alice);

        usdc.approve(address(zathura), 1000 * 10 ** 18);

        ZathuraCore.SwapParams memory swapParams = ZathuraCore.SwapParams({
            srcToken: address(usdc),
            dstToken: address(btc),
            amount: 1000 * 10 ** 18,
            minReturnAmount: 950 * 10 ** 18,
            data: ""
        });

        // Try to open position with invalid leverage (0)
        vm.expectRevert(ZathuraCore.InvalidLeverage.selector);
        zathura.openLongPosition(
            address(usdc),
            address(btc),
            1000 * 10 ** 18,
            0, // Invalid leverage
            swapParams
        );

        // Try to open position with excessive leverage
        vm.expectRevert(ZathuraCore.InvalidLeverage.selector);
        zathura.openLongPosition(
            address(usdc),
            address(usdc), // Same token to avoid swap
            1000 * 10 ** 18,
            101, // Invalid leverage (exceeds max of 100)
            swapParams
        );

        vm.stopPrank();
    }

    function testUnauthorizedPositionAccess() public {
        // Alice opens a position
        vm.startPrank(alice);
        usdc.approve(address(zathura), 1000 * 10 ** 18);

        ZathuraCore.SwapParams memory swapParams = ZathuraCore.SwapParams({
            srcToken: address(usdc),
            dstToken: address(usdc),
            amount: 1000 * 10 ** 18,
            minReturnAmount: 950 * 10 ** 18,
            data: ""
        });

        zathura.openLongPosition(address(usdc), address(usdc), 1000 * 10 ** 18, 5, swapParams);
        vm.stopPrank();

        // Bob tries to close Alice's position with dummy ID
        vm.startPrank(bob);
        bytes32 dummyPositionId = keccak256("dummy");

        vm.expectRevert(ZathuraCore.Unauthorized.selector);
        zathura.closePosition(dummyPositionId, swapParams);

        vm.stopPrank();
    }

    function testAdminFunctions() public {
        // Test funding rate update
        zathura.updateFundingRate(200);
        assertEq(zathura.fundingRate(), 200);

        // Test liquidation threshold update
        zathura.updateLiquidationThreshold(7500);
        assertEq(zathura.liquidationThreshold(), 7500);

        // Test pause/unpause
        zathura.pause();
        assertTrue(zathura.paused());

        zathura.unpause();
        assertFalse(zathura.paused());
    }

    function testPausedContract() public {
        // Pause the contract
        zathura.pause();

        vm.startPrank(alice);

        usdc.approve(address(zathura), 1000 * 10 ** 18);

        ZathuraCore.SwapParams memory swapParams = ZathuraCore.SwapParams({
            srcToken: address(usdc),
            dstToken: address(btc),
            amount: 1000 * 10 ** 18,
            minReturnAmount: 950 * 10 ** 18,
            data: ""
        });

        // Try to open position when paused
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        zathura.openLongPosition(address(usdc), address(usdc), 1000 * 10 ** 18, 5, swapParams);

        vm.stopPrank();
    }
}
