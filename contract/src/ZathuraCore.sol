// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title ZathuraCore
 * @dev Perpetual futures trading contract with 1inch router integration
 * @notice Enables long/short positions with optimized token swaps via 1inch
 */
contract ZathuraCore is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    // ============ STRUCTS ============

    struct Position {
        address trader;
        address collateralToken;
        address indexToken;
        bool isLong;
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 lastFundingTime;
        uint256 entryFundingRate;
        bool isActive;
    }

    struct SwapParams {
        address srcToken;
        address dstToken;
        uint256 amount;
        uint256 minReturnAmount;
        bytes data;
    }

    // ============ STATE VARIABLES ============

    address public immutable oneInchRouter;
    address public immutable weth;

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MAX_LEVERAGE = 100; // 50x max leverage
    uint256 public fundingRate = 100; // 1% funding rate in basis points
    uint256 public liquidationThreshold = 8000; // 80% liquidation threshold

    mapping(bytes32 => Position) public positions;
    mapping(address => uint256) public totalCollateral;
    mapping(address => uint256) public totalSize;

    uint256 public positionCounter;
    uint256 public totalPositions;

    // ============ EVENTS ============

    event PositionOpened(
        bytes32 indexed positionId,
        address indexed trader,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice
    );

    event PositionClosed(bytes32 indexed positionId, address indexed trader, uint256 pnl, uint256 fee);

    event PositionLiquidated(bytes32 indexed positionId, address indexed trader, uint256 liquidationFee);

    event CollateralSwapped(
        address indexed trader, address fromToken, address toToken, uint256 amountIn, uint256 amountOut
    );

    event FundingRateUpdated(uint256 newRate);

    // ============ ERRORS ============

    error PositionNotFound();
    error InsufficientCollateral();
    error InvalidLeverage();
    error PositionNotActive();
    error LiquidationNotAllowed();
    error SwapFailed();
    error InvalidToken();
    error Unauthorized();

    // ============ CONSTRUCTOR ============

    constructor(address _oneInchRouter, address _weth) Ownable(msg.sender) {
        oneInchRouter = _oneInchRouter;
        weth = _weth;
    }

    // ============ MODIFIERS ============

    modifier onlyPositionOwner(bytes32 positionId) {
        if (positions[positionId].trader != msg.sender) revert Unauthorized();
        _;
    }

    modifier positionExists(bytes32 positionId) {
        if (!positions[positionId].isActive) revert PositionNotFound();
        _;
    }

    // ============ CORE FUNCTIONS ============

    /**
     * @dev Open a long position
     * @param collateralToken Token used as collateral
     * @param indexToken Token being traded
     * @param collateralAmount Amount of collateral
     * @param leverage Desired leverage (1-50x)
     * @param swapParams Parameters for 1inch swap if collateral needs conversion
     */
    function openLongPosition(
        address collateralToken,
        address indexToken,
        uint256 collateralAmount,
        uint256 leverage,
        SwapParams calldata swapParams
    ) external nonReentrant whenNotPaused {
        _validateLeverage(leverage);

        // Handle collateral swap if needed
        uint256 finalCollateral = _handleCollateralSwap(collateralToken, indexToken, collateralAmount, swapParams);

        bytes32 positionId = _generatePositionId();
        uint256 positionSize = finalCollateral * leverage;

        positions[positionId] = Position({
            trader: msg.sender,
            collateralToken: indexToken, // Use index token as collateral for long
            indexToken: indexToken,
            isLong: true,
            size: positionSize,
            collateral: finalCollateral,
            averagePrice: _getCurrentPrice(indexToken),
            lastFundingTime: block.timestamp,
            entryFundingRate: fundingRate,
            isActive: true
        });

        _updateTraderStats(msg.sender, finalCollateral, positionSize);
        totalPositions++;

        emit PositionOpened(
            positionId,
            msg.sender,
            indexToken,
            indexToken,
            true,
            positionSize,
            finalCollateral,
            positions[positionId].averagePrice
        );
    }

    /**
     * @dev Open a short position
     * @param collateralToken Token used as collateral
     * @param indexToken Token being traded
     * @param collateralAmount Amount of collateral
     * @param leverage Desired leverage (1-50x)
     * @param swapParams Parameters for 1inch swap if collateral needs conversion
     */
    function openShortPosition(
        address collateralToken,
        address indexToken,
        uint256 collateralAmount,
        uint256 leverage,
        SwapParams calldata swapParams
    ) external nonReentrant whenNotPaused {
        _validateLeverage(leverage);

        // Handle collateral swap if needed
        uint256 finalCollateral = _handleCollateralSwap(
            collateralToken,
            weth, // Use WETH as collateral for short positions
            collateralAmount,
            swapParams
        );

        bytes32 positionId = _generatePositionId();
        uint256 positionSize = finalCollateral * leverage;

        positions[positionId] = Position({
            trader: msg.sender,
            collateralToken: weth,
            indexToken: indexToken,
            isLong: false,
            size: positionSize,
            collateral: finalCollateral,
            averagePrice: _getCurrentPrice(indexToken),
            lastFundingTime: block.timestamp,
            entryFundingRate: fundingRate,
            isActive: true
        });

        _updateTraderStats(msg.sender, finalCollateral, positionSize);
        totalPositions++;

        emit PositionOpened(
            positionId,
            msg.sender,
            weth,
            indexToken,
            false,
            positionSize,
            finalCollateral,
            positions[positionId].averagePrice
        );
    }

    /**
     * @dev Close a position
     * @param positionId ID of the position to close
     * @param swapParams Parameters for 1inch swap to convert PnL
     */
    function closePosition(bytes32 positionId, SwapParams calldata swapParams)
        external
        nonReentrant
        onlyPositionOwner(positionId)
        positionExists(positionId)
    {
        Position storage position = positions[positionId];

        uint256 currentPrice = _getCurrentPrice(position.indexToken);
        int256 pnl = _calculatePnL(position, currentPrice);
        uint256 fundingFee = _calculateFundingFee(position);
        uint256 totalReturn = position.collateral + uint256(pnl) - fundingFee;

        // Handle PnL conversion if needed
        if (totalReturn > 0) {
            _handlePnLConversion(position.collateralToken, totalReturn, swapParams);
        }

        // Update trader stats
        _updateTraderStats(position.trader, position.collateral, position.size);

        // Deactivate position
        position.isActive = false;
        totalPositions--;

        emit PositionClosed(positionId, position.trader, uint256(pnl), fundingFee);
    }

    /**
     * @dev Liquidate a position
     * @param positionId ID of the position to liquidate
     */
    function liquidatePosition(bytes32 positionId) external nonReentrant positionExists(positionId) {
        Position storage position = positions[positionId];

        if (!_isLiquidatable(position)) revert LiquidationNotAllowed();

        uint256 liquidationFee = position.collateral * 50 / BASIS_POINTS; // 0.5% liquidation fee
        uint256 remainingCollateral = position.collateral - liquidationFee;

        // Transfer liquidation fee to liquidator
        IERC20(position.collateralToken).safeTransfer(msg.sender, liquidationFee);

        // Update trader stats
        _updateTraderStats(position.trader, position.collateral, position.size);

        // Deactivate position
        position.isActive = false;
        totalPositions--;

        emit PositionLiquidated(positionId, position.trader, liquidationFee);
    }

    // ============ INTERNAL FUNCTIONS ============

    function _handleCollateralSwap(address fromToken, address toToken, uint256 amount, SwapParams calldata swapParams)
        internal
        returns (uint256)
    {
        if (fromToken == toToken) {
            IERC20(fromToken).safeTransferFrom(msg.sender, address(this), amount);
            return amount;
        }

        // Transfer tokens to contract
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), amount);

        // Approve 1inch router
        IERC20(fromToken).approve(oneInchRouter, amount);

        // Perform swap via 1inch
        (bool success, bytes memory data) = oneInchRouter.call(swapParams.data);
        if (!success) revert SwapFailed();

        uint256 amountOut = abi.decode(data, (uint256));

        emit CollateralSwapped(msg.sender, fromToken, toToken, amount, amountOut);

        return amountOut;
    }

    function _handlePnLConversion(address fromToken, uint256 amount, SwapParams calldata swapParams) internal {
        if (fromToken == swapParams.dstToken) {
            IERC20(fromToken).safeTransfer(msg.sender, amount);
            return;
        }

        // Approve 1inch router
        IERC20(fromToken).approve(oneInchRouter, amount);

        // Perform swap via 1inch
        (bool success, bytes memory data) = oneInchRouter.call(swapParams.data);
        if (!success) revert SwapFailed();

        uint256 amountOut = abi.decode(data, (uint256));

        // Transfer swapped tokens to trader
        IERC20(swapParams.dstToken).safeTransfer(msg.sender, amountOut);
    }

    function _calculatePnL(Position memory position, uint256 currentPrice) internal pure returns (int256) {
        if (position.isLong) {
            return int256(position.size * (currentPrice - position.averagePrice) / position.averagePrice);
        } else {
            return int256(position.size * (position.averagePrice - currentPrice) / position.averagePrice);
        }
    }

    function _calculateFundingFee(Position memory position) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - position.lastFundingTime;
        uint256 fundingRateDiff = fundingRate - position.entryFundingRate;
        return position.size * fundingRateDiff * timeElapsed / (365 days * BASIS_POINTS);
    }

    function _isLiquidatable(Position memory position) internal view returns (bool) {
        uint256 currentPrice = _getCurrentPrice(position.indexToken);
        int256 pnl = _calculatePnL(position, currentPrice);
        uint256 fundingFee = _calculateFundingFee(position);

        uint256 totalValue = position.collateral + uint256(pnl) - fundingFee;
        uint256 liquidationValue = position.size * liquidationThreshold / BASIS_POINTS;

        return totalValue < liquidationValue;
    }

    function _getCurrentPrice(address token) internal view returns (uint256) {
        // In a real implementation, this would fetch from an oracle
        // For now, return a mock price
        return 1000 * 10 ** 18; // Mock price
    }

    function _validateLeverage(uint256 leverage) internal pure {
        if (leverage == 0 || leverage > MAX_LEVERAGE) revert InvalidLeverage();
    }

    function _generatePositionId() internal returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, block.timestamp, positionCounter++));
    }

    function _updateTraderStats(address trader, uint256 collateral, uint256 size) internal {
        totalCollateral[trader] += collateral;
        totalSize[trader] += size;
    }

    // ============ ADMIN FUNCTIONS ============

    function updateFundingRate(uint256 newRate) external onlyOwner {
        fundingRate = newRate;
        emit FundingRateUpdated(newRate);
    }

    function updateLiquidationThreshold(uint256 newThreshold) external onlyOwner {
        liquidationThreshold = newThreshold;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ VIEW FUNCTIONS ============

    function getPosition(bytes32 positionId) external view returns (Position memory) {
        return positions[positionId];
    }

    function getTraderStats(address trader) external view returns (uint256 collateral, uint256 size) {
        return (totalCollateral[trader], totalSize[trader]);
    }

    function isPositionLiquidatable(bytes32 positionId) external view returns (bool) {
        return _isLiquidatable(positions[positionId]);
    }
}
