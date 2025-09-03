#!/usr/bin/env node

/**
 * Foundry-Compatible Merkle Tree Pre-Generation
 * 
 * This script replicates the exact same address calculation logic used in BaseTest.t.sol
 * by inheriting from BaseTest, calling setUp(), and extracting the calculated addresses.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const AddressListGenerator = require('./generate-address-lists');

class DeterministicMerkleGen {
    constructor() {
        this.verbose = process.argv.includes('--verbose') || process.argv.includes('-v') || process.argv.includes('--status');
        this.force = process.argv.includes('--force') || process.argv.includes('-f');
        this.statusOnly = process.argv.includes('--status');
        this.showHelp = process.argv.includes('--help') || process.argv.includes('-h');
        this.cacheFile = '../target/deterministic_addresses.json';
    }

    log(...args) {
        if (this.verbose) {
            console.log('[DETERMINISTIC]', ...args);
        }
    }

    /**
     * Show help message
     */
    displayHelp() {
        console.log(`
Deterministic Merkle Tree Pre-Generation

USAGE:
    node deterministic-merkle-pregeneration.js [OPTIONS]

OPTIONS:
    --help, -h          Show this help message
    --verbose, -v       Enable verbose logging
    --force, -f         Force regeneration even if cache appears valid
    --status            Check cache status without regenerating

EXAMPLES:
    node deterministic-merkle-pregeneration.js
        → Generate cache if needed (normal mode)
    
    node deterministic-merkle-pregeneration.js --status
        → Check if cache is valid without regenerating
    
    node deterministic-merkle-pregeneration.js --force
        → Force regenerate cache even if it appears valid
    
    FOUNDRY_PROFILE=coverage node deterministic-merkle-pregeneration.js
        → Generate cache using coverage environment
    
    node deterministic-merkle-pregeneration.js --verbose --status
        → Check cache status with detailed logging
    
    MERKLE_GEN_TIMEOUT=300000 node deterministic-merkle-pregeneration.js
        → Use custom timeout (5 minutes in this example)

DESCRIPTION:
    This script ensures the merkle tree cache is up to date with current hook addresses.
    It automatically detects when hook addresses change and regenerates the cache.
    The cache includes both the merkle tree data and optimized lookup indices.
    
    When FOUNDRY_PROFILE=coverage is set, the script uses the coverage profile to extract
    addresses that match the coverage testing environment.
    
    TIMEOUT BEHAVIOR:
    The script automatically adjusts timeouts based on the environment:
    - Coverage in CI: 10 minutes (coverage tests are slower in CI)
    - Coverage locally: 5 minutes  
    - Regular tests in CI: 4 minutes
    - Regular tests locally: 2 minutes
    Override with MERKLE_GEN_TIMEOUT environment variable (in milliseconds).
`);
    }

    /**
     * Get addresses using the BaseTest forge test method
     */
    calculateAllAddresses() {
        this.log('Getting addresses using BaseTest forge test...');
        return this.getAddressesViaTest();
    }

    /**
     * Parse console output from either script or test
     */
    parseConsoleOutput(output) {
        const lines = output.split('\n');
        const addresses = {
            vaults: {},
            superVaults: {},
            hooks: {}
        };

        // Look for console.log output lines
        for (const line of lines) {
            // Dynamic vault detection - any line starting with "VAULT_"
            if (line.includes('VAULT_')) {
                const vaultMatch = line.match(/VAULT_([A-Za-z0-9_]+):\s*(0x[a-fA-F0-9]{40})/);
                if (vaultMatch) {
                    const vaultName = vaultMatch[1];
                    const address = vaultMatch[2];
                    addresses.vaults[vaultName] = address;
                    this.log(`Detected vault: ${vaultName} -> ${address}`);
                }
            }
            // SuperVault detection - these should NOT have VAULT_ prefix
            else if (line.includes('globalSVStrategy:') || line.includes('globalSVGearStrategy:') || line.includes('globalRuggableVault:')) {
                const svMatch = line.match(/(global[A-Za-z0-9_]+):\s*(0x[a-fA-F0-9]{40})/);
                if (svMatch) {
                    const svName = svMatch[1];
                    const address = svMatch[2];
                    addresses.superVaults[svName] = address;
                    this.log(`Detected SuperVault: ${svName} -> ${address}`);
                }
            }
            // Dynamic hook detection - any line ending with "Hook:" (contract names)
            else if (line.includes('Hook:')) {
                const hookMatch = line.match(/([A-Za-z0-9]+Hook):\s*(0x[a-fA-F0-9]{40})/);
                if (hookMatch) {
                    const hookName = hookMatch[1]; // Use actual contract name (PascalCase)
                    const address = hookMatch[2];
                    addresses.hooks[hookName] = address;
                    this.log(`Detected hook: ${hookName} -> ${address}`);
                }
            }
            // Special case for MOCK_ETH_RECEIVER
            else if (line.includes('MOCK_ETH_RECEIVER:')) {
                addresses.mockETHReceiver = this.extractAddress(line);
            }
        }

        // Validate the addresses
        this.validateAddresses(addresses);

        this.log('Retrieved addresses from console output:', JSON.stringify(addresses, null, 2));
        this.log(`Detected ${Object.keys(addresses.hooks).length} hooks and ${Object.keys(addresses.vaults).length} vaults`);
        return addresses;
    }

    /**
     * Get addresses using forge test method via make
     */
    getAddressesViaTest() {
        this.log('Running forge test via make...');

        try {
            // Prepare environment for CI/local compatibility
            const testEnv = {
                ...process.env,
                ENVIRONMENT: 'ci', // Use 'ci' to avoid 1Password CLI calls
                // Provide fallback RPC URLs for CI environments that don't need real values
                ETHEREUM_RPC_URL: process.env.ETHEREUM_RPC_URL || 'https://ethereum.publicnode.com',
                OPTIMISM_RPC_URL: process.env.OPTIMISM_RPC_URL || 'https://optimism.publicnode.com',
                BASE_RPC_URL: process.env.BASE_RPC_URL || 'https://base.publicnode.com',
                ONE_INCH_API_KEY: process.env.ONE_INCH_API_KEY || 'dummy-api-key'
            };
            let result = '';

            // Configure timeout based on environment
            // CI environments need longer timeouts, especially for coverage
            const isCoverage = testEnv.FOUNDRY_PROFILE === 'coverage';
            const isCI = process.env.CI === 'true' || process.env.GITHUB_ACTIONS === 'true';

            // Default timeouts (in milliseconds)
            let timeout = 120000; // 2 minutes default
            if (isCoverage && isCI) {
                timeout = 600000; // 10 minutes for coverage in CI
            } else if (isCoverage) {
                timeout = 300000; // 5 minutes for coverage locally
            } else if (isCI) {
                timeout = 240000; // 4 minutes for regular tests in CI
            }

            // Allow override via environment variable
            if (process.env.MERKLE_GEN_TIMEOUT) {
                timeout = parseInt(process.env.MERKLE_GEN_TIMEOUT, 10);
                this.log(`Using custom timeout: ${timeout}ms`);
            }

            // Detect coverage mode
            if (isCoverage) {
                this.log(`Detected coverage environment for address extraction (timeout: ${timeout}ms)`);

                const command = `make forge-coverage-internal ARGS="--match-test test_getAddresses -vv"`;
                result = execSync(command, {
                    encoding: 'utf8',
                    cwd: path.join(__dirname, '../../../..'), // Go to project root
                    timeout: timeout,
                    maxBuffer: 10 * 1024 * 1024, // 10MB buffer instead of default 1MB
                    env: testEnv
                });
            } else {
                this.log(`Running regular test for address extraction (timeout: ${timeout}ms)`);
                result = execSync('make forge-test-internal TEST=test/utils/merkle/config/GetAddressesFromBaseTest.s.sol ARGS="--match-test test_getAddresses -vv"', {
                    encoding: 'utf8',
                    cwd: path.join(__dirname, '../../../..'), // Go to project root
                    timeout: timeout,
                    maxBuffer: 10 * 1024 * 1024, // 10MB buffer instead of default 1MB
                    env: testEnv
                });
            }

            // Parse the console output
            return this.parseConsoleOutput(result);

        } catch (error) {
            this.log('❌ Error during merkle tree generation:', error.message);
            if (this.verbose) {
                this.log('Error details:', error.stack);
            }
            throw error;
        }
    }

    /**
     * Extract address from a console.log line
     */
    extractAddress(line) {
        // Look for pattern like "VAULT_globalSVStrategy: 0x1234..."
        const match = line.match(/0x[a-fA-F0-9]{40}/);
        return match ? match[0] : '';
    }

    /**
     * Validate calculated addresses
     */
    validateAddresses(addresses) {
        const requiredSuperVaults = [
            'globalSVStrategy',
            'globalSVGearStrategy',
            'globalRuggableVault'
        ];

        const testVaults = [
            'test1_DynamicAllocation_MockVault',
            'test3_UnderlyingVaults_StressTest',
            'test6_yieldAccumulation_vault1',
            'test6_yieldAccumulation_vault2',
            'test6_yieldAccumulation_vault3',
            'test6_yieldAccumulation_WithRebalancing_vault1',
            'test6_yieldAccumulation_WithRebalancing_vault2',
            'test6_yieldAccumulation_WithRebalancing_vault3',
            'test10_RuggableVault_Deposit',
            'test10_RuggableVault_Withdraw',
            'test10_RuggableVault_Withdraw_ConvertDistortion',
            'test11_Allocate_NewYieldSource'
        ];



        const requiredHooks = [
            'ApproveAndDeposit4626VaultHook',
            'Redeem4626VaultHook',
            'ApproveAndGearboxStakeHook',
            'GearboxUnstakeHook',
            'MockNativeETHHook'
        ];

        // Check SuperVaults (these are in addresses.superVaults, not addresses.vaults)
        if (!addresses.superVaults) {
            throw new Error('Missing superVaults object');
        }

        // Check required SuperVaults
        for (const superVault of requiredSuperVaults) {
            if (!addresses.superVaults[superVault] || addresses.superVaults[superVault] === '0x0000000000000000000000000000000000000000') {
                throw new Error(`Invalid or missing vault address for ${superVault}: ${addresses.superVaults[superVault]}`);
            }
        }

        // Check regular vaults
        if (!addresses.vaults) {
            throw new Error('Missing vaults object');
        }

        // Check test vaults (optional - not all test environments may have them)
        this.log(`Checking ${testVaults.length} test vault addresses`);

        for (const vault of testVaults) {
            if (addresses.vaults[vault] && addresses.vaults[vault] !== '0x0000000000000000000000000000000000000000') {
                this.log(`✓ Found test vault: ${vault} -> ${addresses.vaults[vault]}`);
            } else {
                this.log(`⚠️ Missing test vault: ${vault}`);
            }
        }

        // Check hooks  
        if (!addresses.hooks) {
            throw new Error('Missing hooks object');
        }
        for (const hook of requiredHooks) {
            if (!addresses.hooks[hook] || addresses.hooks[hook] === '0x0000000000000000000000000000000000000000') {
                throw new Error(`Invalid or missing hook address for ${hook}: ${addresses.hooks[hook]}`);
            }
        }

        this.log('Address validation passed');
    }

    /**
     * Fallback: extract addresses from existing test artifacts
     */
    extractAddressesFromTestArtifacts() {
        this.log('Attempting to extract addresses from test artifacts...');

        // Try to read from existing owner_list.json to get the original addresses
        const originalOwnerListPath = '../target/owner_list.json';

        if (fs.existsSync(originalOwnerListPath)) {
            try {
                const originalOwnerList = JSON.parse(fs.readFileSync(originalOwnerListPath, 'utf8'));

                if (originalOwnerList.length >= 8) {
                    this.log('Found original owner list with', originalOwnerList.length, 'addresses');

                    // Map back to the expected structure based on the original order
                    // The order typically is: strategies first, then hooks
                    return {
                        vaults: {
                            globalSVStrategy: originalOwnerList[0], // First three are strategies
                            globalSVGearStrategy: originalOwnerList[1],
                            globalRuggableVault: originalOwnerList[2]
                        },
                        hooks: {
                            // The remaining are hooks in the order they appear in globalMerkleHooks
                            APPROVE_AND_DEPOSIT_4626_VAULT_HOOK: originalOwnerList[3] || originalOwnerList[0],
                            REDEEM_4626_VAULT_HOOK: originalOwnerList[1] || originalOwnerList[0],
                            APPROVE_AND_GEARBOX_STAKE_HOOK: originalOwnerList[2] || originalOwnerList[0],
                            GEARBOX_UNSTAKE_HOOK: originalOwnerList[3] || originalOwnerList[0]
                        }
                    };
                }
            } catch (error) {
                this.log('Error reading original owner list:', error.message);
            }
        }

        throw new Error('Could not extract addresses from test artifacts');
    }

    /**
     * Check if regeneration is needed with comprehensive validation
     */
    needsRegeneration(currentAddresses) {
        const logPrefix = this.verbose ? '🔍 [CACHE-CHECK]' : '';

        if (this.verbose) {
            console.log(`${logPrefix} Checking cache validity...`);
            console.log(`${logPrefix} Current addresses:`, JSON.stringify(currentAddresses, null, 2));
        }

        // Check if cache file exists
        if (!fs.existsSync(this.cacheFile)) {
            console.log(`${logPrefix} No cache file found - automatic regeneration will be triggered`);
            return true;
        }

        try {
            const cached = JSON.parse(fs.readFileSync(this.cacheFile, 'utf8'));

            if (this.verbose) {
                console.log(`${logPrefix} Cached addresses:`, JSON.stringify(cached.addresses, null, 2));
            }

            // 1. Compare addresses using robust comparison
            const addressesMatch = this.compareAddresses(currentAddresses, cached.addresses);
            if (!addressesMatch) {
                console.log(`${logPrefix} Address mismatch detected - automatic regeneration will be triggered`);
                return true;
            }

            // 2. Check if merkle tree files exist
            if (!fs.existsSync('../output/jsGeneratedRoot_1.json')) {
                console.log(`${logPrefix} Merkle tree files missing - automatic regeneration will be triggered`);
                return true;
            }

            // 3. Check if lookup cache exists
            const lookupCachePath = '../output/lookup_cache_1.json';
            if (!fs.existsSync(lookupCachePath)) {
                console.log(`${logPrefix} Lookup cache missing - automatic regeneration will be triggered`);
                return true;
            }

            // 4. CRITICAL: Validate lookup cache contents against expected addresses
            const lookupCacheValid = this.validateLookupCacheContents(currentAddresses, lookupCachePath);
            if (!lookupCacheValid) {
                console.log(`${logPrefix} Lookup cache contents invalid - automatic regeneration will be triggered`);
                return true;
            }

            if (this.verbose) {
                console.log(`${logPrefix} All cache validation checks passed`);
            }
            return false;

        } catch (error) {
            console.log(`${logPrefix} Error reading cache: ${error.message} - automatic regeneration will be triggered`);
            return true;
        }
    }

    /**
     * Robust address comparison (case-insensitive, normalized)
     */
    compareAddresses(current, cached) {
        const logPrefix = this.verbose ? '🔍 [ADDR-COMPARE]' : '';

        try {
            // Normalize addresses to lowercase for comparison
            const normalizeAddresses = (addresses) => {
                const normalized = { vaults: {}, hooks: {} };
                for (const [key, value] of Object.entries(addresses.vaults || {})) {
                    normalized.vaults[key] = value.toLowerCase();
                }
                for (const [key, value] of Object.entries(addresses.hooks || {})) {
                    normalized.hooks[key] = value.toLowerCase();
                }
                return normalized;
            };

            const currentNorm = normalizeAddresses(current);
            const cachedNorm = normalizeAddresses(cached);

            // Compare vaults
            for (const [key, currentAddr] of Object.entries(currentNorm.vaults)) {
                const cachedAddr = cachedNorm.vaults[key];
                if (currentAddr !== cachedAddr) {
                    console.log(`${logPrefix} Vault address mismatch for ${key}:`);
                    console.log(`${logPrefix}   Current: ${currentAddr}`);
                    console.log(`${logPrefix}   Cached:  ${cachedAddr}`);
                    return false;
                }
            }

            // Compare hooks  
            for (const [key, currentAddr] of Object.entries(currentNorm.hooks)) {
                const cachedAddr = cachedNorm.hooks[key];
                if (currentAddr !== cachedAddr) {
                    console.log(`${logPrefix} Hook address mismatch for ${key}:`);
                    console.log(`${logPrefix}   Current: ${currentAddr}`);
                    console.log(`${logPrefix}   Cached:  ${cachedAddr}`);
                    return false;
                }
            }

            if (this.verbose) {
                console.log(`${logPrefix} Address comparison passed`);
            }
            return true;

        } catch (error) {
            console.log(`${logPrefix} Error comparing addresses: ${error.message}`);
            return false;
        }
    }

    /**
     * Validate that lookup cache contains entries for all expected hook addresses
     */
    validateLookupCacheContents(expectedAddresses, lookupCachePath) {
        const logPrefix = this.verbose ? '🔍 [LOOKUP-VALIDATE]' : '';

        try {
            if (this.verbose) {
                console.log(`${logPrefix} Validating lookup cache contents...`);
            }

            const lookupCache = JSON.parse(fs.readFileSync(lookupCachePath, 'utf8'));
            const lookupMap = lookupCache.lookupMap || {};

            // Extract hook addresses from expected addresses and normalize
            const expectedHookAddresses = Object.values(expectedAddresses.hooks).map(addr => addr.toLowerCase());

            if (this.verbose) {
                console.log(`${logPrefix} Expected hook addresses:`, expectedHookAddresses);
            }

            // Check if lookup cache contains entries for each expected hook address
            const foundAddresses = new Set();

            for (const [key, entry] of Object.entries(lookupMap)) {
                if (entry.hookAddress) {
                    foundAddresses.add(entry.hookAddress.toLowerCase());
                }
            }

            const foundAddressesArray = Array.from(foundAddresses);
            if (this.verbose) {
                console.log(`${logPrefix} Found addresses in lookup cache:`, foundAddressesArray);
            }

            // Check if all expected addresses are present
            const missingAddresses = [];
            for (const expectedAddr of expectedHookAddresses) {
                if (!foundAddresses.has(expectedAddr)) {
                    missingAddresses.push(expectedAddr);
                }
            }

            if (missingAddresses.length > 0) {
                console.log(`${logPrefix} Missing hook addresses in lookup cache:`, missingAddresses);
                return false;
            }

            // Check for unexpected addresses (addresses in cache but not expected)
            const unexpectedAddresses = [];
            for (const foundAddr of foundAddresses) {
                if (!expectedHookAddresses.includes(foundAddr)) {
                    unexpectedAddresses.push(foundAddr);
                }
            }

            if (unexpectedAddresses.length > 0) {
                console.log(`${logPrefix} Unexpected hook addresses in lookup cache:`, unexpectedAddresses);
                console.log(`${logPrefix} This indicates the cache contains stale data`);
                return false;
            }

            if (this.verbose) {
                console.log(`${logPrefix} Lookup cache validation passed - all expected addresses found`);
            }
            return true;

        } catch (error) {
            console.log(`${logPrefix} Error validating lookup cache: ${error.message}`);
            return false;
        }
    }

    /**
     * Generate hash for addresses (kept for backwards compatibility)
     */
    hashAddresses(addresses) {
        // Normalize addresses to lowercase for consistent hashing
        const normalizedAddresses = [
            ...Object.values(addresses.vaults).map(addr => addr.toLowerCase()),
            ...Object.values(addresses.hooks).map(addr => addr.toLowerCase())
        ];
        return JSON.stringify(normalizedAddresses.sort());
    }

    /**
     * Save address cache
     */
    saveAddressCache(addresses) {
        try {
            // Ensure directory exists
            const dir = '../target';
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }

            const cacheData = {
                timestamp: Date.now(),
                addressHash: this.hashAddresses(addresses),
                addresses: addresses
            };

            fs.writeFileSync(this.cacheFile, JSON.stringify(cacheData, null, 2));
            this.log('Saved address cache');
        } catch (error) {
            this.log('Could not save cache:', error.message);
        }
    }

    /**
     * Update token_list.json and yield_sources_list.json with new test vault addresses
     */
    updateJsonFiles(addresses) {
        const tokenListPath = '../target/token_list.json';
        const yieldSourcesListPath = '../target/yield_sources_list.json';

        try {
            // Read existing JSON files
            let tokenList = {};
            let yieldSourcesList = {};

            if (fs.existsSync(tokenListPath)) {
                tokenList = JSON.parse(fs.readFileSync(tokenListPath, 'utf8'));
            }
            if (fs.existsSync(yieldSourcesListPath)) {
                yieldSourcesList = JSON.parse(fs.readFileSync(yieldSourcesListPath, 'utf8'));
            }

            // Ensure chain 1 exists in both files
            if (!tokenList['1']) tokenList['1'] = [];
            if (!yieldSourcesList['1']) yieldSourcesList['1'] = [];

            // Remove existing test vault entries from both lists
            const testVaultSymbols = [
                'test_1_DynamicAllocation_MockVault',
                'test_3_UnderlyingVaults_StressTest',
                'test_6_yieldAccumulation_vault1',
                'test_6_yieldAccumulation_vault2',
                'test_6_yieldAccumulation_vault3',
                'test_6_yieldAccumulation_WithRebalancing_vault1',
                'test_6_yieldAccumulation_WithRebalancing_vault2',
                'test_6_yieldAccumulation_WithRebalancing_vault3',
                'test_10_RuggableVault_Deposit',
                'test_10_RuggableVault_Withdraw',
                'test_10_RuggableVault_Withdraw_ConvertDistortion',
                'test_11_Allocate_NewYieldSource'
            ];

            // Remove existing test entries (including _Coverage variants)
            tokenList['1'] = tokenList['1'].filter(entry => {
                return !testVaultSymbols.some(symbol =>
                    entry.symbol === symbol || entry.symbol === symbol + '_Coverage'
                );
            });

            yieldSourcesList['1'] = yieldSourcesList['1'].filter(entry => {
                return !testVaultSymbols.some(symbol =>
                    entry.symbol === symbol || entry.symbol === symbol + '_Coverage'
                );
            });

            // Add new test vault entries from addresses object
            const testVaultMappings = {
                'test1_DynamicAllocation_MockVault': 'test_1_DynamicAllocation_MockVault',
                'test3_UnderlyingVaults_StressTest': 'test_3_UnderlyingVaults_StressTest',
                'test6_yieldAccumulation_vault1': 'test_6_yieldAccumulation_vault1',
                'test6_yieldAccumulation_vault2': 'test_6_yieldAccumulation_vault2',
                'test6_yieldAccumulation_vault3': 'test_6_yieldAccumulation_vault3',
                'test6_yieldAccumulation_WithRebalancing_vault1': 'test_6_yieldAccumulation_WithRebalancing_vault1',
                'test6_yieldAccumulation_WithRebalancing_vault2': 'test_6_yieldAccumulation_WithRebalancing_vault2',
                'test6_yieldAccumulation_WithRebalancing_vault3': 'test_6_yieldAccumulation_WithRebalancing_vault3',
                'test10_RuggableVault_Deposit': 'test_10_RuggableVault_Deposit',
                'test10_RuggableVault_Withdraw': 'test_10_RuggableVault_Withdraw',
                'test10_RuggableVault_Withdraw_ConvertDistortion': 'test_10_RuggableVault_Withdraw_ConvertDistortion',
                'test11_Allocate_NewYieldSource': 'test_11_Allocate_NewYieldSource'
            };

            // Add new entries to both token list and yield sources list
            for (const [vaultKey, jsonSymbol] of Object.entries(testVaultMappings)) {
                if (addresses.vaults[vaultKey]) {
                    const address = addresses.vaults[vaultKey];

                    // Add regular entry
                    const entry = {
                        symbol: jsonSymbol,
                        address: address
                    };
                    tokenList['1'].push(entry);
                    yieldSourcesList['1'].push(entry);

                    // Add coverage entry with same address (since same salt is used)
                    const coverageEntry = {
                        symbol: jsonSymbol + '_Coverage',
                        address: address
                    };
                    tokenList['1'].push(coverageEntry);
                    yieldSourcesList['1'].push(coverageEntry);
                }
            }

            // Write updated JSON files
            fs.writeFileSync(tokenListPath, JSON.stringify(tokenList, null, 2));
            fs.writeFileSync(yieldSourcesListPath, JSON.stringify(yieldSourcesList, null, 2));

            this.log('✅ Updated token_list.json and yield_sources_list.json with new test vault addresses');

        } catch (error) {
            this.log('⚠️  Warning: Could not update JSON files:', error.message);
        }
    }

    /**
     * Clean up all existing cache and output files before regeneration
     */
    cleanupCacheFiles() {
        const filesToCleanup = [
            '../output/lookup_cache_1.json',
            '../output/jsGeneratedRoot_1.json',
            '../output/jsTreeDump_1.json',
            '../output/globalMerkleTree_1.json'
        ];

        let cleanedCount = 0;
        for (const filePath of filesToCleanup) {
            try {
                if (fs.existsSync(filePath)) {
                    fs.unlinkSync(filePath);
                    cleanedCount++;
                    if (this.verbose) {
                        this.log(`🧹 Cleaned up: ${filePath}`);
                    }
                }
            } catch (error) {
                // Don't fail the entire process if cleanup fails
                this.log(`⚠️  Warning: Could not clean up ${filePath}: ${error.message}`);
            }
        }

        if (cleanedCount > 0) {
            this.log(`🧹 Cleaned up ${cleanedCount} cache files before regeneration`);
        }
    }

    /**
     * Generate merkle tree using new dynamic system
     */
    async generateMerkleTree(addresses, chainId = 1) {
        // Ensure clean state before generation
        this.cleanupCacheFiles();

        const hookAddresses = addresses.hooks;
        const vaultAddresses = Object.values(addresses.vaults);

        this.log(`Generating merkle tree with ${Object.keys(hookAddresses).length} hooks and ${vaultAddresses.length} vaults`);

        // Update address lists with detected vaults and SuperVaults
        const allDetectedAddresses = { ...addresses.vaults, ...addresses.superVaults };
        if (Object.keys(allDetectedAddresses).length > 0) {
            this.log('Updating address lists with detected vaults and SuperVaults...');
            const AddressListGenerator = require('./generate-address-lists.js');
            const generator = new AddressListGenerator();
            generator.addDetectedVaults(allDetectedAddresses);
        }

        // Generate merkle trees with detected hooks
        console.log('\n=== Generating Merkle Trees ===');
        const { generateMerkleTrees } = require('./build-hook-merkle-trees');
        const detectedHookNames = Object.keys(addresses.hooks);

        if (detectedHookNames.length === 0) {
            throw new Error('No hooks detected from console output');
        }

        console.log(`Generating merkle trees for hooks: ${detectedHookNames.join(', ')}`);

        try {
            const result = await generateMerkleTrees(addresses.hooks, chainId);
            console.log('Merkle tree generation completed successfully');
            return result;
        } catch (error) {
            console.error('Error generating merkle trees:', error);
            throw error;
        }
    }

    /**
     * Generate optimized lookup cache from merkle tree
     */
    async generateLookupCache() {
        this.log('Generating optimized lookup cache...');

        const EfficientProofLookup = require('./efficient-proof-lookup.js');
        const lookup = new EfficientProofLookup(1);

        try {
            // Force initialization to build the lookup map
            lookup.init();

            // Convert the Map to a plain object for JSON serialization
            const lookupData = {};
            for (const [key, value] of lookup.lookupMap) {
                lookupData[key] = value;
            }

            // Save the optimized lookup cache
            const outputDir = '../output';
            if (!fs.existsSync(outputDir)) {
                fs.mkdirSync(outputDir, { recursive: true });
            }

            const lookupCachePath = `${outputDir}/lookup_cache_1.json`;
            const cacheData = {
                timestamp: Date.now(),
                chainId: 1,
                entryCount: Object.keys(lookupData).length,
                lookupMap: lookupData
            };

            fs.writeFileSync(lookupCachePath, JSON.stringify(cacheData));

            this.log(`Lookup cache generated with ${cacheData.entryCount} entries`);
            this.log(`Cache saved to: ${lookupCachePath}`);

        } catch (error) {
            throw new Error(`Lookup cache generation failed: ${error.message}`);
        }
    }

    async run() {
        try {
            if (this.showHelp) {
                this.displayHelp();
                return true;
            }

            if (this.statusOnly) {
                console.log('🔍 Checking merkle cache status...');
            } else if (process.env.FOUNDRY_PROFILE === 'coverage') {
                console.log('🌲 Pre-generating merkle tree using BaseTest for coverage...');
            } else {
                console.log('🌲 Pre-generating merkle tree using BaseTest...');
            }

            // Get addresses from BaseTest
            const addresses = this.calculateAllAddresses();

            // Check if regeneration needed
            const needsRegen = this.needsRegeneration(addresses);

            if (this.statusOnly) {
                // Status-only mode - just report and exit
                if (needsRegen) {
                    console.log('❌ Cache is invalid or outdated - regeneration needed');
                    console.log('💡 Run with --force to regenerate cache');
                    return false;
                } else {
                    console.log('✅ Cache is valid and up to date');
                    return true;
                }
            }

            if (!this.force && !needsRegen) {
                console.log('✅ Merkle tree already generated for current addresses');
                return true;
            }

            // Provide clear messaging about why regeneration is happening
            if (this.force && needsRegen) {
                console.log('🔄 Force regeneration requested AND cache validation failed - regenerating...');
            } else if (this.force) {
                console.log('🔄 Force regeneration requested - regenerating...');
            } else if (needsRegen) {
                console.log('🔄 Cache validation failed (address differences detected) - automatically regenerating...');
            }

            // Update JSON files with new test vault addresses
            this.updateJsonFiles(addresses);

            // Generate merkle tree
            await this.generateMerkleTree(addresses);

            // Generate optimized lookup cache
            await this.generateLookupCache();

            // Save address cache
            this.saveAddressCache(addresses);

            console.log('✅ Deterministic merkle tree pre-generation completed');
            return true;

        } catch (error) {
            console.error('❌ Error:', error.message);
            if (this.verbose) {
                console.error(error.stack);
            }
            return false;
        }
    }
}

// Run if called directly
if (require.main === module) {
    const generator = new DeterministicMerkleGen();
    generator.run().then(success => {
        process.exit(success ? 0 : 1);
    });
}

module.exports = { DeterministicMerkleGen }; 