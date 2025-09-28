#!/bin/bash

# Flow EVM Deployment Script for Subway Surfers Game
# This script deploys the contracts to Flow EVM testnet or mainnet

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if private key is set
if [ -z "$PRIVATE_KEY" ]; then
    print_error "PRIVATE_KEY environment variable is not set!"
    print_status "Please set your private key: export PRIVATE_KEY=your_private_key_here"
    exit 1
fi

# Check if network is specified
if [ -z "$1" ]; then
    print_error "Please specify network: testnet or mainnet"
    print_status "Usage: ./deploy-flow.sh [testnet|mainnet]"
    exit 1
fi

NETWORK=$1

# Set network-specific variables
if [ "$NETWORK" = "testnet" ]; then
    RPC_URL="https://testnet.evm.nodes.onflow.org"
    CHAIN_ID="545"
    EXPLORER_URL="https://testnet.flowscan.org"
    print_status "Deploying to Flow EVM Testnet"
elif [ "$NETWORK" = "mainnet" ]; then
    RPC_URL="https://mainnet.evm.nodes.onflow.org"
    CHAIN_ID="747"
    EXPLORER_URL="https://flowscan.org"
    print_status "Deploying to Flow EVM Mainnet"
else
    print_error "Invalid network. Use 'testnet' or 'mainnet'"
    exit 1
fi

print_status "RPC URL: $RPC_URL"
print_status "Chain ID: $CHAIN_ID"
print_status "Explorer: $EXPLORER_URL"

# Check if forge is installed
if ! command -v forge &> /dev/null; then
    print_error "Forge is not installed. Please install Foundry first."
    exit 1
fi

# Check if contracts are built
if [ ! -d "out" ]; then
    print_status "Building contracts..."
    forge build
fi

# Deploy contracts
print_status "Starting deployment..."

# Create deployment log file
DEPLOYMENT_LOG="deployment-${NETWORK}-$(date +%Y%m%d-%H%M%S).log"
print_status "Deployment log: $DEPLOYMENT_LOG"

# Deploy with foundry
print_status "Deploying contracts using Foundry..."

forge script script/DeployFlowEVM.s.sol \
    --rpc-url "$RPC_URL" \
    --broadcast \
    --verify \
    --chain-id "$CHAIN_ID" \
    --etherscan-api-key "$ETHERSCAN_API_KEY" \
    2>&1 | tee "$DEPLOYMENT_LOG"

# Check if deployment was successful
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    print_success "Deployment completed successfully!"
    
    # Extract contract addresses from log
    print_status "Extracting contract addresses..."
    
    GAME_TOKEN_ADDR=$(grep "GameToken deployed at:" "$DEPLOYMENT_LOG" | cut -d: -f2 | tr -d ' ')
    GAME_VAULT_ADDR=$(grep "GameVault deployed at:" "$DEPLOYMENT_LOG" | cut -d: -f2 | tr -d ' ')
    GAME_ADDR=$(grep "SubwaySurfersGame deployed at:" "$DEPLOYMENT_LOG" | cut -d: -f2 | tr -d ' ')
    
    if [ ! -z "$GAME_TOKEN_ADDR" ] && [ ! -z "$GAME_VAULT_ADDR" ] && [ ! -z "$GAME_ADDR" ]; then
        print_success "Contract addresses:"
        echo "  GameToken: $GAME_TOKEN_ADDR"
        echo "  GameVault: $GAME_VAULT_ADDR"
        echo "  SubwaySurfersGame: $GAME_ADDR"
        
        # Create environment file
        ENV_FILE=".env.${NETWORK}"
        cat > "$ENV_FILE" << EOF
# Flow EVM ${NETWORK^} Deployment
NETWORK=$NETWORK
RPC_URL=$RPC_URL
CHAIN_ID=$CHAIN_ID
EXPLORER_URL=$EXPLORER_URL

# Contract Addresses
GAME_TOKEN_ADDRESS=$GAME_TOKEN_ADDR
GAME_VAULT_ADDRESS=$GAME_VAULT_ADDR
GAME_ADDRESS=$GAME_ADDR

# Your private key (keep this secure!)
PRIVATE_KEY=$PRIVATE_KEY
EOF
        
        print_success "Environment file created: $ENV_FILE"
        
        # Test the deployment
        print_status "Testing deployment..."
        export GAME_TOKEN_ADDRESS="$GAME_TOKEN_ADDR"
        export GAME_VAULT_ADDRESS="$GAME_VAULT_ADDR"
        export GAME_ADDRESS="$GAME_ADDR"
        
        forge script script/TestFlowEVM.s.sol --rpc-url "$RPC_URL" --chain-id "$CHAIN_ID"
        
        print_success "Deployment test completed!"
        
        # Display next steps
        echo ""
        print_status "Next steps:"
        echo "1. View contracts on explorer: $EXPLORER_URL"
        echo "2. Test the integration: node flow-integration.js"
        echo "3. Monitor events using Flow data sources"
        echo "4. Set up sponsored transactions for gasless interactions"
        
    else
        print_warning "Could not extract contract addresses from deployment log"
    fi
    
else
    print_error "Deployment failed! Check the log file: $DEPLOYMENT_LOG"
    exit 1
fi

print_success "Flow EVM deployment completed!"
