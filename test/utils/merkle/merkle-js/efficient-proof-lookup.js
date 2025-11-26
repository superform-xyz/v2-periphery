#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

/**
 * Efficient Merkle Proof Lookup Script
 *
 * This script pre-builds lookup indices for fast proof retrieval,
 * avoiding the need to load and search the entire merkle tree in Solidity.
 */
class EfficientProofLookup {
  constructor(chainId = 1) {
    this.chainId = chainId;
    this.lookupMap = new Map();
    this.initialized = false;
  }

  /**
   * Initialize the lookup system by loading cached indices or building from scratch
   */
  init() {
    if (this.initialized) return;

    const outputDir = path.join(__dirname, "../output");
    const lookupCachePath = path.join(outputDir, `lookup_cache_${this.chainId}.json`);

    if (fs.existsSync(lookupCachePath)) {
      try {
        if (process.env.NODE_ENV !== "test" && !process.env.SOLIDITY_CALL) {
          console.log("Loading lookup cache...");
        }
        const cacheData = JSON.parse(fs.readFileSync(lookupCachePath, "utf8"));

        this.lookupMap = new Map();
        for (const [key, value] of Object.entries(cacheData.lookupMap || {})) {
          this.lookupMap.set(key, value);
        }

        if (process.env.NODE_ENV !== "test" && !process.env.SOLIDITY_CALL) {
          console.log(`Loaded ${this.lookupMap.size} entries from cache`);
        }
        this.initialized = true;
        return;
      } catch (error) {
        if (process.env.NODE_ENV !== "test") {
          console.log("Cache load failed, building from tree dump:", error.message);
        }
      }
    }

    this.buildFromTreeDump();
  }

  /**
   * Build lookup indices from tree dump (fallback method)
   */
  buildFromTreeDump() {
    const outputDir = path.join(__dirname, "../output");
    const treeDumpPath = path.join(outputDir, `jsTreeDump_${this.chainId}.json`);

    if (!fs.existsSync(treeDumpPath)) {
      throw new Error(`Tree dump file not found: ${treeDumpPath}. Run deterministic merkle generation first.`);
    }

    if (process.env.NODE_ENV !== "test") {
      console.log("Loading merkle tree data...");
    }
    const treeDump = JSON.parse(fs.readFileSync(treeDumpPath, "utf8"));

    if (process.env.NODE_ENV !== "test") {
      console.log(`Building lookup indices for ${treeDump.count} entries...`);
    }

    for (const entry of treeDump.values) {
      const hookAddress = entry.hookAddress.toLowerCase();
      const encodedArgs = String(entry.encodedHookArgs); // force string

      const lookupKey = `${hookAddress}:${encodedArgs}`;

      this.lookupMap.set(lookupKey, {
        proof: entry.proof,
        hookName: entry.hookName,
        hookAddress: entry.hookAddress,
        encodedArgs,
      });
    }

    if (process.env.NODE_ENV !== "test") {
      console.log(`Lookup indices built. ${this.lookupMap.size} entries indexed.`);
    }
    this.initialized = true;
  }

  getProofsForHooks(hookAddresses, encodedHookArgs) {
    this.init();

    if (hookAddresses.length !== encodedHookArgs.length) {
      throw new Error("Hook addresses and encoded args arrays must have the same length");
    }
    if (hookAddresses.length === 0) {
      throw new Error("Empty input arrays");
    }

    const results = [];
    for (let i = 0; i < hookAddresses.length; i++) {
      const hookAddress = hookAddresses[i].toLowerCase();
      const encodedArgs = String(encodedHookArgs[i]); // ensure string
      const lookupKey = `${hookAddress}:${encodedArgs}`;
      const entry = this.lookupMap.get(lookupKey);

      if (!entry) {
        console.error(`No proof found for hook: ${hookAddresses[i]}, args: ${encodedArgs}`);
        throw new Error(`No proof found for hook address: ${hookAddresses[i]}`);
      }
      results.push(entry.proof);
    }
    return results;
  }

  getSingleProof(hookAddress, encodedArgs) {
    const proofs = this.getProofsForHooks([hookAddress], [encodedArgs]);
    return proofs[0];
  }

  listAvailableHooks() {
    this.init();

    const hooks = new Map();
    for (const [, value] of this.lookupMap) {
      const hookAddress = value.hookAddress;
      if (!hooks.has(hookAddress)) {
        hooks.set(hookAddress, { name: value.hookName, address: hookAddress, argsCount: 0 });
      }
      hooks.get(hookAddress).argsCount++;
    }

    if (process.env.NODE_ENV !== "test") {
      console.log("\nAvailable hooks:");
      for (const [address, info] of hooks) {
        console.log(`  ${info.name}: ${address} (${info.argsCount} combinations)`);
      }
    }

    return Array.from(hooks.values());
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log("Usage:");
    console.log("  node efficient-proof-lookup.js list                    # List available hooks");
    console.log("  node efficient-proof-lookup.js get <addr> <args>       # Get single proof");
    console.log("  node efficient-proof-lookup.js batch <addrs> <args>    # Get multiple proofs");
    process.exit(1);
  }

  const lookup = new EfficientProofLookup(1);

  try {
    if (args[0] === "list") {
      lookup.listAvailableHooks();
    } else if (args[0] === "get" && args.length === 3) {
      const [, hookAddress, encodedArgs] = args;
      const proof = lookup.getSingleProof(hookAddress, encodedArgs);
      console.log(JSON.stringify(proof));
    } else if (args[0] === "batch" && args.length >= 3) {
      process.env.SOLIDITY_CALL = "true";
      const addresses = args[1].split(",").map(a => a.trim());
      const argsList = args[2].split(",").map(a => a.trim());
      const proofs = lookup.getProofsForHooks(addresses, argsList);
      console.log(JSON.stringify(proofs));
    } else {
      console.error("Invalid arguments");
      process.exit(1);
    }
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
}

module.exports = EfficientProofLookup;
