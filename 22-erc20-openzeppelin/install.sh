#!/bin/bash
# Installation script for Project 22: ERC-20 (OpenZeppelin)

set -e

echo "Installing dependencies for Project 22..."

# Install OpenZeppelin Contracts
echo "Installing OpenZeppelin Contracts v5.0.0..."
forge install OpenZeppelin/openzeppelin-contracts@v5.0.0 --no-commit

# Install Forge Standard Library (if not already installed)
if [ ! -d "lib/forge-std" ]; then
    echo "Installing Forge Standard Library..."
    forge install foundry-rs/forge-std --no-commit
fi

echo ""
echo "Dependencies installed successfully!"
echo ""
echo "You can now:"
echo "  - Run tests: forge test"
echo "  - Build: forge build"
echo "  - Run specific tests: forge test --match-contract Project22Test -vv"
echo ""
