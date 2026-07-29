"""
SuperBank Merkle Tree Builder

Builds per-hook merkle trees for SuperBank. Unlike SuperVault which uses one global
tree for all hooks, SuperBank has one tree PER HOOK, each with its own root set via
SuperGovernor.proposeSuperBankHookMerkleRoot(hook, root).

Leaf format (matches Solidity exactly):
    leaf = keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))))
Where hookArgs = abi.encodePacked(arg1, arg2, ...) from ISuperHookInspector.inspect()
"""

import itertools
import json
import os
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from eth_utils import to_checksum_address

from config_loader import (
    AddressEntry,
    HookArgInfo,
    HookConfig,
    MerkleConfigLoader,
)
from tree_builder import (
    ZERO_ADDRESS,
    FilterEngine,
    MerkleLeaf,
    MerkleTreeBuilder,
    MerkleTreeData,
)

SUPERBANK_CONFIG_FILENAME = 'superbank_hook_config.json'


@dataclass
class HookTreeData:
    """Merkle tree data for a single SuperBank hook."""

    hook_names: List[str]
    hook_address: str
    root: bytes
    leaves: List[MerkleLeaf]
    proofs: Dict[int, List[bytes]]
    total_leaves: int


class SuperBankTreeBuilder:
    """
    Builds per-hook merkle trees for SuperBank.

    Each hook gets its own merkle tree containing all valid argument combinations.
    Hooks sharing the same contract address (e.g., PendleUnifiedHook variants)
    have their argument combinations merged into one tree.
    """

    def __init__(
        self,
        config_loader: Optional[MerkleConfigLoader] = None,
        superbank_config_path: Optional[str] = None,
    ):
        self.config_loader = config_loader or MerkleConfigLoader()
        self._tree_builder = MerkleTreeBuilder(self.config_loader)
        self._filter_engine = FilterEngine()

        if superbank_config_path:
            self._config_path = superbank_config_path
        else:
            self._config_path = os.path.join(
                os.path.dirname(__file__), 'config', SUPERBANK_CONFIG_FILENAME
            )

        self._superbank_config = self._load_superbank_config()

    def _load_superbank_config(self) -> Dict[str, Any]:
        """Load the SuperBank hook configuration."""
        with open(self._config_path, 'r') as f:
            return json.load(f)

    @property
    def superbank_address(self) -> str:
        return to_checksum_address(self._superbank_config['superbank_address'])

    def _get_hook_address(self, hook_name: str, chain_id: str, environment: str) -> Optional[str]:
        """Get the deployed hook address from contracts/deployments.json."""
        hook_config = self._superbank_config['hooks'].get(hook_name, {})
        contract_name = hook_config.get('contract_name', hook_name)

        from deployments_resolver import get_contract_address

        address = get_contract_address(contract_name, chain_id, environment)
        if address:
            return to_checksum_address(address)
        return None

    def _get_raw_type_map(self, hook_name: str) -> Dict[str, str]:
        """Get original arg type mapping from raw config (before HookArgInfo conversion)."""
        raw_args = self._superbank_config['hooks'][hook_name]['args']
        return {a['name']: a['type'] for a in raw_args}

    def _get_additional_addresses(self, hook_name: str) -> Dict[str, List[str]]:
        """Get additionalAddresses for each arg from raw config.

        Used for cross-chain tokens (e.g., Across outputToken includes destination chain tokens).
        """
        raw_args = self._superbank_config['hooks'][hook_name]['args']
        result = {}
        for a in raw_args:
            extra = a.get('additionalAddresses', [])
            if extra:
                result[a['name']] = [to_checksum_address(addr) for addr in extra]
        return result

    def _build_hook_config(self, hook_name: str) -> HookConfig:
        """Build a HookConfig from the SuperBank config for a given hook.

        Maps custom SuperBank types (superbank, zero_address) to valid HookArgInfo types.
        Use _get_raw_type_map() to access original types for type resolution logic.
        """
        raw_config = self._superbank_config['hooks'][hook_name]
        args = []
        for arg in raw_config['args']:
            arg_copy = dict(arg)
            # Map custom types to valid HookArgInfo types for validation.
            # Actual type resolution uses _get_raw_type_map() in _generate_combinations.
            if arg_copy['type'] in ('superbank', 'zero_address'):
                arg_copy['type'] = 'beneficiary'
            # Strip fields not supported by HookArgInfo
            arg_copy.pop('additionalAddresses', None)
            args.append(arg_copy)
        return HookConfig(name=hook_name, args=[HookArgInfo(**a) for a in args])

    def _generate_combinations(
        self, hook_name: str, hook_config: HookConfig, chain_id: str
    ) -> List[Dict[str, str]]:
        """Generate all valid argument combinations for a hook."""
        self.config_loader.load_address_registry()

        # Use raw types from config (custom types mapped away in HookArgInfo)
        raw_type_map = self._get_raw_type_map(hook_name)
        additional_addresses = self._get_additional_addresses(hook_name)

        arg_values = {}
        for arg_info in hook_config.args:
            addresses = []
            arg_type = raw_type_map.get(arg_info.name, arg_info.type)

            if arg_type == 'token':
                token_entries = self.config_loader.get_address_entries(chain_id, 'tokens')
                filtered = self._filter_engine.filter_addresses(token_entries, arg_info.filter)
                addresses = [e.address for e in filtered]

            elif arg_type == 'yieldSource':
                ys_entries = self.config_loader.get_address_entries(chain_id, 'yieldSources')
                filtered = self._filter_engine.filter_addresses(ys_entries, arg_info.filter)
                addresses = [e.address for e in filtered]

            elif arg_type == 'contract':
                all_contracts = self.config_loader.get_contracts(chain_id, arg_info.subtype)
                filtered = self._filter_engine.filter_contracts(all_contracts, arg_info.filter)
                addresses = [c.address for c in filtered]
                # Only fall back to zero address for optional contract args
                # (e.g., extRouter, pendleSwap). For required args like executor,
                # no contract found means the hook has no valid combinations.
                OPTIONAL_CONTRACT_ARGS = {'extRouter', 'pendleSwap', 'limitRouter'}
                if not addresses and arg_info.name in OPTIONAL_CONTRACT_ARGS:
                    addresses = [ZERO_ADDRESS]

            elif arg_type == 'feeRecipient':
                fr_entries = self.config_loader.get_address_entries(chain_id, 'feeRecipients')
                filtered = self._filter_engine.filter_addresses(fr_entries, arg_info.filter)
                addresses = [e.address for e in filtered]

            elif arg_type == 'superbank':
                addresses = [self.superbank_address]

            elif arg_type == 'zero_address':
                addresses = [ZERO_ADDRESS]

            elif arg_type == 'beneficiary':
                # For SuperBank, beneficiary = SuperBank address
                addresses = [self.superbank_address]

            # Append cross-chain or explicit addresses (e.g., Across outputToken on dest chain)
            extra = additional_addresses.get(arg_info.name, [])
            for addr in extra:
                if addr not in addresses:
                    addresses.append(addr)

            if addresses:
                arg_values[arg_info.name] = addresses

        if not arg_values:
            return []

        arg_names = list(arg_values.keys())
        value_lists = [arg_values[name] for name in arg_names]

        combinations = []
        for combo in itertools.product(*value_lists):
            combinations.append(dict(zip(arg_names, combo)))

        return combinations

    def build_all_hook_trees(
        self,
        chain_id: str,
        environment: str = 'prod',
        hook_filter: Optional[List[str]] = None,
    ) -> Dict[str, HookTreeData]:
        """
        Build merkle trees for all configured SuperBank hooks on a chain.

        Hooks sharing the same contract address have their leaves merged into one tree.

        Args:
            chain_id: Chain ID (e.g., '1' for ETH, '8453' for Base)
            environment: Deployment environment ('prod', 'staging', 'demo')
            hook_filter: If provided, only generate trees for these hook names

        Returns:
            Dict mapping hook_address -> HookTreeData
        """
        # Group hooks by their deployed contract address
        address_to_hooks: Dict[str, List[str]] = {}
        for hook_name in self._superbank_config['hooks']:
            if hook_filter and hook_name not in hook_filter:
                continue
            address = self._get_hook_address(hook_name, chain_id, environment)
            if not address:
                print(f'  [SKIP] {hook_name}: no deployment found on chain {chain_id} ({environment})')
                continue
            address_to_hooks.setdefault(address, []).append(hook_name)

        results = {}
        for hook_address, hook_names in address_to_hooks.items():
            tree_data = self._build_merged_hook_tree(
                hook_names, hook_address, chain_id
            )
            if tree_data:
                results[hook_address] = tree_data

        return results

    def _build_merged_hook_tree(
        self, hook_names: List[str], hook_address: str, chain_id: str
    ) -> Optional[HookTreeData]:
        """Build a single merkle tree from possibly multiple logical hooks sharing an address."""
        all_leaves = []
        seen_leaf_hashes = set()

        for hook_name in hook_names:
            hook_config = self._build_hook_config(hook_name)
            raw_type_map = self._get_raw_type_map(hook_name)
            combinations = self._generate_combinations(hook_name, hook_config, chain_id)

            if not combinations:
                print(f'  [WARN] {hook_name}: no valid argument combinations')
                continue

            for args in combinations:
                # Skip combinations with zero address in non-allowed positions.
                # Only zero_address type and optional contract args may be zero.
                OPTIONAL_CONTRACT_ARGS = {'extRouter', 'pendleSwap', 'limitRouter'}
                skip = False
                for arg_info in hook_config.args:
                    raw_type = raw_type_map.get(arg_info.name, arg_info.type)
                    zero_allowed = (
                        raw_type == 'zero_address'
                        or (raw_type == 'contract' and arg_info.name in OPTIONAL_CONTRACT_ARGS)
                    )
                    if not zero_allowed and \
                       arg_info.name in args and \
                       args[arg_info.name].lower() == ZERO_ADDRESS.lower():
                        skip = True
                        break
                if skip:
                    continue

                leaf = self._tree_builder.create_merkle_leaf(
                    hook_name, hook_address, args, hook_config
                )
                # Deduplicate by leaf hash
                if leaf.leaf_hash not in seen_leaf_hashes:
                    all_leaves.append(leaf)
                    seen_leaf_hashes.add(leaf.leaf_hash)

        if not all_leaves:
            return None

        # Sort leaves by hash for deterministic ordering
        all_leaves.sort(key=lambda leaf: leaf.leaf_hash)

        # Calculate merkle root
        leaf_hashes = [leaf.leaf_hash for leaf in all_leaves]
        root = self._tree_builder._calculate_merkle_root(leaf_hashes)

        # Build tree data for proof generation
        tree_data = MerkleTreeData(
            root=root,
            leaves=all_leaves,
            tree_height=self._tree_builder._calculate_tree_height(len(all_leaves)),
            total_leaves=len(all_leaves),
        )

        # Generate proofs for all leaves
        proofs = {}
        for i in range(len(all_leaves)):
            proof = self._tree_builder.generate_merkle_proof(tree_data, i)
            if proof is not None:
                proofs[i] = proof

        display_name = ' + '.join(hook_names)
        print(
            f'  [{display_name}] @ {hook_address}: '
            f'{len(all_leaves)} leaves, root=0x{root.hex()[:16]}...'
        )

        return HookTreeData(
            hook_names=hook_names,
            hook_address=hook_address,
            root=root,
            leaves=all_leaves,
            proofs=proofs,
            total_leaves=len(all_leaves),
        )

    def save_trees_to_json(
        self,
        trees: Dict[str, HookTreeData],
        chain_id: str,
        environment: str,
        output_dir: Optional[str] = None,
    ) -> str:
        """
        Save generated merkle trees to JSON files.

        Args:
            trees: Dict of hook_address -> HookTreeData
            chain_id: Chain ID
            environment: Environment name
            output_dir: Output directory (default: generated/{env}/{chain_id}/)

        Returns:
            Path to the output directory
        """
        if not output_dir:
            output_dir = os.path.join(
                os.path.dirname(__file__), 'generated', environment, chain_id
            )

        os.makedirs(output_dir, exist_ok=True)

        # Save summary
        summary = {
            'chain_id': chain_id,
            'environment': environment,
            'generated_at': datetime.now(timezone.utc).isoformat(),
            'superbank_address': self.superbank_address,
            'hooks': {},
        }

        for hook_address, tree_data in trees.items():
            summary['hooks'][hook_address] = {
                'names': tree_data.hook_names,
                'root': '0x' + tree_data.root.hex(),
                'total_leaves': tree_data.total_leaves,
            }

            # Save per-hook tree
            hook_file = {
                'hook_address': hook_address,
                'hook_names': tree_data.hook_names,
                'root': '0x' + tree_data.root.hex(),
                'total_leaves': tree_data.total_leaves,
                'leaves': [
                    {
                        'index': i,
                        'hook_name': leaf.hook_name,
                        'hook_address': leaf.hook_address,
                        'args': leaf.args,
                        'encoded_args': '0x' + leaf.encoded_args.hex(),
                        'leaf_hash': '0x' + leaf.leaf_hash.hex(),
                        'proof': [
                            '0x' + p.hex() for p in tree_data.proofs.get(i, [])
                        ],
                    }
                    for i, leaf in enumerate(tree_data.leaves)
                ],
            }

            safe_addr = hook_address.lower()
            hook_filepath = os.path.join(output_dir, f'hook_{safe_addr}.json')
            with open(hook_filepath, 'w') as f:
                json.dump(hook_file, f, indent=2)

        summary_filepath = os.path.join(output_dir, 'trees_summary.json')
        with open(summary_filepath, 'w') as f:
            json.dump(summary, f, indent=2)

        return output_dir
