"""
Merkle Tree Builder

This module implements the core merkle tree building functionality for SuperVault hooks.
The key change from the old implementation is the new leaf format: [hookAddress, encodedArgs]
instead of just encodedArgs.
"""

import itertools
from dataclasses import dataclass
from typing import TYPE_CHECKING, Any, Dict, List, Optional, Tuple

from eth_abi import encode
from eth_utils import keccak, to_checksum_address

from config_loader import AddressEntry, ArgFilter, ContractEntry, HookConfig, MerkleConfigLoader

# Zero address constant - must never appear in any merkle tree
ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"


def validate_address_not_zero(address: str, context: str = "address") -> None:
    """Validate that an address is not the zero address.

    Args:
        address: Address to validate
        context: Context for error message (e.g., "beneficiary for vault 0x...")

    Raises:
        ValueError: If address is zero address
    """
    if address.lower() == ZERO_ADDRESS.lower():
        raise ValueError(f"Invalid {context}: address 0 is not allowed in merkle trees")


if TYPE_CHECKING:
    from .external_config_reader import StrategyConfig


class FilterEngine:
    """Engine for filtering addresses based on hook arg filters.

    Simple tag-based filtering:
    - tags: address must have ALL these tags to be included
    - exclude_tags: address with ANY of these tags is excluded
    """

    def filter_addresses(
        self,
        addresses: List[AddressEntry],
        filter_config: Optional[ArgFilter],
    ) -> List[AddressEntry]:
        """Filter addresses based on filter configuration.

        Args:
            addresses: List of addresses to filter
            filter_config: Filter configuration (or None for no filtering)

        Returns:
            Filtered list of addresses
        """
        if not filter_config:
            return addresses

        result = []
        for addr in addresses:
            if self._matches_filter(addr.tags, filter_config):
                result.append(addr)

        return result

    def filter_contracts(
        self,
        contracts: List[ContractEntry],
        filter_config: Optional[ArgFilter],
    ) -> List[ContractEntry]:
        """Filter contracts based on filter configuration.

        Args:
            contracts: List of contracts to filter
            filter_config: Filter configuration (or None for no filtering)

        Returns:
            Filtered list of contracts
        """
        if not filter_config:
            return contracts

        result = []
        for contract in contracts:
            if self._matches_filter(contract.tags, filter_config):
                result.append(contract)

        return result

    def _matches_filter(
        self,
        tags: List[str],
        filter_config: ArgFilter,
    ) -> bool:
        """Check if tags match the filter configuration.

        Args:
            tags: List of tags on the address/contract
            filter_config: Filter configuration

        Returns:
            True if the tags match the filter
        """
        # Check tags whitelist (must have ALL tags)
        if filter_config.tags:
            if not all(tag in tags for tag in filter_config.tags):
                return False

        # Check tags blacklist (must not have ANY tag)
        if filter_config.exclude_tags:
            if any(tag in tags for tag in filter_config.exclude_tags):
                return False

        return True


@dataclass
class MerkleLeaf:
    """Represents a single leaf in the merkle tree."""

    hook_name: str
    hook_address: str
    args: Dict[str, str]  # argument name -> address
    encoded_args: bytes
    leaf_hash: bytes

    def to_leaf_data(self) -> List[Any]:
        """Convert to the format expected by merkle tree library: [hookAddress, encodedArgs]."""
        return [self.hook_address, self.encoded_args]


@dataclass
class MerkleTreeData:
    """Complete merkle tree data structure."""

    root: bytes
    leaves: List[MerkleLeaf]
    tree_height: int
    total_leaves: int

    def get_leaf_by_index(self, index: int) -> Optional[MerkleLeaf]:
        """Get leaf by index."""
        if 0 <= index < len(self.leaves):
            return self.leaves[index]
        return None

    def find_leaf(self, hook_address: str, encoded_args: bytes) -> Optional[Tuple[int, MerkleLeaf]]:
        """Find a leaf by hook address and encoded args."""
        for i, leaf in enumerate(self.leaves):
            if leaf.hook_address == hook_address and leaf.encoded_args == encoded_args:
                return i, leaf
        return None


class MerkleTreeBuilder:
    """
    Builder for merkle trees using the new [hookAddress, encodedArgs] leaf format.

    This is the Python equivalent of the JavaScript build-hook-merkle-trees.js
    with the same deterministic tree generation algorithm.
    """

    def __init__(self, config_loader: Optional[MerkleConfigLoader] = None):
        """
        Initialize the tree builder.

        Args:
            config_loader: Configuration loader. If None, creates a default one.
        """
        self.config_loader = config_loader or MerkleConfigLoader()

    def encode_hook_args(self, args: Dict[str, str], hook_config: HookConfig) -> bytes:
        """
        Encode hook arguments using the same method as the JavaScript implementation.
        Uses solidityPack equivalent (abi.encodePacked).

        Args:
            args: Dictionary mapping argument names to addresses
            hook_config: Hook configuration

        Returns:
            Packed encoded arguments as bytes
        """
        if not args:
            return b""

        # Build types and values arrays in the correct order
        types = []
        values = []

        for arg_info in hook_config.args:
            arg_name = arg_info.name
            if arg_name in args:
                types.append("address")  # All our args are addresses
                values.append(to_checksum_address(args[arg_name]))

        if not types:
            return b""

        # Use abi.encode with tight packing (equivalent to solidityPack)
        # We need to manually pack addresses as 20-byte values
        packed_data = b""
        for value in values:
            # Ensure value is a string and has proper format
            if not isinstance(value, str):
                raise ValueError(f"Address must be a string, got {type(value)}: {value}")

            if not value.startswith("0x"):
                raise ValueError(f"Address must start with 0x: {value}")

            hex_part = value[2:]
            if len(hex_part) != 40:
                raise ValueError(
                    f"Address must be 40 hex chars after 0x, got {len(hex_part)}: {value}"
                )

            # Remove 0x prefix and convert to bytes, ensure 20 bytes
            try:
                addr_bytes = bytes.fromhex(hex_part)
            except ValueError as e:
                raise ValueError(f"Invalid hex in address {value}: {e}")

            if len(addr_bytes) != 20:
                raise ValueError(f"Invalid address length: {value}")
            packed_data += addr_bytes

        return packed_data

    def _generate_filtered_argument_combinations(
        self,
        hook_name: str,
        hook_config: HookConfig,
        tokens: List[Dict[str, str]] = [],
        yield_sources: List[Dict[str, str]] = [],
        beneficiaries: List[str] = [],
        fee_recipients: List[str] = [],
    ) -> List[Dict[str, str]]:
        """
        Generate argument combinations using pre-filtered strategy data.

        Args:
            hook_name: Name of the hook
            hook_config: Hook configuration
            tokens: Pre-filtered token list
            yield_sources: Pre-filtered yield source list
            beneficiaries: Pre-filtered beneficiary list
            fee_recipients: Pre-filtered fee recipient list

        Returns:
            List of argument combinations
        """
        # Get possible addresses for each argument from filtered data
        arg_values = {}

        for arg_info in hook_config.args:
            addresses = []

            if arg_info.type == "token":
                addresses = [token["address"] for token in tokens]
            elif arg_info.type == "yieldSource":
                addresses = [source["address"] for source in yield_sources]
            elif arg_info.type == "beneficiary":
                addresses = beneficiaries
            elif arg_info.type == "staking":
                # Strategy configs don't currently specify staking separately
                addresses = []
            elif arg_info.type == "feeRecipient":
                # feeRecipient type - use pre-filtered fee recipients
                addresses = fee_recipients

            if addresses:
                arg_values[arg_info.name] = addresses

        # Generate all combinations using itertools.product
        if not arg_values:
            return []

        arg_names = list(arg_values.keys())
        value_lists = [arg_values[name] for name in arg_names]

        combinations = []
        for combination in itertools.product(*value_lists):
            combo_dict = dict(zip(arg_names, combination))
            combinations.append(combo_dict)

        return combinations

    def create_merkle_leaf(
        self, hook_name: str, hook_address: str, args: Dict[str, str], hook_config: HookConfig
    ) -> MerkleLeaf:
        """
        Create a single merkle leaf using exact Solidity _createLeaf logic.

        Solidity implementation:
        keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))))

        Args:
            hook_name: Name of the hook
            hook_address: Address of the deployed hook
            args: Argument combination
            hook_config: Hook configuration

        Returns:
            MerkleLeaf object

        Raises:
            ValueError: If any address argument is address 0
        """
        # Validate no zero addresses in args (except for allowed special cases)
        # Pendle hooks can have zero addresses when:
        # - limitRouter: not using limit orders
        # - pendleSwap: market accepts token directly without internal swap
        # - extRouter: no external router needed (e.g., Odos/KyberSwap)
        ZERO_ADDRESS_ALLOWED_ARGS = {
            "limitRouter", "pendleSwap", "extRouter", "feeRecipient", "exclusiveRelayer",
        }
        for arg_name, arg_value in args.items():
            if arg_name not in ZERO_ADDRESS_ALLOWED_ARGS:
                validate_address_not_zero(
                    arg_value, f"argument '{arg_name}' for hook '{hook_name}'"
                )

        # Ensure hook address has proper format
        hook_address = to_checksum_address(hook_address)

        # Encode the arguments
        encoded_args = self.encode_hook_args(args, hook_config)

        # Step 1: abi.encode(hookAddress, hookArgs)
        # This matches Solidity's abi.encode for address and bytes
        abi_encoded = encode(["address", "bytes"], [hook_address, encoded_args])

        # Step 2: keccak256(abi_encoded)
        inner_hash = keccak(abi_encoded)

        # Step 3: bytes.concat(inner_hash) - in this case just the hash itself
        # Step 4: keccak256(bytes.concat(inner_hash))
        leaf_hash = keccak(inner_hash)

        return MerkleLeaf(
            hook_name=hook_name,
            hook_address=hook_address,
            args=args.copy(),
            encoded_args=encoded_args,
            leaf_hash=leaf_hash,
        )

    def _calculate_merkle_root(self, leaf_hashes: List[bytes]) -> bytes:
        """
        Calculate merkle root from leaf hashes using the same algorithm as the JS implementation.

        Args:
            leaf_hashes: List of leaf hashes (should be pre-sorted)

        Returns:
            Merkle root as bytes
        """
        if not leaf_hashes:
            return b"\x00" * 32

        if len(leaf_hashes) == 1:
            return leaf_hashes[0]

        # Build layers bottom-up
        current_layer = leaf_hashes[:]

        while len(current_layer) > 1:
            next_layer = []

            # Process pairs
            for i in range(0, len(current_layer), 2):
                if i + 1 < len(current_layer):
                    # Hash the pair - ensure consistent ordering
                    left = current_layer[i]
                    right = current_layer[i + 1]

                    # Use the same ordering as OpenZeppelin's MerkleTree
                    if left <= right:
                        combined = left + right
                    else:
                        combined = right + left

                    next_layer.append(keccak(combined))
                else:
                    # Odd number of nodes - duplicate the last one
                    next_layer.append(current_layer[i])

            current_layer = next_layer

        return current_layer[0]

    def _calculate_tree_height(self, leaf_count: int) -> int:
        """Calculate the height of a merkle tree with the given number of leaves."""
        if leaf_count <= 1:
            return 0

        height = 0
        nodes = leaf_count

        while nodes > 1:
            nodes = (nodes + 1) // 2  # Ceiling division
            height += 1

        return height

    def generate_merkle_proof(
        self, tree_data: MerkleTreeData, leaf_index: int
    ) -> Optional[List[bytes]]:
        """
        Generate a merkle proof for a specific leaf.

        Args:
            tree_data: The merkle tree data
            leaf_index: Index of the leaf to prove

        Returns:
            List of sibling hashes for the proof, or None if invalid index
        """
        if not (0 <= leaf_index < len(tree_data.leaves)):
            return None

        leaf_hashes = [leaf.leaf_hash for leaf in tree_data.leaves]
        proof = []
        current_layer = leaf_hashes[:]
        current_index = leaf_index

        while len(current_layer) > 1:
            next_layer = []

            # Calculate sibling index
            if current_index % 2 == 0:
                # Left node - sibling is right
                sibling_index = current_index + 1
            else:
                # Right node - sibling is left
                sibling_index = current_index - 1

            # Add sibling to proof if it exists
            if sibling_index < len(current_layer):
                proof.append(current_layer[sibling_index])

            # Build next layer
            for i in range(0, len(current_layer), 2):
                if i + 1 < len(current_layer):
                    left = current_layer[i]
                    right = current_layer[i + 1]

                    if left <= right:
                        combined = left + right
                    else:
                        combined = right + left

                    next_layer.append(keccak(combined))
                else:
                    next_layer.append(current_layer[i])

            current_layer = next_layer
            current_index = current_index // 2

        return proof

    def verify_merkle_proof(
        self, leaf_hash: bytes, proof: List[bytes], root: bytes, leaf_index: int
    ) -> bool:
        """
        Verify a merkle proof.

        Args:
            leaf_hash: Hash of the leaf to verify
            proof: List of sibling hashes
            root: Expected merkle root
            leaf_index: Index of the leaf in the tree

        Returns:
            True if proof is valid
        """
        current_hash = leaf_hash
        current_index = leaf_index

        for sibling in proof:
            if current_index % 2 == 0:
                # Current node is left child
                if current_hash <= sibling:
                    combined = current_hash + sibling
                else:
                    combined = sibling + current_hash
            else:
                # Current node is right child
                if sibling <= current_hash:
                    combined = sibling + current_hash
                else:
                    combined = current_hash + sibling

            current_hash = keccak(combined)
            current_index = current_index // 2

        return current_hash == root

    def build_strategy_merkle_tree(
        self,
        chain_id: str,
        manager_tree_config: "StrategyConfig",
        strategy_address: str,
        hook_names: Optional[List[str]] = None,
        hook_config_type: str = "template",
        vault_address: Optional[str] = None,
        environment: Optional[str] = None,
    ) -> MerkleTreeData:
        """
        Build a merkle tree for a specific strategy configuration.

        Supports two modes:
        1. Template mode (default): Uses explicit whitelists from manager_tree_config
        2. Custom mode: Uses tag-based filtering from vault-specific hook config

        Args:
            chain_id: Chain ID as string
            manager_tree_config: Strategy-specific configuration with whitelisting
            strategy_address: Address of the strategy (used as beneficiary)
            hook_names: Optional subset of hooks to include (defaults to all whitelisted)
            hook_config_type: "template" or "custom" - determines filtering approach
            vault_address: Required for custom hook_config_type
            environment: Environment name (staging, prod) for custom config path

        Returns:
            MerkleTreeData with strategy-specific leaves

        Raises:
            ValueError: If strategy_address or any beneficiary is address 0
        """
        import os

        # Validate strategy address is not zero
        if strategy_address.lower() == ZERO_ADDRESS.lower():
            raise ValueError(f"Invalid strategy address for manager tree: address 0 is not allowed")

        # Get beneficiaries (default to strategy address if none specified)
        beneficiaries = manager_tree_config.beneficiaries or [strategy_address]

        # Validate all beneficiaries are not zero address
        for beneficiary in beneficiaries:
            validate_address_not_zero(beneficiary, f"beneficiary in manager tree")

        # Use strategy's whitelisted hooks or provided subset
        hooks_to_use = hook_names or manager_tree_config.whitelisted_hooks

        # Custom hook config: use tag-based filtering
        if hook_config_type == "custom" and vault_address:
            return self._build_strategy_tree_with_tags(
                chain_id=chain_id,
                hooks_to_use=hooks_to_use,
                vault_address=vault_address,
                environment=environment or os.getenv("ENVIRONMENT", "staging"),
                beneficiaries=beneficiaries,
                whitelisted_yield_source_names=manager_tree_config.whitelisted_yield_sources,
                strategy_name=manager_tree_config.name,
            )

        # Template mode: use explicit whitelists
        # Filter tokens to whitelisted only
        whitelisted_tokens = []
        for token_address in manager_tree_config.whitelisted_tokens:
            # Validate token exists in registry
            if self.config_loader.is_valid_token_address(token_address, str(chain_id)):
                whitelisted_tokens.append(
                    {
                        "address": token_address,
                        "symbol": f"Token_{token_address[:8]}",  # Generate symbol for display
                    }
                )
            else:
                raise ValueError(
                    f"Whitelisted token {token_address} not found in address registry for chain {chain_id}"
                )

        # Filter yield sources to whitelisted only
        whitelisted_sources = []
        for yield_source in manager_tree_config.whitelisted_yield_sources:
            # Handle both dict format (with symbol key) and string format
            if isinstance(yield_source, dict):
                source_name = yield_source.get("symbol", str(yield_source))
            else:
                source_name = yield_source
            source_address = self.config_loader.get_yield_source_address(source_name, str(chain_id))
            if source_address:
                whitelisted_sources.append({"symbol": source_name, "address": source_address})
            else:
                raise ValueError(
                    f"Whitelisted yield source '{source_name}' not found in address registry for chain {chain_id}"
                )

        # Validate that all hooks exist and get their addresses
        validated_hooks = {}
        for hook_name in hooks_to_use:
            hook_address = self.config_loader.get_hook_address(hook_name, int(chain_id))
            if hook_address:
                validated_hooks[hook_name] = hook_address
            else:
                raise ValueError(
                    f"Whitelisted hook '{hook_name}' not found in deployments for chain {chain_id}"
                )

        # Filter fee recipients to whitelisted only
        whitelisted_fee_recipients = []
        for fee_recipient_address in manager_tree_config.whitelisted_fee_recipients:
            # Validate fee recipient exists in registry
            fee_recipient_entries = self.config_loader.get_address_entries(
                str(chain_id), "feeRecipients"
            )
            valid_fee_recipients = [fr.address for fr in fee_recipient_entries]
            if fee_recipient_address in valid_fee_recipients:
                whitelisted_fee_recipients.append(
                    {
                        "address": fee_recipient_address,
                        "symbol": f"FeeRecipient_{fee_recipient_address[:8]}",  # Generate symbol for display
                    }
                )
            else:
                raise ValueError(
                    f"Whitelisted fee recipient '{fee_recipient_address}' not found in address registry for chain {chain_id}"
                )

        print(f"Building strategy tree for '{manager_tree_config.name}':")
        print(f"  - Hooks: {len(validated_hooks)}")
        print(f"  - Tokens: {len(whitelisted_tokens)}")
        print(f"  - Yield sources: {len(whitelisted_sources)}")
        print(f"  - Beneficiaries: {len(beneficiaries)}")
        print(f"  - Fee recipients: {len(whitelisted_fee_recipients)}")

        # Build tree with filtered configuration
        return self._build_merkle_tree_with_filtered_config(
            chain_id=chain_id,
            validated_hooks=validated_hooks,
            tokens=whitelisted_tokens,
            yield_sources=whitelisted_sources,
            beneficiaries=beneficiaries,
            fee_recipients=[fr["address"] for fr in whitelisted_fee_recipients],
        )

    def _build_strategy_tree_with_tags(
        self,
        chain_id: str,
        hooks_to_use: List[str],
        vault_address: str,
        environment: str,
        beneficiaries: List[str],
        whitelisted_yield_source_names: List[str],
        strategy_name: str,
    ) -> MerkleTreeData:
        """
        Build a strategy tree using tag-based filtering from vault-specific hook config.

        This method loads the vault's custom hook config and uses the tag filters
        defined in each hook's arguments to resolve addresses from address_registry.

        Args:
            chain_id: Chain ID as string
            hooks_to_use: List of hook names to include
            vault_address: Vault address for loading custom config
            environment: Environment name (staging, prod)
            beneficiaries: List of beneficiary addresses
            whitelisted_yield_source_names: Yield source symbols from supervaults.json
            strategy_name: Name of the strategy for logging

        Returns:
            MerkleTreeData with strategy-specific leaves
        """
        import json
        import os

        # Load vault-specific hook config
        project_root = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
        )
        normalized_address = vault_address.lower()
        config_path = os.path.join(
            project_root,
            "deployments",
            environment,
            chain_id,
            "manager_trees",
            f"vault_{normalized_address}.json",
        )

        if not os.path.exists(config_path):
            raise FileNotFoundError(
                f"Custom hook config not found: {config_path}. "
                f"Create vault_{normalized_address}.json for custom hook_config_type."
            )

        with open(config_path) as f:
            vault_hook_config = json.load(f)

        # Get all addresses from registry for tag-based filtering
        chain_str = str(chain_id)
        token_entries = self.config_loader.get_address_entries(chain_str, "tokens")
        yield_source_entries = self.config_loader.get_address_entries(chain_str, "yieldSources")
        contract_entries = self.config_loader.get_contracts(chain_str)
        fee_recipient_entries = self.config_loader.get_address_entries(chain_str, "feeRecipients")

        # Also build yield source lookup by symbol for whitelisted_yield_sources
        yield_source_by_symbol = {ys.symbol: ys for ys in yield_source_entries}

        # Get whitelisted yield sources by symbol
        whitelisted_yield_sources = []
        for yield_source in whitelisted_yield_source_names:
            # Handle both dict format (with symbol key) and string format
            if isinstance(yield_source, dict):
                symbol = yield_source.get("symbol", str(yield_source))
            else:
                symbol = yield_source
            if symbol in yield_source_by_symbol:
                whitelisted_yield_sources.append(yield_source_by_symbol[symbol])

        filter_engine = FilterEngine()

        # Validate hooks and get addresses
        validated_hooks = {}
        for hook_name in hooks_to_use:
            hook_address = self.config_loader.get_hook_address(hook_name, int(chain_id))
            if hook_address:
                validated_hooks[hook_name] = hook_address
            else:
                raise ValueError(
                    f"Hook '{hook_name}' not found in deployments for chain {chain_id}"
                )

        print(f"Building strategy tree for '{strategy_name}' (custom config):")
        print(f"  - Hooks: {len(validated_hooks)}")
        print(f"  - Available tokens: {len(token_entries)}")
        print(f"  - Whitelisted yield sources: {len(whitelisted_yield_sources)}")
        print(f"  - Beneficiaries: {len(beneficiaries)}")

        leaves = []

        for hook_name, hook_address in validated_hooks.items():
            # Get hook config from vault-specific config or fall back to template
            hook_args_config = vault_hook_config.get(hook_name, {}).get("args", [])

            # Get standard hook config for encoding
            hook_config = self.config_loader.get_hook_config(hook_name)
            if not hook_config:
                print(f"Warning: No configuration found for hook '{hook_name}', skipping")
                continue

            # Build argument values using tag-based filtering
            arg_values = {}

            for arg_info in hook_config.args:
                arg_name = arg_info.name

                # Find matching arg config from vault-specific config
                vault_arg_config = next(
                    (a for a in hook_args_config if a.get("name") == arg_name), None
                )

                # Custom configs require all args to be explicitly defined
                if not vault_arg_config:
                    raise ValueError(
                        f"Hook '{hook_name}' arg '{arg_name}' not found in vault config. "
                        f"Custom configs require all args to be explicitly defined."
                    )

                # Custom configs require explicit type for all args
                if "type" not in vault_arg_config:
                    raise ValueError(
                        f"Hook '{hook_name}' arg '{arg_name}' missing 'type' field. "
                        f"Custom configs require explicit type for all args."
                    )

                arg_type = vault_arg_config["type"]

                # Get filter from vault config
                filter_config = None
                if "filter" in vault_arg_config:
                    filter_data = vault_arg_config["filter"]
                    filter_config = ArgFilter(
                        tags=filter_data.get("tags", []),
                        exclude_tags=filter_data.get("excludeTags", []),
                    )

                addresses = []

                if arg_type == "token":
                    # Filter tokens by tag
                    filtered = filter_engine.filter_addresses(token_entries, filter_config)
                    addresses = [t.address for t in filtered]
                elif arg_type == "yieldSource":
                    # Use whitelisted yield sources, then apply tag filter
                    filtered = filter_engine.filter_addresses(
                        whitelisted_yield_sources, filter_config
                    )
                    addresses = [ys.address for ys in filtered]
                elif arg_type == "beneficiary":
                    addresses = beneficiaries
                elif arg_type == "contract":
                    # Filter contracts by tag
                    filtered = filter_engine.filter_contracts(contract_entries, filter_config)
                    addresses = [c.address for c in filtered]
                elif arg_type == "feeRecipient":
                    # feeRecipient type - filter from pre-fetched fee recipients
                    filtered = filter_engine.filter_addresses(fee_recipient_entries, filter_config)
                    addresses = [fr.address for fr in filtered]

                if addresses:
                    arg_values[arg_name] = addresses

            # Generate all combinations
            if not arg_values:
                continue

            arg_names = list(arg_values.keys())
            value_lists = [arg_values[name] for name in arg_names]

            for combination in itertools.product(*value_lists):
                args_combo = dict(zip(arg_names, combination))

                try:
                    leaf = self.create_merkle_leaf(
                        hook_name=hook_name,
                        hook_address=hook_address,
                        args=args_combo,
                        hook_config=hook_config,
                    )
                    leaves.append(leaf)
                except Exception as e:
                    print(f"Error creating leaf for {hook_name} with args {args_combo}: {e}")
                    continue

        if not leaves:
            raise ValueError("No valid leaves generated for custom strategy configuration")

        # Sort leaves deterministically
        leaves.sort(key=lambda x: (x.hook_address, x.encoded_args))

        print(f"Generated {len(leaves)} leaves for custom strategy")

        # Calculate merkle root and tree height
        root = self._calculate_merkle_root([leaf.leaf_hash for leaf in leaves])
        tree_height = self._calculate_tree_height(len(leaves))

        return MerkleTreeData(
            leaves=leaves, root=root, tree_height=tree_height, total_leaves=len(leaves)
        )

    def _build_merkle_tree_with_filtered_config(
        self,
        chain_id: str,
        validated_hooks: Dict[str, str],
        tokens: List[Dict[str, str]],
        yield_sources: List[Dict[str, str]],
        beneficiaries: List[str],
        fee_recipients: List[str],
    ) -> MerkleTreeData:
        """
        Build merkle tree with pre-filtered and validated configuration.

        Args:
            chain_id: Chain ID as string
            validated_hooks: Dict of hook_name -> hook_address (pre-validated)
            tokens: List of token dictionaries (pre-filtered)
            yield_sources: List of yield source dictionaries (pre-filtered)
            beneficiaries: List of beneficiary addresses
            fee_recipients: List of fee recipient addresses (pre-filtered)

        Returns:
            MerkleTreeData object
        """
        leaves = []

        for hook_name, hook_address in validated_hooks.items():
            # Get hook configuration to understand its arguments
            hook_config = self.config_loader.get_hook_config(hook_name)
            if not hook_config:
                print(f"Warning: No configuration found for hook '{hook_name}', skipping")
                continue

            # Generate address combinations for this hook's arguments using pre-filtered data
            arg_combinations = self._generate_filtered_argument_combinations(
                hook_name=hook_name,
                hook_config=hook_config,
                tokens=tokens,
                yield_sources=yield_sources,
                beneficiaries=beneficiaries,
                fee_recipients=fee_recipients,
            )

            # Create leaves for each combination
            for args_combo in arg_combinations:
                try:
                    # Use the proper leaf creation method
                    leaf = self.create_merkle_leaf(
                        hook_name=hook_name,
                        hook_address=hook_address,
                        args=args_combo,
                        hook_config=hook_config,
                    )

                    leaves.append(leaf)

                except Exception as e:
                    print(f"Error creating leaf for {hook_name} with args {args_combo}: {e}")
                    continue

        if not leaves:
            raise ValueError("No valid leaves generated for strategy configuration")

        # Sort leaves deterministically for consistent trees
        leaves.sort(key=lambda x: (x.hook_address, x.encoded_args))

        print(f"Generated {len(leaves)} leaves for strategy")

        # Calculate merkle root and tree height
        root = self._calculate_merkle_root([leaf.leaf_hash for leaf in leaves])
        tree_height = self._calculate_tree_height(len(leaves))

        return MerkleTreeData(
            leaves=leaves, root=root, tree_height=tree_height, total_leaves=len(leaves)
        )

    def build_global_hooks_tree(self, chain_id: int, use_filters: bool = True) -> MerkleTreeData:
        """
        Build a global hooks merkle tree containing all registered hooks combined
        with ALL tokens and yield sources from address_registry.json.

        The global tree is comprehensive - it includes all possible hook × token ×
        yield source combinations for the chain. This allows any strategy to use
        any combination that's been globally approved.

        SECURITY MODEL FOR BENEFICIARY ARGUMENTS:
        -----------------------------------------
        Hooks with beneficiary arguments (e.g., Redeem4626VaultHook, TransferERC20Hook)
        are EXCLUDED from the global tree entirely.

        Security rationale:
        1. Beneficiary hooks are inherently strategy-specific (require specific owner/recipient)
        2. Address 0 is never a valid beneficiary and must not appear in any merkle tree
        3. Global tree should only contain hooks that work generically across all strategies
        4. Manager trees provide the proper security boundary for beneficiary validation

        This design ensures:
        - No risk of address 0 validation bypass
        - Clear separation: global = generic hooks, manager = strategy-specific hooks
        - Per-strategy isolation for beneficiary-based operations

        Args:
            chain_id: Chain ID for which to build the global tree
            use_filters: Whether to apply tag-based filtering from hook configs (default: True)

        Returns:
            MerkleTreeData with all hook/token/yield_source combinations as leaves
        """
        chain_str = str(chain_id)

        # Get all available hooks for this chain
        available_hooks = self.config_loader.get_available_hooks(chain_id)
        if not available_hooks:
            raise ValueError(f"No hooks found for chain {chain_id}")

        # Get AddressEntry objects with tags for filtering
        token_entries = self.config_loader.get_address_entries(chain_str, "tokens")
        yield_source_entries = self.config_loader.get_address_entries(chain_str, "yieldSources")
        staking_entries = self.config_loader.get_address_entries(chain_str, "staking")
        contract_entries = self.config_loader.get_contracts(chain_str)
        fee_recipient_entries = self.config_loader.get_address_entries(chain_str, "feeRecipients")

        # For backwards compatibility, also maintain simple address lists
        token_addresses = [t.address for t in token_entries]
        yield_source_addresses = [ys.address for ys in yield_source_entries]
        staking_addresses = [s.address for s in staking_entries]

        print(f"Building global hooks tree for chain {chain_id}:")
        print(f"  - Hooks: {len(available_hooks)}")
        print(f"  - Tokens: {len(token_addresses)}")
        print(f"  - Yield Sources: {len(yield_source_addresses)}")
        print(f"  - Staking: {len(staking_addresses)}")
        print(f"  - Contracts: {len(contract_entries)}")
        print(f"  - Using filters: {use_filters}")

        leaves = []
        skipped_beneficiary_hooks = []

        filter_engine = FilterEngine() if use_filters else None

        for hook_name, hook_address in available_hooks.items():
            try:
                # Get hook configuration
                hook_config = self.config_loader.get_hook_config(hook_name)
                if not hook_config:
                    print(f"Warning: No configuration found for hook '{hook_name}', skipping")
                    continue

                # SECURITY: Skip hooks with beneficiary arguments - they belong only in manager trees
                has_beneficiary = any(arg.type == "beneficiary" for arg in hook_config.args)
                if has_beneficiary:
                    skipped_beneficiary_hooks.append(hook_name)
                    continue

                # Generate all argument combinations for this hook
                if use_filters:
                    arg_combinations = self._generate_filtered_global_arg_combinations(
                        hook_config=hook_config,
                        token_entries=token_entries,
                        yield_source_entries=yield_source_entries,
                        staking_entries=staking_entries,
                        contract_entries=contract_entries,
                        fee_recipient_entries=fee_recipient_entries,
                        filter_engine=filter_engine,
                    )
                else:
                    arg_combinations = self._generate_global_arg_combinations(
                        hook_config=hook_config,
                        tokens=token_addresses,
                        yield_sources=yield_source_addresses,
                        staking=staking_addresses,
                    )

                # Create a leaf for each combination
                for args in arg_combinations:
                    try:
                        leaf = self.create_merkle_leaf(
                            hook_name=hook_name,
                            hook_address=hook_address,
                            args=args,
                            hook_config=hook_config,
                        )
                        leaves.append(leaf)
                    except Exception as e:
                        # Skip invalid combinations silently
                        continue

            except Exception as e:
                print(f"Warning: Error processing hook {hook_name}: {e}")
                continue

        if skipped_beneficiary_hooks:
            print(
                f"  - Skipped {len(skipped_beneficiary_hooks)} hooks with beneficiary args: {skipped_beneficiary_hooks}"
            )

        if not leaves:
            raise ValueError(f"No valid leaves generated for global hooks tree on chain {chain_id}")

        # Sort leaves deterministically for consistent trees
        leaves.sort(key=lambda x: (x.hook_address, x.encoded_args))

        print(f"Generated {len(leaves)} leaves for global hooks tree")

        # Calculate merkle root and tree height
        root = self._calculate_merkle_root([leaf.leaf_hash for leaf in leaves])
        tree_height = self._calculate_tree_height(len(leaves))

        return MerkleTreeData(
            leaves=leaves, root=root, tree_height=tree_height, total_leaves=len(leaves)
        )

    def _generate_global_arg_combinations(
        self,
        hook_config: HookConfig,
        tokens: List[str],
        yield_sources: List[str],
        staking: List[str],
    ) -> List[Dict[str, str]]:
        """
        Generate all argument combinations for a hook in the global tree.

        For the global tree, we generate all possible combinations of:
        - tokens × yield_sources for hooks that need both
        - just yield_sources for hooks that only need yield source
        - just tokens for hooks that only need token
        - staking addresses for staking hooks

        SECURITY: Hooks with beneficiary arguments are NOT allowed in global tree.
        They should only appear in manager-specific trees. This method will raise
        an error if called for such hooks.

        Args:
            hook_config: Hook configuration with argument types
            tokens: List of all token addresses
            yield_sources: List of all yield source addresses
            staking: List of all staking addresses

        Returns:
            List of argument dictionaries

        Raises:
            ValueError: If hook has beneficiary arguments
        """
        # Safety check: reject beneficiary hooks - they should be filtered before calling this
        if any(arg.type == "beneficiary" for arg in hook_config.args):
            raise ValueError(
                f"Security violation: Hook '{hook_config.name}' has beneficiary arguments "
                f"and cannot be included in global tree. Filter these hooks in build_global_hooks_tree()."
            )

        if not hook_config.args:
            # Hook takes no arguments
            return [{}]

        # Determine what address types this hook needs
        needs_token = any(arg.type == "token" for arg in hook_config.args)
        needs_yield_source = any(arg.type == "yieldSource" for arg in hook_config.args)
        needs_staking = any(arg.type == "staking" for arg in hook_config.args)
        needs_fee_recipient = any(arg.type == "feeRecipient" for arg in hook_config.args)

        combinations = []

        # Get the specific argument names for each type
        token_args = [arg.name for arg in hook_config.args if arg.type == "token"]
        yield_source_args = [arg.name for arg in hook_config.args if arg.type == "yieldSource"]
        staking_args = [arg.name for arg in hook_config.args if arg.type == "staking"]

        # Build combinations based on what the hook needs
        if needs_yield_source and needs_token:
            # Hooks like ApproveAndDeposit4626VaultHook need both
            for ys in yield_sources:
                for token in tokens:
                    args = {}
                    for arg_name in yield_source_args:
                        args[arg_name] = ys
                    for arg_name in token_args:
                        args[arg_name] = token
                    combinations.append(args)
        elif needs_yield_source:
            # Hooks like Deposit4626VaultHook only need yield source
            for ys in yield_sources:
                args = {}
                for arg_name in yield_source_args:
                    args[arg_name] = ys
                combinations.append(args)
        elif needs_staking and needs_token:
            # Hooks like ApproveAndGearboxStakeHook
            for s in staking:
                for token in tokens:
                    args = {}
                    for arg_name in staking_args:
                        args[arg_name] = s
                    for arg_name in token_args:
                        args[arg_name] = token
                    combinations.append(args)
        elif needs_staking:
            # Hooks like GearboxUnstakeHook
            for s in staking:
                args = {}
                for arg_name in staking_args:
                    args[arg_name] = s
                combinations.append(args)
        elif needs_token:
            # Hooks that only need tokens (like SwapOdosV2Hook with tokenIn/tokenOut)
            # For swap hooks with multiple token args, we need token × token combinations
            if len(token_args) == 2:
                # Swap hooks - all token pairs
                for token_in in tokens:
                    for token_out in tokens:
                        args = {
                            token_args[0]: token_in,
                            token_args[1]: token_out,
                        }
                        combinations.append(args)
            else:
                # Single token arg
                for token in tokens:
                    args = {}
                    for arg_name in token_args:
                        args[arg_name] = token
                    combinations.append(args)
        elif needs_fee_recipient:
            # Hook only has feeRecipient args (like MerklClaimRewardHook with feeRecipient)
            combinations.append({})
        else:
            # Hook has no recognized argument types
            combinations.append({})

        return combinations if combinations else [{}]

    def _generate_filtered_global_arg_combinations(
        self,
        hook_config: HookConfig,
        token_entries: List[AddressEntry],
        yield_source_entries: List[AddressEntry],
        staking_entries: List[AddressEntry],
        contract_entries: List[ContractEntry],
        fee_recipient_entries: List[AddressEntry],
        filter_engine: FilterEngine,
    ) -> List[Dict[str, str]]:
        """
        Generate argument combinations with tag-based filtering for the global tree.

        This method applies the filter configuration from each hook argument to filter
        addresses based on their tags.

        SECURITY: Hooks with beneficiary arguments are NOT allowed in global tree.
        They should only appear in manager-specific trees. This method will raise
        an error if called for such hooks.

        Args:
            hook_config: Hook configuration with argument types and filters
            token_entries: List of token AddressEntry objects
            yield_source_entries: List of yield source AddressEntry objects
            staking_entries: List of staking AddressEntry objects
            contract_entries: List of ContractEntry objects
            filter_engine: FilterEngine instance for applying filters

        Returns:
            List of argument dictionaries with filtered addresses

        Raises:
            ValueError: If hook has beneficiary arguments
        """
        # Safety check: reject beneficiary hooks - they should be filtered before calling this
        if any(arg.type == "beneficiary" for arg in hook_config.args):
            raise ValueError(
                f"Security violation: Hook '{hook_config.name}' has beneficiary arguments "
                f"and cannot be included in global tree. Filter these hooks in build_global_hooks_tree()."
            )
        if not hook_config.args:
            return [{}]

        # Build filtered address lists per argument
        arg_addresses: Dict[str, List[str]] = {}

        for arg in hook_config.args:
            addresses: List[str] = []

            if arg.type == "token":
                filtered = filter_engine.filter_addresses(token_entries, arg.filter)
                addresses = [entry.address for entry in filtered]

            elif arg.type == "yieldSource":
                filtered = filter_engine.filter_addresses(yield_source_entries, arg.filter)
                addresses = [entry.address for entry in filtered]

            elif arg.type == "staking":
                filtered = filter_engine.filter_addresses(staking_entries, arg.filter)
                addresses = [entry.address for entry in filtered]

            elif arg.type == "contract":
                # Filter contracts by subtype first, then apply tag filter
                subtype_filtered = [c for c in contract_entries if c.subtype == arg.subtype]
                filtered = filter_engine.filter_contracts(subtype_filtered, arg.filter)
                addresses = [entry.address for entry in filtered]

            elif arg.type == "feeRecipient":
                # feeRecipient type - filter from pre-fetched fee recipients
                filtered = filter_engine.filter_addresses(fee_recipient_entries, arg.filter)
                addresses = [entry.address for entry in filtered]

            if addresses:
                arg_addresses[arg.name] = addresses
            else:
                # If no addresses pass the filter, this arg gets no combinations
                # Log this as it might indicate a misconfiguration
                print(
                    f"  Warning: No addresses for arg '{arg.name}' "
                    f"(type={arg.type}, filter={arg.filter})"
                )
                arg_addresses[arg.name] = []

        # Check if any arg has no addresses - if so, no combinations possible
        if any(len(addrs) == 0 for addrs in arg_addresses.values()):
            return []

        # Generate all combinations using itertools.product
        arg_names = list(arg_addresses.keys())
        value_lists = [arg_addresses[name] for name in arg_names]

        combinations = []
        for combo_values in itertools.product(*value_lists):
            combo = dict(zip(arg_names, combo_values))
            combinations.append(combo)

        return combinations
