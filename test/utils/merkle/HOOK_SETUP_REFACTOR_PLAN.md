# Hook Setup Refactor Plan

## Implementation Plan

### Step 1: Core Infrastructure ✅ COMPLETED
1. **Remove hardcoded hook addresses** from `build-hook-merkle-trees.js` ✅
2. **Enhance console parsing** for automatic Hook suffix detection using contract names ✅
3. **Create `hook_configs.json`** with existing hook configurations ✅
4. **Standardize `owner_list.json`** to chain-based structure ✅

### Step 2: Dynamic Hook System ✅ COMPLETED
1. **Implement dynamic `hookDefinitions` building** from detected hooks ✅
2. **Update argument combination generation** to use hook configs ✅
3. **Remove command line argument order dependencies** ✅
4. **Remove SCREAMING_SNAKE_CASE conversion and use proper contract names** ✅
5. **Update detection mechanism to use Hook suffix instead of HOOK_ prefix** ✅

### Step 3: Address List Enhancement ✅ COMPLETED
1. **Create `address_registry.json`** as master source ✅
2. **Implement automatic JSON generation** from registry ✅
3. **Add vault address detection** from console logs ✅
4. **Remove duplicate test vault entries** from static files ✅
5. **Reorganize configuration files** into `/config/` folder ✅
6. **Fix SuperVault classification** (exclude from yield sources) ✅

### Step 4: Integration & Testing ✅ COMPLETED
1. **Update Makefile commands** to work with new system ✅
2. **Ensure `make ensure-merkle-cache`** works with dynamic detection ✅
3. **Verify `make ftest`** passes all tests ✅

---

## Python Implementation Plan

The JavaScript system will be fully translated to Python for production use. The Python implementation will handle all configuration centrally without relying on Foundry console logs.

### Core Architecture
- **Central Configuration**: All addresses managed in `address_registry.json`
- **Hook Definitions**: All hook configurations in `hook_configs.json`
- **No Foundry Dependencies**: Pure Python implementation
- **Advanced Filtering**: Complex rules and patterns (moved from Steps 4-5 above)

### Implementation Steps

#### 1. Address Management (equivalent to `generate-address-lists.js`)
```python
class AddressManager:
    def __init__(self, config_dir="../config"):
        self.registry_path = Path(config_dir) / "address_registry.json"
        self.super_vaults = {'globalSVStrategy', 'globalSVGearStrategy', 'globalRuggableVault'}
    
    def generate_yield_source_list(self, chain_id=1):
        """Generate yield source list, excluding SuperVaults"""
        registry = self.load_registry()
        yield_sources = registry["yieldSources"][str(chain_id)]
        return [source for source in yield_sources 
                if source["symbol"] not in self.super_vaults]
    
    def add_detected_vaults(self, detected_vaults, chain_id=1):
        """Add dynamically detected vaults, skip SuperVaults for yield sources"""
        registry = self.load_registry()
        for vault_name, address in detected_vaults.items():
            if vault_name in self.super_vaults:
                continue  # Skip SuperVaults
            # Add to yieldSources with test_vault category
```

#### 2. Hook Configuration Management (equivalent to `build-hook-merkle-trees.js`)
```python
class HookConfigManager:
    def build_hook_definitions(self, detected_hooks):
        """Build hook definitions from detected hooks and configs"""
        hook_definitions = {}
        for hook_name, address in detected_hooks.items():
            config = self.hook_configs.get(hook_name)
            if config:
                hook_definitions[hook_name] = {
                    'address': address,
                    'arguments': config['args'],
                    'config': config
                }
        return hook_definitions
    
    def generate_argument_combinations(self, hook_def):
        """Generate all possible argument combinations using itertools.product"""
        arg_sources = []
        for arg in hook_def['arguments']:
            addresses = self.get_addresses_for_source(arg['source'])
            arg_sources.append(addresses)
        
        from itertools import product
        return list(product(*arg_sources))
```

#### 3. Merkle Tree Generation (equivalent to `build-hook-merkle-trees.js`)
```python
from merklelib import MerkleTree
from eth_abi import encode

class MerkleTreeGenerator:
    def encode_hook_arguments(self, hook_def, args_combo):
        """Encode hook arguments using ABI encoding"""
        types = [arg['type'] for arg in hook_def['arguments']]
        return encode(types, args_combo)
    
    def build_hook_merkle_tree(self, hook_def, combinations):
        """Build merkle tree for a single hook"""
        leaves = []
        for combo in combinations:
            encoded_args = self.encode_hook_arguments(hook_def, combo)
            leaf_data = {
                'hookAddress': hook_def['address'],
                'encodedHookArgs': encoded_args.hex(),
                'hookName': hook_def['name']
            }
            leaves.append(json.dumps(leaf_data, sort_keys=True))
        
        tree = MerkleTree(leaves)
        return {
            'tree': tree,
            'leaves': leaves,
            'root': tree.merkle_root.hex()
        }
```

#### 4. Efficient Proof Lookup (equivalent to `efficient-proof-lookup.js`)
```python
class ProofLookupCache:
    def __init__(self, chain_id=1):
        self.lookup_map = {}
        self.chain_id = chain_id
    
    def build_lookup_cache(self, tree_dump):
        """Build O(1) lookup cache from tree dump"""
        for entry in tree_dump['values']:
            lookup_key = f"{entry['hookAddress'].lower()}:{entry['encodedHookArgs']}"
            self.lookup_map[lookup_key] = {
                'proof': entry['proof'],
                'hookName': entry['hookName'],
                'hookAddress': entry['hookAddress']
            }
    
    def get_proofs_for_hooks(self, hook_addresses, encoded_args):
        """Get proofs for multiple hooks efficiently"""
        results = []
        for addr, args in zip(hook_addresses, encoded_args):
            lookup_key = f"{addr.lower()}:{args}"
            entry = self.lookup_map.get(lookup_key)
            if not entry:
                raise ValueError(f"No proof found for {addr}:{args}")
            results.append(entry['proof'])
        return results
```

#### 5. Advanced Filtering System (new functionality)
```python
class AdvancedFilter:
    def apply_token_filtering(self, combinations, allowed_tokens):
        """Filter combinations based on allowed tokens"""
        if not allowed_tokens:
            return combinations
        
        filtered = []
        for combo in combinations:
            if any(token in allowed_tokens for token in combo.values()):
                filtered.append(combo)
        return filtered
    
    def apply_category_filtering(self, combinations, allowed_categories):
        """Filter based on address categories from registry"""
        # Implementation for category-based filtering
        pass
    
    def apply_environment_rules(self, combinations, environment):
        """Apply environment-specific filtering rules"""
        if environment == "production":
            # Stricter filtering for production
            pass
        elif environment == "testing":
            # More permissive for testing
            pass
```

#### 6. Central Orchestrator (equivalent to `deterministic-merkle-pregeneration.js`)
```python
class PythonMerkleGenerator:
    def __init__(self, config_dir="../config"):
        self.address_manager = AddressManager(config_dir)
        self.hook_manager = HookConfigManager(config_dir)
        self.tree_generator = MerkleTreeGenerator()
        self.proof_cache = ProofLookupCache()
    
    def generate_merkle_trees(self, detected_hooks, chain_id=1):
        """Main orchestration method"""
        # 1. Update address lists with detected vaults
        self.address_manager.add_detected_vaults(detected_hooks.get('vaults', {}))
        
        # 2. Build hook definitions
        hook_definitions = self.hook_manager.build_hook_definitions(detected_hooks.get('hooks', {}))
        
        # 3. Generate merkle trees for each hook
        all_trees = {}
        global_leaves = []
        
        for hook_name, hook_def in hook_definitions.items():
            combinations = self.hook_manager.generate_argument_combinations(hook_def)
            tree_data = self.tree_generator.build_hook_merkle_tree(hook_def, combinations)
            all_trees[hook_name] = tree_data
            global_leaves.extend(tree_data['leaves'])
        
        # 4. Build global merkle tree
        global_tree = MerkleTree(global_leaves)
        
        # 5. Generate lookup cache
        self.proof_cache.build_lookup_cache({'values': global_leaves})
        
        return {
            'hook_trees': all_trees,
            'global_tree': global_tree,
            'lookup_cache': self.proof_cache.lookup_map
        }
```
