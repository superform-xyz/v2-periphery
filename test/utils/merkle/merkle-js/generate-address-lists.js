#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Generate individual address list JSON files from the master address registry
 */
class AddressListGenerator {
    constructor() {
        this.registryPath = path.join(__dirname, '../config/address_registry.json');
        this.targetDir = path.join(__dirname, '../target');
    }

    /**
     * Load the master address registry
     */
    loadRegistry() {
        try {
            const registryContent = fs.readFileSync(this.registryPath, 'utf8');
            return JSON.parse(registryContent);
        } catch (error) {
            throw new Error(`Failed to load address registry: ${error.message}`);
        }
    }

    /**
     * Generate token_list.json from registry tokens AND yieldSources
     * (yield sources must appear in both lists as per plan)
     */
    generateTokenList(registry) {
        const tokenList = {};

        for (const [chainId, tokens] of Object.entries(registry.tokens)) {
            tokenList[chainId] = tokens.map(token => ({
                symbol: token.symbol,
                address: token.address
            }));
        }

        // Add yield sources to token list as well (required by plan)
        for (const [chainId, yieldSources] of Object.entries(registry.yieldSources)) {
            if (!tokenList[chainId]) {
                tokenList[chainId] = [];
            }

            // Add yield sources to tokens, avoiding duplicates
            for (const yieldSource of yieldSources) {
                const exists = tokenList[chainId].some(token =>
                    token.symbol === yieldSource.symbol && token.address === yieldSource.address
                );

                if (!exists) {
                    tokenList[chainId].push({
                        symbol: yieldSource.symbol,
                        address: yieldSource.address
                    });
                }
            }
        }

        return tokenList;
    }

    /**
     * Generate yield_sources_list.json from registry yieldSources
     */
    generateYieldSourcesList(registry) {
        const yieldSourcesList = {};

        for (const [chainId, yieldSources] of Object.entries(registry.yieldSources)) {
            yieldSourcesList[chainId] = yieldSources.map(source => ({
                symbol: source.symbol,
                address: source.address
            }));
        }

        return yieldSourcesList;
    }

    /**
     * Generate owner_list.json from registry beneficiaries
     */
    generateOwnerList(registry) {
        return registry.beneficiaries;
    }

    /**
     * Generate staking_list.json from registry staking
     */
    generateStakingList(registry) {
        const stakingList = {};

        for (const [chainId, stakingAddresses] of Object.entries(registry.staking)) {
            stakingList[chainId] = stakingAddresses.map(staking => ({
                symbol: staking.symbol,
                address: staking.address
            }));
        }

        return stakingList;
    }

    /**
     * Generate passthrough_contracts_list.json from registry passthroughContracts
     */
    generatePassthroughContractsList(registry) {
        const passthroughContractsList = {};

        for (const [chainId, passthroughContracts] of Object.entries(registry.passthroughContracts || {})) {
            passthroughContractsList[chainId] = passthroughContracts.map(contract => ({
                symbol: contract.symbol,
                address: contract.address
            }));
        }

        return passthroughContractsList;
    }

    /**
     * Write JSON file with proper formatting
     */
    writeJsonFile(filename, data) {
        const filePath = path.join(this.targetDir, filename);
        const jsonContent = JSON.stringify(data, null, 2);
        fs.writeFileSync(filePath, jsonContent);
        console.log(`Generated: ${filename}`);
    }

    /**
     * Generate all address list files
     */
    generateAll() {
        console.log('Loading address registry...');
        const registry = this.loadRegistry();

        console.log('Generating address list files...');

        // Generate token list
        const tokenList = this.generateTokenList(registry);
        this.writeJsonFile('token_list.json', tokenList);

        // Generate yield sources list
        const yieldSourcesList = this.generateYieldSourcesList(registry);
        this.writeJsonFile('yield_sources_list.json', yieldSourcesList);

        // Generate owner list
        const ownerList = this.generateOwnerList(registry);
        this.writeJsonFile('owner_list.json', ownerList);

        // Generate staking list
        const stakingList = this.generateStakingList(registry);
        this.writeJsonFile('staking_list.json', stakingList);

        // Generate passthrough contracts list
        const passthroughContractsList = this.generatePassthroughContractsList(registry);
        this.writeJsonFile('passthrough_contracts_list.json', passthroughContractsList);

        console.log('Address list generation complete!');
    }

    /**
     * Add detected vault addresses to target JSON files only (not registry)
     */
    addDetectedVaults(detectedVaults) {
        // SuperVaults that should only appear in beneficiaries, not in yieldSources
        // These are the main SuperVault contracts, not yield source vaults
        const superVaults = ['globalSVStrategy', 'globalSVGearStrategy', 'globalRuggableVault'];

        // Load existing target JSON files
        const tokenListPath = path.join(this.targetDir, 'token_list.json');
        const yieldSourcesListPath = path.join(this.targetDir, 'yield_sources_list.json');

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

        // Helper function to normalize vault names and remove duplicates
        const normalizeVaultName = (name) => {
            // Strip VAULT_ prefix if present
            let cleanName = name.startsWith('VAULT_') ? name.substring(6) : name;

            // Normalize test naming: convert test1_, test3_, etc. to test_1_, test_3_, etc.
            cleanName = cleanName.replace(/^test(\d+)_/, 'test_$1_');

            return cleanName;
        };

        // Create a set to track what we've already added to avoid duplicates
        const addedVaults = new Set();

        // First, remove ALL existing test vault entries to ensure clean state
        const isTestVault = (symbol) =>
            symbol.startsWith('test_') ||
            symbol.startsWith('test') ||
            symbol.includes('_Coverage') ||
            symbol === 'MOCK_ETH_RECEIVER';

        tokenList['1'] = tokenList['1'].filter(entry => !isTestVault(entry.symbol));
        yieldSourcesList['1'] = yieldSourcesList['1'].filter(entry => !isTestVault(entry.symbol));

        // Add detected vaults to target files only (excluding SuperVaults)
        for (const [vaultName, address] of Object.entries(detectedVaults)) {
            // Skip SuperVaults - they should only be in beneficiaries
            if (superVaults.includes(vaultName)) {
                continue;
            }

            // Normalize the vault name
            const cleanVaultName = normalizeVaultName(vaultName);

            // Skip if we've already processed this vault (by normalized name and address)
            const vaultKey = `${cleanVaultName}:${address}`;
            if (addedVaults.has(vaultKey)) {
                continue;
            }
            addedVaults.add(vaultKey);

            // Create regular vault entry
            const vaultEntry = {
                symbol: cleanVaultName,
                address: address
            };

            // Create coverage variant entry
            const coverageEntry = {
                symbol: `${cleanVaultName}_Coverage`,
                address: address // Same address as regular vault
            };

            // Add both regular and coverage variants to target files only
            tokenList['1'].push(vaultEntry);
            tokenList['1'].push(coverageEntry);
            yieldSourcesList['1'].push(vaultEntry);
            yieldSourcesList['1'].push(coverageEntry);
        }

        // Write updated target JSON files (NOT the registry)
        fs.writeFileSync(tokenListPath, JSON.stringify(tokenList, null, 2));
        fs.writeFileSync(yieldSourcesListPath, JSON.stringify(yieldSourcesList, null, 2));

        console.log(`Updated target JSON files with ${addedVaults.size} unique detected vaults (including _Coverage variants)`);
        console.log('Note: address_registry.json was NOT modified - test vaults only added to target files');
        console.log('Note: Removed all existing test vault entries and normalized naming to prevent duplicates');
    }
}

// Export for use in other scripts
module.exports = AddressListGenerator;

// CLI usage
if (require.main === module) {
    const generator = new AddressListGenerator();

    // Check command line arguments
    const args = process.argv.slice(2);

    if (args.length === 0) {
        // Generate all lists
        generator.generateAll();
    } else if (args[0] === '--add-vaults' && args[1]) {
        // Add detected vaults from JSON string
        try {
            const detectedVaults = JSON.parse(args[1]);
            generator.addDetectedVaults(detectedVaults);
        } catch (error) {
            console.error('Failed to parse detected vaults JSON:', error.message);
            process.exit(1);
        }
    } else {
        console.log('Usage:');
        console.log('  node generate-address-lists.js                    # Generate all lists');
        console.log('  node generate-address-lists.js --add-vaults JSON  # Add detected vaults');
        process.exit(1);
    }
}
