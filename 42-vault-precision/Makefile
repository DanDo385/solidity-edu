.PHONY: help install build test test-v test-vv coverage clean deploy-local

# Default target
help:
	@echo "Available targets:"
	@echo "  install      - Install dependencies"
	@echo "  build        - Build the project"
	@echo "  test         - Run all tests"
	@echo "  test-v       - Run tests with verbose output"
	@echo "  test-vv      - Run tests with very verbose output"
	@echo "  test-gas     - Run tests with gas reporting"
	@echo "  test-fuzz    - Run only fuzz tests"
	@echo "  coverage     - Generate coverage report"
	@echo "  clean        - Clean build artifacts"
	@echo "  deploy-local - Deploy to local testnet"
	@echo ""
	@echo "Test specific functions:"
	@echo "  make test-match TEST=testRoundingDirection"

# Install dependencies
install:
	forge install openzeppelin/openzeppelin-contracts --no-commit
	forge install foundry-rs/forge-std --no-commit

# Build the project
build:
	forge build

# Run all tests
test:
	forge test

# Run tests with verbose output
test-v:
	forge test -v

# Run tests with very verbose output
test-vv:
	forge test -vv

# Run tests with gas reporting
test-gas:
	forge test --gas-report

# Run specific test
test-match:
	forge test --match-test $(TEST) -vvv

# Run only fuzz tests
test-fuzz:
	forge test --match-test testFuzz -vv

# Run tests for rounding
test-rounding:
	forge test --match-test "testDeposit|testMint|testWithdraw|testRedeem" -vvv

# Run tests for preview functions
test-preview:
	forge test --match-test testPreview -vvv

# Run tests for edge cases
test-edge:
	forge test --match-test "testConvert|testZero" -vvv

# Run tests for attacks
test-attacks:
	forge test --match-test "testInflation|testDrain" -vvv

# Run tests for invariants
test-invariants:
	forge test --match-test "testVaultCannot|testUserCannot|testTotal" -vvv

# Generate coverage report
coverage:
	forge coverage
	forge coverage --report lcov
	@echo "Coverage report generated: lcov.info"

# Clean build artifacts
clean:
	forge clean
	rm -rf cache out

# Format code
fmt:
	forge fmt

# Check formatting
fmt-check:
	forge fmt --check

# Deploy to local network
deploy-local:
	forge script script/DeployProject42.s.sol:DeployLocalTestVault --fork-url http://localhost:8545 --broadcast

# Deploy skeleton to testnet
deploy-testnet:
	@echo "Make sure to set SEPOLIA_RPC_URL and PRIVATE_KEY in .env"
	forge script script/DeployProject42.s.sol:DeployProject42 --rpc-url sepolia --broadcast --verify

# Deploy solution to testnet
deploy-solution-testnet:
	@echo "Make sure to set SEPOLIA_RPC_URL and PRIVATE_KEY in .env"
	forge script script/DeployProject42.s.sol:DeployProject42Solution --rpc-url sepolia --broadcast --verify

# Snapshot gas usage
snapshot:
	forge snapshot

# Compare gas snapshots
snapshot-diff:
	forge snapshot --diff

# Run Slither static analysis (requires slither to be installed)
slither:
	slither src/

# Check contract size
size:
	forge build --sizes
