# Blockchain Integration Features

This document outlines the blockchain integration features added to the Eth vs Sol game.

## Features Added

### 1. Wallet Connection

- **RainbowKit Integration**: Users can connect their wallets using various providers (MetaMask, WalletConnect, etc.)
- **Multi-chain Support**: Supports Ethereum, Polygon, Arbitrum, Optimism, Base, and Sepolia networks
- **Wallet Status Display**: Shows connection status and balance in the game UI

### 2. Blockchain Interactions During Gameplay

- **In-Game Transactions**: Press `B` during gameplay to send blockchain transactions
- **Cooldown System**: 5-second cooldown between blockchain interactions to prevent spam
- **Visual Feedback**: Success/failure messages displayed in-game
- **Transaction Status**: Real-time feedback on transaction status

### 3. Game Over Blockchain Features

- **Transaction Button**: Send transactions from the game over screen
- **Keyboard Shortcut**: Press `T` to trigger blockchain transactions
- **Error Handling**: Proper error handling for failed transactions

### 4. UI Components

- **Wallet Button**: Top-right corner wallet connection button
- **Balance Display**: Shows current ETH balance when connected
- **Blockchain HUD**: In-game UI showing blockchain interaction status
- **Cooldown Timer**: Visual countdown for blockchain interaction cooldown

## Technical Implementation

### Dependencies Added

- `@rainbow-me/rainbowkit`: Wallet connection UI
- `@tanstack/react-query`: Data fetching and caching
- `viem`: Ethereum library for blockchain interactions
- `wagmi`: React hooks for Ethereum

### Key Files

- `app/providers.tsx`: Wallet and query client providers
- `app/hooks/useWallet.ts`: Custom hook for wallet functionality
- `app/components/WalletButton.tsx`: Wallet connection component
- `app/page.tsx`: Main game with blockchain integration

## Usage

### Setting Up

1. Create a WalletConnect project ID at https://cloud.walletconnect.com/
2. Add the project ID to your environment variables:
   ```
   NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your-project-id
   ```

### Playing the Game

1. **Connect Wallet**: Click the wallet button in the top-right corner
2. **Start Game**: Press `P` or click "Play" to start
3. **Blockchain Interaction**: Press `B` during gameplay to send transactions
4. **Game Over**: Press `T` on the game over screen to send transactions

### Controls

- `P`: Play game
- `I`: Instructions
- `B`: Blockchain interaction (during gameplay)
- `T`: Send transaction (game over screen)
- `R`: Restart game
- `ESC`: Main menu

## Transaction Details

- **Default Recipient**: Burn address (0x000000000000000000000000000000000000dEaD)
- **Amount**: 0.0001 ETH (during gameplay), 0.001 ETH (game over)
- **Network**: Supports all configured networks

## Customization

You can modify the transaction amounts, recipients, and blockchain interactions by editing the `handleGameBlockchainInteraction` and `handleBlockchainTransaction` functions in `app/page.tsx`.
