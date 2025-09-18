# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# only export these env vars if ENVIRONMENT = local
ifeq ($(ENVIRONMENT), local)
	export ETHEREUM_RPC_URL = $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential)
	export OPTIMISM_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPTIMISM_RPC_URL/credential)
	export BASE_RPC_URL := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential)
	export ONE_INCH_API_KEY := $(shell op read op://5ylebqljbh3x6zomdxi3qd7tsa/OneInch/credential)
endif


deploy-poc:
	forge script script/PoC/Deploy.s.sol --broadcast --legacy --multi --verify

build :; $(MAKE) ensure-merkle-cache && forge build && $(MAKE) generate

forge-script :; forge script $(SCRIPT) $(ARGS)

forge-test :; $(MAKE) ensure-merkle-cache && forge test --match-test $(TEST) $(ARGS)

# Internal forge-test without merkle cache check (used by cache generation)
forge-test-internal :; forge test --match-path $(TEST) $(ARGS)

# Internal forge-test with coverage profile (used by cache generation)
forge-test-coverage-internal :; FOUNDRY_PROFILE=coverage forge test --match-path $(TEST) $(ARGS)

# Internal forge-coverage without merkle cache check (used by cache generation)
forge-coverage-internal :; FOUNDRY_PROFILE=coverage forge coverage --jobs 10 --ir-minimum $(ARGS)

forge-coverage-internal2 :; FOUNDRY_PROFILE=coverage forge coverage --jobs 10 --ir-minimum --match-contract SuperVaultTest -vv

# Ensure merkle cache is up to date before running tests/builds
ensure-merkle-cache:
	@echo "🌲 Checking merkle cache..."
	@cd test/utils/merkle/merkle-js && node deterministic-merkle-pregeneration.js

# Ensure merkle cache is up to date for CI environments
ensure-merkle-cache-ci:
	@echo "🌲 Checking merkle cache (CI mode)..."
	@cd test/utils/merkle/merkle-js && ENVIRONMENT=ci node deterministic-merkle-pregeneration.js

# Ensure merkle cache is up to date before running tests/builds
ensure-merkle-cache-coverage:
	@echo "🌲 Checking merkle cache for coverage..."
	@cd test/utils/merkle/merkle-js && FOUNDRY_PROFILE=coverage node deterministic-merkle-pregeneration.js

# Force regenerate merkle cache
regenerate-merkle-cache:
	@echo "🌲 Force regenerating merkle cache..."
	@cd test/utils/merkle/merkle-js && node deterministic-merkle-pregeneration.js --force

# Force regenerate merkle cache for coverage
regenerate-merkle-cache-coverage:
	@echo "🌲 Force regenerating merkle cache for coverage..."
	@cd test/utils/merkle/merkle-js && FOUNDRY_PROFILE=coverage node deterministic-merkle-pregeneration.js --force

# Force regenerate merkle cache for CI environments
regenerate-merkle-cache-ci:
	@echo "🌲 Force regenerating merkle cache (CI mode)..."
	@cd test/utils/merkle/merkle-js && ENVIRONMENT=ci node deterministic-merkle-pregeneration.js --force

# Check merkle cache status
merkle-status:
	@cd test/utils/merkle/merkle-js && node deterministic-merkle-pregeneration.js --status

ftest :; $(MAKE) ensure-merkle-cache && forge test

ftest-vvv :; $(MAKE) ensure-merkle-cache && forge test -vvv --jobs 2

ftest-ci :; $(MAKE) regenerate-merkle-cache-ci && forge test -v --jobs 2

ftest-quick :; forge test

coverage :; $(MAKE) ensure-merkle-cache-coverage && FOUNDRY_PROFILE=coverage forge coverage --jobs 10 --ir-minimum --report lcov

coverage-genhtml :; $(MAKE) ensure-merkle-cache-coverage && FOUNDRY_PROFILE=coverage forge coverage --jobs 10 --ir-minimum --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage --ignore-errors inconsistent,corrupt,unused --exclude 'src/libraries/*' --exclude 'src/oracles/SuperOracleBase.sol' --exclude 'src/oracles/SuperOracle.sol' --exclude 'src/oracles/SuperOracleL2.sol' --exclude 'src/SuperAsset/*' --exclude 'src/UP/*' --exclude 'src/VaultBank/*' --exclude 'src/vendor/*' --exclude 'src/BundlerRegistry.sol' --exclude 'test/*'

test-vvv :; $(MAKE) ensure-merkle-cache && forge test --match-test test_SuperVault_MultipleDeposits_PartialRedemptions -vvvv --jobs 10

test-integration :; $(MAKE) ensure-merkle-cache && forge test --match-test test_DeBridgeCancelOrderHook -vvvv --jobs 10

test-vvv-quick :; forge test --match-test test_SuperVault_E2E_Flow_With_Ledger_Fees -vvv --jobs 10

test-gas-report-user :; $(MAKE) ensure-merkle-cache && forge test --match-test test_gasReport --gas-report --jobs 10
test-gas-report-2vaults :; $(MAKE) ensure-merkle-cache && forge test --match-test test_gasReport_TwoVaults --gas-report --jobs 10
test-gas-report-3vaults :; $(MAKE) ensure-merkle-cache && forge test --match-test test_gasReport_ThreeVaults --gas-report --jobs 10

test-cache :; $(MAKE) ensure-merkle-cache && forge test --cache-tests

.PHONY: generate
generate:
	rm -rf contract_bindings/*
	./script/run/retrieve-abis.sh
	./script/run/generate-contract-bindings.sh