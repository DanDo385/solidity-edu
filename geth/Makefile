.PHONY: help tidy build test clean run-all

# Default target
help:
	@echo "Ethereum Go Development Track"
	@echo ""
	@echo "Available targets:"
	@echo "  tidy        - Run go mod tidy to update dependencies"
	@echo "  build       - Build all modules"
	@echo "  test        - Run tests (if any)"
	@echo "  clean       - Remove build artifacts"
	@echo "  run-all     - Run all module solutions (requires INFURA_RPC_URL)"
	@echo ""
	@echo "Run individual modules:"
	@echo "  make run-01  - Run 01-stack solution"
	@echo "  make run-02  - Run 02-rpc-basics solution"
	@echo "  ... (run-01 through run-25)"
	@echo ""
	@echo "Example:"
	@echo "  export INFURA_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY"
	@echo "  make run-01"

# Update dependencies
tidy:
	@echo "Running go mod tidy..."
	@go mod tidy
	@echo "✓ Dependencies updated"

# Build all modules
build:
	@echo "Building all modules..."
	@for dir in [0-9]*/cmd/*_solution; do \
		if [ -d "$$dir" ]; then \
			module=$$(basename $$dir | sed 's/_solution//'); \
			echo "Building $$module..."; \
			go build -o bin/$$module $$dir/main.go || true; \
		fi \
	done
	@echo "✓ Build complete (binaries in bin/)"

# Run tests (placeholder for future tests)
test:
	@echo "No tests defined yet"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf bin/
	@find . -name "*.test" -delete
	@find . -name "*.out" -delete
	@find . -name "*.db" -delete
	@find . -name "*.db-shm" -delete
	@find . -name "*.db-wal" -delete
	@echo "✓ Clean complete"

# Run individual modules (01-25)
run-01:
	@go run 01-stack/cmd/01-stack_solution/main.go

run-02:
	@go run 02-rpc-basics/cmd/02-rpc-basics_solution/main.go

run-03:
	@go run 03-keys-addresses/cmd/03-keys-addresses_solution/main.go

run-04:
	@go run 04-accounts-balances/cmd/04-accounts-balances_solution/main.go 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb

run-05:
	@go run 05-tx-nonces/cmd/05-tx-nonces_solution/main.go

run-06:
	@go run 06-eip1559/cmd/06-eip1559_solution/main.go

run-07:
	@go run 07-eth-call/cmd/07-eth-call_solution/main.go

run-08:
	@go run 08-abigen/cmd/08-abigen_solution/main.go

run-09:
	@go run 09-events/cmd/09-events_solution/main.go

run-10:
	@go run 10-filters/cmd/10-filters_solution/main.go

run-11:
	@go run 11-storage/cmd/11-storage_solution/main.go

run-12:
	@go run 12-proofs/cmd/12-proofs_solution/main.go

run-13:
	@go run 13-trace/cmd/13-trace_solution/main.go

run-14:
	@go run 14-explorer/cmd/14-explorer_solution/main.go

run-15:
	@go run 15-receipts/cmd/15-receipts_solution/main.go

run-16:
	@go run 16-concurrency/cmd/16-concurrency_solution/main.go

run-17:
	@go run 17-indexer/cmd/17-indexer_solution/main.go -token 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

run-18:
	@go run 18-reorgs/cmd/18-reorgs_solution/main.go

run-19:
	@go run 19-devnets/cmd/19-devnets_solution/main.go

run-20:
	@go run 20-node/cmd/20-node_solution/main.go

run-21:
	@go run 21-sync/cmd/21-sync_solution/main.go

run-22:
	@go run 22-peers/cmd/22-peers_solution/main.go

run-23:
	@go run 23-mempool/cmd/23-mempool_solution/main.go

run-24:
	@go run 24-monitor/cmd/24-monitor_solution/main.go

run-25:
	@go run 25-toolbox/cmd/25-toolbox_solution/main.go status
