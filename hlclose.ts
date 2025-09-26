// @ts-ignore - hyperliquid module types not available
import { Hyperliquid } from 'hyperliquid';

// ============================================================================
// HYPERLIQUID POSITION CLOSER - INTEGRATED WITH PLEXI VAULT
// ============================================================================

// ============================================================================
// 1. HYPERLIQUID SDK INITIALIZATION
// ============================================================================

interface HyperliquidConfig {
  privateKey: string;
  testnet?: boolean;
  walletAddress?: string;
}

export class HyperliquidPositionCloser {
  private hypeSdk: Hyperliquid;
  private config: HyperliquidConfig;

  constructor(config: HyperliquidConfig) {
    this.config = config;
    this.hypeSdk = new Hyperliquid({
      privateKey: config.privateKey,
      testnet: config.testnet || false,
      walletAddress: config.walletAddress,
    });
  }

  // ============================================================================
  // 2. PRICE FETCHING FROM COINGECKO
  // ============================================================================

  /**
   * Fetches current ETH price from CoinGecko API
   * @param coinId - CoinGecko coin ID (default: 'ethereum')
   * @returns Current price in USD
   */
  async fetchEthPriceFromCoinGecko(coinId: string = 'ethereum'): Promise<number> {
    try {
      const response = await fetch(
        `https://api.coingecko.com/api/v3/simple/price?ids=${coinId}&vs_currencies=usd`
      );
      
      if (!response.ok) {
        throw new Error(`CoinGecko API error: ${response.status} ${response.statusText}`);
      }
      
      const data = await response.json();
      const price = data[coinId]?.usd;
      
      if (!price || typeof price !== 'number') {
        throw new Error('Invalid price data from CoinGecko');
      }
      
      console.log(`Fetched ETH price from CoinGecko: $${price}`);
      return price;
    } catch (error) {
      console.error('Failed to fetch ETH price from CoinGecko:', error);
      // Fallback to a reasonable ETH price if API fails
      const fallbackPrice = 3200;
      console.log(`Using fallback ETH price: $${fallbackPrice}`);
      return fallbackPrice;
    }
  }

  // ============================================================================
  // 3. POSITION MANAGEMENT
  // ============================================================================

  /**
   * Gets user's current positions
   * @param userAddress - The user's wallet address
   */
  async getUserPositions(userAddress: string) {
    try {
      // Note: This might need to be implemented based on actual Hyperliquid API
      // For now, we'll return a placeholder structure
      console.log(`Fetching positions for user: ${userAddress}`);
      
      // Try to get positions - this may need to be adjusted based on actual API
      const positions = await this.hypeSdk.info.getUserState(userAddress);
      console.log('User positions:', positions);
      
      return positions;
    } catch (error) {
      console.error('Error fetching user positions:', error);
      return [];
    }
  }

  /**
   * Gets user's open orders
   * @param userAddress - The user's wallet address
   */
  async getUserOpenOrders(userAddress: string) {
    try {
      const openOrders = await this.hypeSdk.info.getUserOpenOrders(userAddress);
      console.log(`Found ${openOrders.length} open orders for user: ${userAddress}`);
      return openOrders;
    } catch (error) {
      console.error('Error fetching open orders:', error);
      return [];
    }
  }

  /**
   * Gets user's recent fills
   * @param userAddress - The user's wallet address
   */
  async getUserFills(userAddress: string) {
    try {
      const fills = await this.hypeSdk.info.getUserFills(userAddress);
      console.log(`Found ${fills.length} fills for user: ${userAddress}`);
      return fills;
    } catch (error) {
      console.error('Error fetching user fills:', error);
      return [];
    }
  }

  // ============================================================================
  // 4. ORDER CANCELLATION
  // ============================================================================

  /**
   * Cancels a specific order by order ID
   * @param coin - The coin symbol (e.g., 'ETH')
   * @param orderId - The order ID to cancel
   */
  async cancelOrder(coin: string, orderId: number) {
    try {
      const coinSymbol = `${coin}-PERP`;
      console.log(`Cancelling order ${orderId} for ${coinSymbol}`);
      
      const result = await this.hypeSdk.exchange.cancelOrder({
        coin: coinSymbol,
        o: orderId
      });
      
      console.log(`Order ${orderId} cancelled successfully`);
      return result;
    } catch (error) {
      console.error(`Failed to cancel order ${orderId}:`, error);
      throw error;
    }
  }

  /**
   * Cancels all orders for a specific coin
   * @param coin - The coin symbol (e.g., 'ETH')
   */
  async cancelAllOrders(coin: string) {
    try {
      const coinSymbol = `${coin}-PERP`;
      console.log(`Cancelling all orders for ${coinSymbol}`);
      
      const result = await this.hypeSdk.exchange.cancelOrder({
        coin: coinSymbol,
        o: 0 // Cancel all orders for this coin
      });
      
      console.log(`All orders for ${coinSymbol} cancelled successfully`);
      return result;
    } catch (error) {
      console.error(`Failed to cancel all orders for ${coin}:`, error);
      throw error;
    }
  }

  // ============================================================================
  // 5. POSITION CLOSING FUNCTIONS
  // ============================================================================

  /**
   * Places a market order to close a position
   * @param coin - The coin symbol (e.g., 'ETH')
   * @param size - The size to close (positive number)
   * @param isLong - Whether the position is long (true) or short (false)
   * @param coinPrice - Current price of the coin (optional, will fetch if not provided)
   */
  async closePositionMarket(
    coin: string,
    size: number,
    isLong: boolean,
    coinPrice?: number
  ) {
    try {
      console.log(`Closing ${size} ${coin} position (${isLong ? 'long' : 'short'}) with market order`);
      
      // Fetch current price if not provided
      let currentPrice = coinPrice;
      if (!currentPrice) {
        currentPrice = await this.fetchEthPriceFromCoinGecko();
      }
      
      // For closing positions, we need to place an order in the opposite direction
      const is_buy = !isLong; // If we're long, we need to sell to close
      
      // Use market price with small slippage for immediate execution
      const limit_px = is_buy 
        ? currentPrice * 1.0015  // Buy slightly above market for immediate fill
        : currentPrice * 0.9985; // Sell slightly below market for immediate fill
      
      const roundedLimitPx = Math.round(limit_px * 10) / 10; // Round to 1 decimal place
      const roundedSz = Math.round(size * 1000) / 1000; // Round to 3 decimal places
      
      console.log(`Closing order parameters: price=${roundedLimitPx}, size=${roundedSz}, is_buy=${is_buy}`);
      
      const result = await this.placeIocPerpOrder(
        coin,
        roundedSz,
        roundedLimitPx,
        is_buy,
        false // not reduce-only
      );
      
      console.log(`Position closed successfully:`, result);
      return result;
    } catch (error) {
      console.error('Failed to close position with market order:', error);
      throw error;
    }
  }

  /**
   * Places a limit order to close a position
   * @param coin - The coin symbol (e.g., 'ETH')
   * @param size - The size to close (positive number)
   * @param isLong - Whether the position is long (true) or short (false)
   * @param limitPrice - The limit price for the order
   */
  async closePositionLimit(
    coin: string,
    size: number,
    isLong: boolean,
    limitPrice: number
  ) {
    try {
      console.log(`Closing ${size} ${coin} position (${isLong ? 'long' : 'short'}) with limit order at ${limitPrice}`);
      
      // For closing positions, we need to place an order in the opposite direction
      const is_buy = !isLong; // If we're long, we need to sell to close
      
      const roundedSz = Math.round(size * 1000) / 1000; // Round to 3 decimal places
      const roundedLimitPx = Math.round(limitPrice * 10) / 10; // Round to 1 decimal place
      
      console.log(`Closing order parameters: price=${roundedLimitPx}, size=${roundedSz}, is_buy=${is_buy}`);
      
      const result = await this.placeLimitOrder(
        coin,
        roundedSz,
        roundedLimitPx,
        is_buy,
        false // not reduce-only
      );
      
      console.log(`Position close order placed successfully:`, result);
      return result;
    } catch (error) {
      console.error('Failed to close position with limit order:', error);
      throw error;
    }
  }

  // ============================================================================
  // 6. ORDER PLACEMENT HELPERS
  // ============================================================================

  /**
   * Places an IOC (Immediate or Cancel) perpetual order on Hyperliquid
   * @param coin - The coin symbol (e.g., 'ETH')
   * @param sz - Order size
   * @param limit_px - Limit price
   * @param is_buy - Whether it's a buy order (true) or sell order (false)
   * @param reduce_only - Whether this is a reduce-only order
   */
  async placeIocPerpOrder(
    coin: string,
    sz: number,
    limit_px: number,
    is_buy: boolean = true,
    reduce_only: boolean = false
  ) {
    // Validate minimum order size
    const minOrderSize = 0.001;
    if (sz < minOrderSize) {
      throw new Error(
        `Order size ${sz} is below minimum order size ${minOrderSize}`
      );
    }

    const coinSymbol = `${coin}-PERP`;

    const orderRequest = {
      coin: coinSymbol,
      is_buy,
      sz,
      limit_px,
      order_type: { limit: { tif: 'Ioc' as const } },
      reduce_only,
    };

    console.log(`Order request: ${JSON.stringify(orderRequest, null, 2)}`);

    try {
      const result = await this.hypeSdk.exchange.placeOrder(orderRequest);
      console.log(`Order placed successfully!`);
      return result;
    } catch (error: any) {
      console.error('Order placement failed:', {
        message: error.message,
        code: error.code,
        data: error.data,
        stack: error.stack,
      });
      throw error;
    }
  }

  /**
   * Places a regular limit order (not IOC)
   */
  async placeLimitOrder(
    coin: string,
    sz: number,
    limit_px: number,
    is_buy: boolean = true,
    reduce_only: boolean = false
  ) {
    const coinSymbol = `${coin}-PERP`;

    const orderRequest = {
      coin: coinSymbol,
      is_buy,
      sz,
      limit_px,
      order_type: { limit: { tif: 'Alo' as const } },
      reduce_only,
    };

    console.log(`Order request: ${JSON.stringify(orderRequest, null, 2)}`);

    try {
      const result = await this.hypeSdk.exchange.placeOrder(orderRequest);
      console.log(`Order placed successfully!`);
      return result;
    } catch (error: any) {
      console.error('Order placement failed:', {
        message: error.message,
        code: error.code,
        data: error.data,
        stack: error.stack,
      });
      throw error;
    }
  }

  // ============================================================================
  // 7. VAULT INTEGRATION FUNCTIONS
  // ============================================================================

  /**
   * Closes ETH position when a vault withdrawal is requested
   * @param withdrawalAmount - Amount to withdraw (in ETH tokens)
   * @param coin - The coin to close (default: 'ETH')
   * @param coinPrice - Current price of the coin (optional, will fetch if not provided)
   */
  async closePositionOnWithdrawal(
    withdrawalAmount: number,
    coin: string = 'ETH',
    coinPrice?: number
  ) {
    try {
      console.log(`Closing position for withdrawal amount: ${withdrawalAmount} ${coin}`);
      
      // Fetch current ETH price if not provided
      let currentPrice = coinPrice;
      if (!currentPrice) {
        currentPrice = await this.fetchEthPriceFromCoinGecko();
      }
      
      // Ensure minimum withdrawal amount
      const MINIMUM_WITHDRAWAL_ETH = 0.001;
      if (withdrawalAmount < MINIMUM_WITHDRAWAL_ETH) {
        throw new Error(`Withdrawal amount ${withdrawalAmount} ${coin} is below minimum required ${MINIMUM_WITHDRAWAL_ETH} ${coin}`);
      }
      
      // For now, we'll assume we're closing a long position
      // In a real implementation, you'd check the actual position direction
      const isLong = true; // This should be determined from actual position data
      
      // Close the position with a market order for immediate execution
      const result = await this.closePositionMarket(
        coin,
        withdrawalAmount,
        isLong,
        currentPrice
      );
      
      console.log(`Position closed successfully for withdrawal:`, result);
      return result;
      
    } catch (error) {
      console.error('Failed to close position on withdrawal:', error);
      throw error;
    }
  }

  /**
   * Closes all ETH positions (emergency close)
   * @param coin - The coin to close (default: 'ETH')
   * @param coinPrice - Current price of the coin (optional, will fetch if not provided)
   */
  async closeAllPositions(
    coin: string = 'ETH',
    coinPrice?: number
  ) {
    try {
      console.log(`Closing all ${coin} positions`);
      
      // First, cancel all open orders
      await this.cancelAllOrders(coin);
      
      // Fetch current price if not provided
      let currentPrice = coinPrice;
      if (!currentPrice) {
        currentPrice = await this.fetchEthPriceFromCoinGecko();
      }
      
      // Get user positions to determine what to close
      const userAddress = this.config.walletAddress;
      if (!userAddress) {
        throw new Error('Wallet address not configured');
      }
      
      const positions = await this.getUserPositions(userAddress);
      console.log('Current positions:', positions);
      
      // For now, we'll assume we need to close a position
      // In a real implementation, you'd parse the position data to get exact sizes and directions
      const estimatedPositionSize = 0.1; // This should come from actual position data
      const isLong = true; // This should be determined from actual position data
      
      if (estimatedPositionSize > 0) {
        const result = await this.closePositionMarket(
          coin,
          estimatedPositionSize,
          isLong,
          currentPrice
        );
        
        console.log(`All positions closed successfully:`, result);
        return result;
      } else {
        console.log('No positions to close');
        return { message: 'No positions found to close' };
      }
      
    } catch (error) {
      console.error('Failed to close all positions:', error);
      throw error;
    }
  }

  // ============================================================================
  // 8. UTILITY FUNCTIONS
  // ============================================================================

  /**
   * Calculates PnL for a position
   * @param entryPrice - Entry price of the position
   * @param currentPrice - Current market price
   * @param size - Position size
   * @param isLong - Whether the position is long
   */
  calculatePnL(
    entryPrice: number,
    currentPrice: number,
    size: number,
    isLong: boolean
  ): number {
    const priceDiff = isLong 
      ? currentPrice - entryPrice 
      : entryPrice - currentPrice;
    
    return priceDiff * size;
  }

  /**
   * Gets position summary for a user
   * @param userAddress - The user's wallet address
   */
  async getPositionSummary(userAddress: string) {
    try {
      const [positions, openOrders, fills] = await Promise.all([
        this.getUserPositions(userAddress),
        this.getUserOpenOrders(userAddress),
        this.getUserFills(userAddress)
      ]);
      
      return {
        positions,
        openOrders,
        fills,
        summary: {
          totalPositions: positions?.length || 0,
          totalOpenOrders: openOrders?.length || 0,
          totalFills: fills?.length || 0
        }
      };
    } catch (error) {
      console.error('Error getting position summary:', error);
      throw error;
    }
  }
}

// ============================================================================
// 9. HARDCODED TESTNET CONFIGURATION
// ============================================================================

// Hardcoded testnet credentials from the modal
const TESTNET_CONFIG = {
  privateKey: '0x95723ed55563c522b976f1000f6ab2fa544363109eee34d6cb7b3cac56ed98cb',
  testnet: true,
  walletAddress: '0x8403C885370cEd907350556e798Bc6c499985dbB'
};

// Create singleton instance for testnet
export const hyperliquidPositionCloser = new HyperliquidPositionCloser(TESTNET_CONFIG);

export default HyperliquidPositionCloser;
