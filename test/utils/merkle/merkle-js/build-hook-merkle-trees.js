const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");
const fs = require("fs");
const path = require("path");

// Load our JSON data files
const tokenList = require('../target/token_list.json');
const yieldSourcesList = require('../target/yield_sources_list.json');
const ownerList = require('../target/owner_list.json');
const stakingList = require('../target/staking_list.json');
const hookConfigs = require('../config/hook_configs.json');


let customAddresses = {};

// Hook addresses will be populated dynamically from console output
let hookAddresses = {};

// Hook addresses will be populated from detected hooks
// Command line arguments will be processed differently in the new system
if (process.argv.length > 2) {
  console.log("Command line arguments detected - will be processed by new dynamic system");
}

// Check if strategy addresses were provided as a command line argument (cmd[3])
// Skip if arguments are flags (start with --)
if (process.argv.length > 3 && !process.argv[3].startsWith('--')) {
  const strategyAddressArg = process.argv[3];
  const strategyAddresses = strategyAddressArg.split(',');

  console.log("\n[DEBUG] Updating owner_list.json with provided strategy addresses:");
  strategyAddresses.forEach(address => console.log("- " + address));

  // Check current content of owner_list.json
  const ownerListPath = path.join(__dirname, '../target/owner_list.json');
  let currentContent = "[]";
  try {
    currentContent = fs.readFileSync(ownerListPath, 'utf8');
    console.log("[DEBUG] Current owner_list.json content before update:", currentContent);
  } catch (err) {
    console.log("[DEBUG] Error reading current owner_list.json:", err.message);
  }

  // Update the owner_list.json file with the provided strategy addresses
  // This will completely replace the current owner list
  try {
    const newContent = JSON.stringify(strategyAddresses, null, 4);
    console.log("[DEBUG] Writing new content to owner_list.json:", newContent);
    fs.writeFileSync(ownerListPath, newContent);

    // Verify the file was properly written
    const verifyContent = fs.readFileSync(ownerListPath, 'utf8');
    console.log("[DEBUG] Verified owner_list.json content after update:", verifyContent);


  } catch (err) {
    console.error("[DEBUG] ERROR writing to owner_list.json:", err.message);
  }
}


/**
 * Build hook definitions dynamically from detected hooks and configurations
 * @param {Object} detectedHooks - Object with hook names as keys and addresses as values
 * @returns {Object} Hook definitions object
 */
function buildHookDefinitions(detectedHooks) {
  const hookDefinitions = {};
  
  for (const [hookName, address] of Object.entries(detectedHooks)) {
    // Get configuration for this hook
    const config = hookConfigs[hookName];
    if (!config) {
      console.warn(`No configuration found for hook: ${hookName}`);
      continue;
    }
    
    // Use the hook name directly (already in proper PascalCase from contract name)
    hookDefinitions[hookName] = {
      // Contract address of the deployed hook
      address: address,
      // Hook name (PascalCase contract name)
      hookName: hookName,
      // Map argument names to their semantic types for proper list lookups
      argsInfo: {
        extractedAddresses: config.args || []
      },
      // Store full configuration for advanced features
      config: config
    };
    
    console.log(`Built definition for ${hookName} -> ${address}`);
  }
  
  return hookDefinitions;
}

// Hook definitions will be built dynamically
let hookDefinitions = {};

/**
 * Get addresses for a specific semantic type and chainId with hook-specific filtering
 * @param {string} type - Semantic type ('token', 'yieldSource', 'beneficiary', 'staking')
 * @param {number} chainId - Chain ID to get addresses for
 * @param {string} hookName - Hook name for filtering (optional)
 * @returns {Array<string>} Array of addresses
 */
function getAddressesForType(type, chainId, hookName = null) {
  let addresses = [];
  
  switch (type) {
    case 'token':
      addresses = (tokenList[chainId] || []).map(item => item.address);
      break;
    case 'yieldSource':
      addresses = (yieldSourcesList[chainId] || []).map(item => item.address);
      break;
    case 'staking':
      addresses = (stakingList[chainId] || []).map(item => item.address);
      break;
    case 'beneficiary':
      // Handle both old flat array format and new chain-based format
      if (Array.isArray(ownerList)) {
        addresses = ownerList; // Legacy format
      } else {
        addresses = ownerList[chainId] || []; // New chain-based format
      }
      break;
    default:
      return [];
  }
  
  // Apply hook-specific filtering if hookName is provided
  if (hookName && hookConfigs[hookName]) {
    addresses = applyHookFiltering(addresses, type, hookName, chainId);
  }
  
  return addresses;
}

/**
 * Apply hook-specific filtering to addresses
 * @param {Array<string>} addresses - Original addresses
 * @param {string} type - Address type
 * @param {string} hookName - Hook name
 * @param {number} chainId - Chain ID
 * @returns {Array<string>} Filtered addresses
 */
function applyHookFiltering(addresses, type, hookName, chainId) {
  const config = hookConfigs[hookName];
  if (!config) return addresses;
  
  let allowedList = [];
  switch (type) {
    case 'token':
      allowedList = config.allowedTokens || ['all'];
      break;
    case 'yieldSource':
      allowedList = config.allowedYieldSources || ['all'];
      break;
    case 'beneficiary':
      allowedList = config.allowedBeneficiaries || ['all'];
      break;
    case 'staking':
      allowedList = config.allowedStaking || ['all'];
      break;
  }
  
  // If 'all' is specified, return all addresses
  if (allowedList.includes('all')) {
    return addresses;
  }
  
  // If 'none' is specified, return empty array
  if (allowedList.includes('none')) {
    return [];
  }
  
  // Filter addresses based on allowed symbols
  // For now, return all addresses (symbol-based filtering will be implemented in Step 4)
  console.log(`Hook ${hookName} filtering for ${type}: ${allowedList.join(', ')}`);
  return addresses;
}

/**
 * Generate all possible argument combinations for a hook using a dynamic approach
 * @param {Object} hookDef - Hook definition
 * @param {number} chainId - Chain ID to use for addresses
 * @returns {Array<Object>} Array of argument objects
 */
function generateArgCombinations(hookDef, chainId) {
  // Get the argument definitions from the hook
  const argDefs = hookDef.argsInfo.extractedAddresses;
  const hookName = hookDef.hookName;

  console.log(`Generating combinations for ${hookName} with ${argDefs.length} argument types`);

  // Create a map of argument names to their possible values
  const argValues = {};
  for (const argDef of argDefs) {
    // Pass hook name for filtering
    argValues[argDef.name] = getAddressesForType(argDef.type, chainId, hookName);
    console.log(`  ${argDef.name} (${argDef.type}): ${argValues[argDef.name].length} addresses`);
  }

  // Helper function to generate combinations recursively
  function generateCombinationsRecursive(argNames, currentIndex, currentCombination) {
    // Base case: we've processed all argument names
    if (currentIndex === argNames.length) {
      return [currentCombination];
    }

    // Get the current argument name
    const argName = argNames[currentIndex];

    // Get the possible values for this argument
    const possibleValues = argValues[argName] || [];

    // If there are no possible values, skip this argument
    if (possibleValues.length === 0) {
      return generateCombinationsRecursive(argNames, currentIndex + 1, currentCombination);
    }

    // Generate combinations for each possible value
    let combinations = [];
    for (const value of possibleValues) {
      // Create a new combination with this value
      const newCombination = { ...currentCombination, [argName]: value };

      // Recursively generate combinations for the remaining arguments
      const remainingCombinations = generateCombinationsRecursive(
        argNames,
        currentIndex + 1,
        newCombination
      );

      // Add these combinations to our result
      combinations = combinations.concat(remainingCombinations);
    }

    return combinations;
  }

  // Get all argument names from the argDefs
  const argNames = argDefs.map(def => def.name);

  // Generate combinations for all arguments
  return generateCombinationsRecursive(argNames, 0, {});
}

// Add ethers import at the top
const { ethers } = require('ethers');

/**
 * Encode args according to the hook's encoding scheme
 * @param {Object} args - Object containing argument addresses
 * @param {string} hookName - Name of the hook
 * @returns {string} Hex string of encoded args (packed, not ABI encoded)
 */
function encodeArgs(args, hookName) {
  // Get hook definition
  const hookDef = hookDefinitions[hookName];
  if (!hookDef) {
    console.warn(`No hook definition found for ${hookName}`);
    return '';
  }

  // Get argument definitions in the correct order
  const argDefs = hookDef.argsInfo.extractedAddresses;

  // Build the types and values arrays for solidityPack
  const types = [];
  const values = [];

  console.log(`\nEncoding args for ${hookName}:`);
  for (const argDef of argDefs) {
    const argName = argDef.name;
    if (args[argName] !== undefined) {
      console.log(`  - ${argName}: ${args[argName]} (type: ${argDef.type})`);
      types.push('address'); // All our args are addresses
      values.push(args[argName]);
    }
  }

  // If we have no arguments, return empty string
  if (types.length === 0) {
    console.log('  No arguments to encode');
    return '';
  }

  // First encode as solidityPacked (abi.encodePacked equivalent)
  const packedData = ethers.utils.solidityPack(types, values);
  console.log(`  Packed data: ${packedData}`);

  // Otherwise, return the packed data directly
  return packedData;
}

/**
 * Build Merkle tree for a specific hook
 * @param {string} hookName - Name of the hook
 * @param {number} chainId - Chain ID to use for addresses
 * @returns {Object} StandardMerkleTree and leaf data
 */
function buildMerkleTreeForHook(hookName, chainId) {
  const hookDef = hookDefinitions[hookName];
  if (!hookDef) throw new Error(`Unknown hook: ${hookName}`);

  const argCombinations = generateArgCombinations(hookDef, chainId);

  // Build leaves in the format expected by StandardMerkleTree.of()
  const leaves = [];
  const leafData = [];

  for (const args of argCombinations) {
    // Encode args according to the hook's specific encoding
    const encodedArgs = encodeArgs(args, hookName);
    const hookAddress = hookDef.address;

    // Store leaf data for later reference
    leafData.push({
      hookName,
      hookAddress,
      args,
      encodedArgs
    });

    // Each leaf is [hookAddress, encodedArgs] - StandardMerkleTree will handle hashing
    leaves.push([hookAddress, encodedArgs]);
  }

  // Create the merkle tree with StandardMerkleTree - it will do standardLeafHash internally
  const tree = StandardMerkleTree.of(
    leaves,
    ["address", "bytes"] // Hook address and encoded args
  );

  return { tree, leafData };
}

/**
 * Generate Merkle trees for hooks
 * @param {Object} detectedHooks - Object with detected hook addresses
 * @param {number} chainId - Chain ID to use for addresses
 */
function generateMerkleTrees(detectedHooks, chainId) {
  console.log(`Generating global Merkle tree for chain ID ${chainId}...`);

  // Build hook definitions from detected hooks
  hookDefinitions = buildHookDefinitions(detectedHooks);
  const hookNames = Object.keys(hookDefinitions);
  
  console.log(`Processing ${hookNames.length} detected hooks:`);
  for (const [hookName, address] of Object.entries(detectedHooks)) {
    console.log(`- ${hookName}: ${address}`);
  }

  // Generate leaves for each hook but only for the global tree
  let allLeaves = [];
  let allLeafData = [];

  for (const hookName of hookNames) {
    const { tree, leafData } = buildMerkleTreeForHook(hookName, chainId);
    console.log(`Generated ${leafData.length} leaves for ${hookName}`);

    // Debug: log first few leaf data items for each hook
    if (leafData.length > 0) {
      console.log(`Sample leaf for ${hookName}:`);
      console.log(`  - Hook Address: ${hookDefinitions[hookName].address}`);
      console.log(`  - Encoded Args: ${leafData[0].encodedArgs}`);
      console.log(`  - Raw Args:`, leafData[0].args);
    }

    // Add to global leaves
    for (let i = 0; i < leafData.length; i++) {
      // Each leaf is [hookAddress, encodedArgs]
      allLeaves.push([leafData[i].hookAddress, leafData[i].encodedArgs]);
      allLeafData.push(leafData[i]);
    }
  }

  // Generate global Merkle tree with all leaves
  if (allLeaves.length > 0) {
    const globalTree = StandardMerkleTree.of(
      allLeaves,
      ["address", "bytes"] // Hook address and encoded args
    );

    const globalTreeDump = globalTree.dump();

    // Add count element to the tree dump for easier access in Solidity
    globalTreeDump.count = allLeaves.length;

    // Enhance global tree dump with proofs for each leaf
    for (const [i, v] of globalTree.entries()) {
      const currentHookName = allLeafData[i].hookName;

      // Verify the hook definition exists
      if (!hookDefinitions[currentHookName]) {
        throw new Error(`Hook definition not found for ${currentHookName}. Please add it to the hookDefinitions object.`);
      }

      // Verify the hook address exists
      const hookAddress = hookDefinitions[currentHookName].address;
      if (!hookAddress) {
        throw new Error(`Hook address not found for ${currentHookName}. Please add it to the hookAddresses object.`);
      }

      // Only include essential information: value, treeIndex, hookName, address, and proof
      globalTreeDump.values[i] = {
        value: globalTreeDump.values[i].value, // This is [hookAddress, encodedArgs] 
        treeIndex: globalTreeDump.values[i].treeIndex,
        hookName: currentHookName,
        hookAddress: hookAddress, // Add hook contract address for validation
        encodedHookArgs: allLeafData[i].encodedArgs, // Add this for easy reference
        proof: globalTree.getProof(i)
      };
    }

    // Create output directory if it doesn't exist
    const outputDir = path.join(__dirname, '../output');
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    // Save root and tree dump separately (like in generateMerkleTree.js)
    const root = globalTree.root;

    fs.writeFileSync(
      path.join(outputDir, `jsGeneratedRoot_${chainId}.json`),
      JSON.stringify({ "root": root })
    );

    fs.writeFileSync(
      path.join(outputDir, `jsTreeDump_${chainId}.json`),
      JSON.stringify(globalTreeDump)
    );

    console.log(`Saved global Merkle tree with root: ${root}`);
    console.log(`Total leaves in global tree: ${allLeaves.length}`);
  }
}

/**
 * Main execution function that processes command line arguments or uses detected hooks
 * @param {Object} detectedHooks - Detected hooks from console output (optional)
 */
function main(detectedHooks = null) {
  const chainId = 1; // Ethereum mainnet as specified in the requirements
  
  if (detectedHooks) {
    // Use provided detected hooks (called from deterministic-merkle-pregeneration.js)
    console.log('Using detected hooks from console output');
    generateMerkleTrees(detectedHooks, chainId);
  } else {
    // Legacy command line argument processing
    console.log('No detected hooks provided - using legacy command line processing');
    console.log('This mode will be deprecated in favor of automatic hook detection');
    
    // For now, create empty hook definitions to prevent errors
    hookDefinitions = {};
    generateMerkleTrees({}, chainId);
  }
}

// Export functions for use by other modules
module.exports = {
  buildMerkleTreeForHook,
  generateMerkleTrees,
  buildHookDefinitions,
  main
};

// Only run main if this file is executed directly
if (require.main === module) {
  main();
}
