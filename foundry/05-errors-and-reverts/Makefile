.PHONY: build clean build-filtered

# Standard build
build:
	forge build

# Clean output directory
clean:
	forge clean

# Build and remove solution/test/script artifacts from out directory
build-filtered: build
	@echo "Cleaning solution, test, script, and lib artifacts from out directory..."
	@find out -type d -name "solution" -exec rm -rf {} + 2>/dev/null || true
	@rm -rf out/*Solution*.sol out/*Test*.sol out/*.s.sol 2>/dev/null || true
	@find out -type f -path "*/test/*" -delete 2>/dev/null || true
	@find out -type f -path "*/script/*" -delete 2>/dev/null || true
	@find out -type f -path "*/lib/*" -delete 2>/dev/null || true
	@rm -rf out/Test.sol out/Script.sol out/Vm.sol out/console.sol out/safeconsole.sol 2>/dev/null || true
	@rm -rf out/Std*.sol out/IMulticall3.sol out/Base.sol 2>/dev/null || true
	@echo "Done! out directory now contains only src contract artifacts (excluding solution files)"

# Default target
all: build-filtered
