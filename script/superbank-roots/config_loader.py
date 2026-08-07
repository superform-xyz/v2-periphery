"""
Merkle Configuration Loader

This module handles loading and parsing of configuration files for the merkle tree system.
It manages address registries and hook configurations needed to generate merkle trees.
"""

import json
import os
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from eth_utils import to_checksum_address

from deployments_resolver import get_chain_deployments


@dataclass
class ArgFilter:
    """Filter configuration for hook arguments.

    Simple tag-based filtering:
    - tags: address must have ALL these tags to be included
    - exclude_tags: address with ANY of these tags is excluded
    """

    tags: List[str] = field(default_factory=list)
    exclude_tags: List[str] = field(default_factory=list)


@dataclass
class HookArgInfo:
    """Information about a hook argument for merkle tree generation."""

    name: str
    type: str  # 'token', 'yieldSource', 'beneficiary', 'staking', 'contract', 'feeRecipient'
    subtype: Optional[str] = None  # For contract type: 'pendle_market', 'swap', 'limit_order', etc.
    filter: Optional[ArgFilter] = None  # Filter configuration

    def __post_init__(self):
        """Validate argument type and convert filter dict to ArgFilter."""
        valid_types = {"token", "yieldSource", "beneficiary", "staking", "contract", "feeRecipient"}
        if self.type not in valid_types:
            raise ValueError(f"Invalid argument type '{self.type}'. Valid types: {valid_types}")

        # Contract type requires subtype
        if self.type == "contract" and not self.subtype:
            raise ValueError(f"Contract type argument '{self.name}' requires a subtype")

        # Convert filter dict to ArgFilter if needed
        if isinstance(self.filter, dict):
            self.filter = ArgFilter(
                tags=self.filter.get("tags", []),
                exclude_tags=self.filter.get("excludeTags", []),
            )


@dataclass
class HookConfig:
    """Configuration for a specific hook."""

    name: str
    args: List[HookArgInfo]

    def __post_init__(self):
        """Convert dict args to HookArgInfo objects."""
        if self.args and isinstance(self.args[0], dict):
            self.args = [HookArgInfo(**arg) for arg in self.args]


@dataclass
class RecipesAllowed:
    """Recipe configuration for a yield source."""

    deposit: Optional[str] = None  # Recipe name for deposits (e.g., "4626_only_deposit")
    redemption: Optional[str] = None  # Recipe name for redemptions (e.g., "4626_only_redeem")


@dataclass
class AddressEntry:
    """An address entry with metadata."""

    symbol: str
    address: str
    category: Optional[str] = None
    tags: List[str] = field(default_factory=list)
    recipes_allowed: Optional[RecipesAllowed] = None

    def __post_init__(self):
        """Ensure address is checksummed and convert recipes_allowed dict."""
        self.address = to_checksum_address(self.address)

        # Convert recipes_allowed dict to RecipesAllowed if needed
        if isinstance(self.recipes_allowed, dict):
            self.recipes_allowed = RecipesAllowed(**self.recipes_allowed)


@dataclass
class ContractEntry:
    """A contract address entry with metadata for Pendle routers, markets, etc."""

    symbol: str
    address: str
    category: str  # router, market, etc.
    subtype: str  # pendle_market, swap, limit_order, etc.
    tags: List[str] = field(default_factory=list)

    def __post_init__(self):
        """Ensure address is checksummed."""
        # Allow zero address only for null/placeholder contracts (e.g., PendleLimitRouterNull)
        if self.address.lower() == "0x0000000000000000000000000000000000000000":
            if self.category != "null":
                raise ValueError(
                    f"Invalid address for {self.symbol}: address 0 is only allowed for category='null' contracts"
                )
            # Keep zero address as-is (checksummed form)
            self.address = "0x0000000000000000000000000000000000000000"
        else:
            self.address = to_checksum_address(self.address)


class MerkleConfigLoader:
    """
    Loader for merkle tree configuration files.

    Manages loading of deployments/address_registry.json and hook config files
    that contain the data needed to generate merkle trees.

    Hook configs are loaded from different locations based on config_type:
    - "global": deployments/hook_global_config.json (for global root)
    - "manager": deployments/hook_managers_config_template.json OR
                 deployments/{env}/{chain_id}/manager_trees/vault_{vault_address}.json (for manager roots)

    The manager config source is determined by the hook_config_type field in supervaults.json:
    - "template": Use hook_managers_config_template.json
    - "custom": Use vault-specific config from manager_trees/vault_{address}.json
    """

    def __init__(
        self,
        config_dir: Optional[str] = None,
        address_registry_path: Optional[str] = None,
        config_type: str = "manager",
    ):
        """
        Initialize the config loader.

        Args:
            config_dir: Directory containing hook_configs.json. If None, uses merkle directory.
            address_registry_path: Path to address_registry.json. If None, uses deployments/address_registry.json.
            config_type: Type of hook config to load - "global" or "manager" (default: "manager")
        """
        if config_dir is None:
            # Default to merkle directory where hook_configs.json is located
            config_dir = os.path.dirname(__file__)

        self.config_dir = config_dir
        self.config_type = config_type
        # Project root for deployments folder
        self._project_root = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
        )
        # Allow override for testing
        self._address_registry_path = address_registry_path or os.path.join(
            os.path.dirname(__file__), "config", "address_registry.json"
        )
        self._address_registry: Optional[Dict[str, Any]] = None
        self._hook_configs: Optional[Dict[str, HookConfig]] = None
        # Cache for vault-specific configs
        self._vault_hook_configs: Dict[str, Dict[str, HookConfig]] = {}

    def load_address_registry(self) -> Dict[str, Any]:
        """
        Load the address registry from deployments/address_registry.json.

        Returns:
            Dict containing address registry data organized by type and chain ID

        Raises:
            FileNotFoundError: If address_registry.json is not found
            ValueError: If the JSON structure is invalid
        """
        if self._address_registry is not None:
            return self._address_registry

        file_path = self._address_registry_path

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"Address registry file not found: {file_path}")
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in address registry: {e}")

        # Validate structure and convert addresses to AddressEntry objects
        validated_registry = {}

        for addr_type in ["tokens", "yieldSources", "beneficiaries", "staking", "feeRecipients"]:
            if addr_type not in data:
                continue

            validated_registry[addr_type] = {}

            for chain_id, entries in data[addr_type].items():
                validated_registry[addr_type][chain_id] = []

                if addr_type == "beneficiaries":
                    # Beneficiaries are just addresses, not objects
                    for addr in entries:
                        validated_registry[addr_type][chain_id].append(
                            AddressEntry(symbol="beneficiary", address=addr)
                        )
                else:
                    # Other types have symbol and address
                    for entry in entries:
                        if isinstance(entry, dict):
                            validated_registry[addr_type][chain_id].append(AddressEntry(**entry))
                        else:
                            # Handle plain address strings
                            validated_registry[addr_type][chain_id].append(
                                AddressEntry(symbol="unknown", address=entry)
                            )

        # Load contracts section (for Pendle routers, markets, etc.)
        if "contracts" in data:
            validated_registry["contracts"] = {}
            for chain_id, entries in data["contracts"].items():
                validated_registry["contracts"][chain_id] = []
                for entry in entries:
                    if isinstance(entry, dict):
                        validated_registry["contracts"][chain_id].append(ContractEntry(**entry))

        self._address_registry = validated_registry
        return self._address_registry

    def load_hook_configs(self) -> Dict[str, HookConfig]:
        """
        Load hook configurations based on config_type.

        For config_type="global":
            Loads from deployments/hook_global_config.json

        For config_type="manager":
            Loads from deployments/hook_managers_config_template.json
            (Use load_vault_hook_configs for vault-specific custom configs)

        If a custom config_dir was provided (not the default merkle directory),
        it will use the hook_configs.json from that directory (for testing).

        Returns:
            Dict mapping hook names to HookConfig objects

        Raises:
            FileNotFoundError: If hook configs file is not found
            ValueError: If the JSON structure is invalid
        """
        if self._hook_configs is not None:
            return self._hook_configs

        # Check if a custom config_dir was provided (not the default merkle directory)
        # This allows tests to use their own hook_configs.json
        default_merkle_dir = os.path.dirname(__file__)
        custom_config_file = os.path.join(self.config_dir, "hook_configs.json")
        if self.config_dir != default_merkle_dir and os.path.exists(custom_config_file):
            file_path = custom_config_file
        else:
            # Determine file path based on config_type
            if self.config_type == "global":
                file_path = os.path.join(
                    self._project_root, "deployments", "hook_global_config.json"
                )
            elif self.config_type == "manager":
                file_path = os.path.join(
                    self._project_root, "deployments", "hook_managers_config_template.json"
                )
            else:
                raise ValueError(
                    f"Invalid config_type: {self.config_type}. Must be 'global' or 'manager'"
                )

        self._hook_configs = self._load_hook_configs_from_file(file_path)
        return self._hook_configs

    def _load_hook_configs_from_file(self, file_path: str) -> Dict[str, HookConfig]:
        """
        Load hook configurations from a specific file path.

        Args:
            file_path: Path to the hook config JSON file

        Returns:
            Dict mapping hook names to HookConfig objects

        Raises:
            FileNotFoundError: If the file is not found
            ValueError: If the JSON structure is invalid
        """
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"Hook configs file not found: {file_path}")
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in hook configs: {e}")

        # Convert to HookConfig objects
        validated_configs = {}
        for hook_name, config_data in data.items():
            validated_configs[hook_name] = HookConfig(
                name=hook_name, args=config_data.get("args", [])
            )

        return validated_configs

    def load_vault_hook_configs(
        self,
        environment: str,
        chain_id: str,
        vault_address: str,
        hook_config_type: str = "template",
    ) -> Dict[str, HookConfig]:
        """
        Load hook configurations for a specific vault.

        Args:
            environment: Environment ("staging" or "prod")
            chain_id: Chain ID as string
            vault_address: Address of the vault
            hook_config_type: Type of config - "template" or "custom"

        Returns:
            Dict mapping hook names to HookConfig objects

        Raises:
            FileNotFoundError: If custom config is requested but doesn't exist
            ValueError: If the JSON structure is invalid
        """
        # Create cache key
        cache_key = f"{environment}:{chain_id}:{vault_address}:{hook_config_type}"
        if cache_key in self._vault_hook_configs:
            return self._vault_hook_configs[cache_key]

        if hook_config_type == "template":
            # Use the shared template
            file_path = os.path.join(
                self._project_root, "deployments", "hook_managers_config_template.json"
            )
        elif hook_config_type == "custom":
            # Use vault-specific config
            # Normalize address for filename (lowercase, no checksum)
            normalized_address = vault_address.lower()
            file_path = os.path.join(
                self._project_root,
                "deployments",
                environment,
                chain_id,
                "manager_trees",
                f"vault_{normalized_address}.json",
            )
        else:
            raise ValueError(
                f"Invalid hook_config_type: {hook_config_type}. Must be 'template' or 'custom'"
            )

        configs = self._load_hook_configs_from_file(file_path)
        self._vault_hook_configs[cache_key] = configs
        return configs

    def get_vault_hook_config_path(
        self,
        environment: str,
        chain_id: str,
        vault_address: str,
    ) -> str:
        """
        Get the path where a custom vault hook config would be stored.

        Args:
            environment: Environment ("staging" or "prod")
            chain_id: Chain ID as string
            vault_address: Address of the vault

        Returns:
            Path to the custom vault hook config file
        """
        normalized_address = vault_address.lower()
        return os.path.join(
            self._project_root,
            "deployments",
            environment,
            chain_id,
            "manager_trees",
            f"vault_{normalized_address}.json",
        )

    def get_addresses_for_type(
        self, addr_type: str, chain_id: int, hook_name: Optional[str] = None
    ) -> List[str]:
        """
        Get addresses for a specific type and chain ID.

        Args:
            addr_type: Type of address ('token', 'yieldSource', 'beneficiary', 'staking')
            chain_id: Chain ID to get addresses for
            hook_name: Optional hook name for filtering (future feature)

        Returns:
            List of addresses as strings
        """
        # Special handling for beneficiaries - load from supervaults.json
        if addr_type == "beneficiary":
            return self._get_beneficiary_addresses(chain_id)

        registry = self.load_address_registry()

        # Map singular types to plural registry keys
        type_mapping = {
            "token": "tokens",
            "yieldSource": "yieldSources",
            "beneficiary": "beneficiaries",
            "staking": "staking",
        }

        registry_key = type_mapping.get(addr_type, addr_type)
        chain_str = str(chain_id)

        if registry_key not in registry:
            return []

        if chain_str not in registry[registry_key]:
            return []

        # Extract addresses from AddressEntry objects
        entries = registry[registry_key][chain_str]
        addresses = [entry.address for entry in entries]

        # Apply hook-specific filtering in the future
        if hook_name:
            # TODO: Implement hook-specific filtering based on allowedTokens, etc.
            pass

        return addresses

    def get_hook_config(self, hook_name: str) -> Optional[HookConfig]:
        """
        Get configuration for a specific hook.

        Args:
            hook_name: Name of the hook

        Returns:
            HookConfig object or None if not found
        """
        configs = self.load_hook_configs()
        return configs.get(hook_name)

    def get_hook_address(self, hook_name: str, chain_id: int) -> Optional[str]:
        """
        Get deployed address for a hook on a specific chain.

        Args:
            hook_name: Name of the hook
            chain_id: Chain ID

        Returns:
            Hook address or None if not found
        """
        try:
            deployments = get_chain_deployments(chain_id)

            # get_chain_deployments() returns the contracts section directly
            # So hooks are at the top level of the returned dictionary
            if hook_name in deployments:
                addr = deployments[hook_name]
                if isinstance(addr, str) and addr.startswith("0x"):
                    return to_checksum_address(addr)

        except Exception as e:
            # If deployment lookup fails, return None
            # This allows the system to continue with hooks that have addresses
            print(f"Error getting hook address for {hook_name}: {e}")

        return None

    def get_available_hooks(self, chain_id: int) -> Dict[str, str]:
        """
        Get all available hooks with their addresses for a chain.

        Args:
            chain_id: Chain ID to check

        Returns:
            Dict mapping hook names to addresses
        """
        configs = self.load_hook_configs()
        available_hooks = {}

        for hook_name in configs.keys():
            address = self.get_hook_address(hook_name, chain_id)
            if address:
                available_hooks[hook_name] = address

        return available_hooks

    def _get_beneficiary_addresses(self, chain_id: int) -> List[str]:
        """
        Get beneficiary addresses from supervaults.json.

        Beneficiaries are strategy addresses from deployed SuperVaults.
        These are the addresses that receive tokens during redeem operations.

        Args:
            chain_id: Chain ID to get addresses for

        Returns:
            List of strategy addresses as beneficiaries
        """
        try:
            # Look for supervaults.json files in the standard location
            scripts_dir = os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "scripts")
            supervaults_files = []

            # Search for supervaults.json files for this chain
            for root, dirs, files in os.walk(scripts_dir):
                for file in files:
                    if file == "supervaults.json":
                        file_path = os.path.join(root, file)
                        supervaults_files.append(file_path)

            chain_str = str(chain_id)
            strategy_addresses = set()  # Use set to avoid duplicates

            # Process all supervaults.json files
            for file_path in supervaults_files:
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        data = json.load(f)

                    # Check if this file is for our chain
                    if data.get("chain_id") == chain_str:
                        deployments = data.get("deployments", [])
                        for deployment in deployments:
                            strategy_address = deployment.get("strategy_address")
                            if strategy_address:
                                strategy_addresses.add(to_checksum_address(strategy_address))

                except (json.JSONDecodeError, KeyError) as e:
                    print(f"Error loading supervaults file {file_path}: {e}")
                    continue

            return list(strategy_addresses)

        except Exception as e:
            print(f"Error loading beneficiaries from supervaults.json: {e}")
            # Fallback to address registry if supervaults.json not available
            return self._get_beneficiaries_from_registry(chain_id)

    def _get_beneficiaries_from_registry(self, chain_id: int) -> List[str]:
        """
        Fallback method to get beneficiaries from address registry.

        Args:
            chain_id: Chain ID to get addresses for

        Returns:
            List of addresses from address registry
        """
        try:
            registry = self.load_address_registry()
            chain_str = str(chain_id)

            if "beneficiaries" not in registry or chain_str not in registry["beneficiaries"]:
                return []

            entries = registry["beneficiaries"][chain_str]
            return [entry.address for entry in entries]

        except Exception as e:
            print(f"Error loading beneficiaries from registry: {e}")
            return []

    def validate_config_integrity(self) -> List[str]:
        """
        Validate the integrity of loaded configurations.

        Returns:
            List of validation error messages (empty if all valid)
        """
        errors = []

        try:
            # Load and validate address registry
            registry = self.load_address_registry()

            # Check for required sections (beneficiaries now come from supervaults.json)
            required_sections = ["tokens", "yieldSources"]
            for section in required_sections:
                if section not in registry:
                    errors.append(f"Missing required section '{section}' in address registry")

            # Validate hook configs
            configs = self.load_hook_configs()

            if not configs:
                errors.append("No hook configurations found")

            # Check that each hook config has valid arguments
            for hook_name, config in configs.items():
                if not config.args:
                    errors.append(f"Hook '{hook_name}' has no argument configuration")

                for arg in config.args:
                    if arg.type not in [
                        "token",
                        "yieldSource",
                        "beneficiary",
                        "staking",
                        "contract",
                    ]:
                        errors.append(f"Hook '{hook_name}' has invalid argument type '{arg.type}'")

        except Exception as e:
            errors.append(f"Configuration validation failed: {str(e)}")

        return errors

    def get_hook_configs(self) -> Dict[str, HookConfig]:
        """
        Get all hook configurations.

        Returns:
            Dict mapping hook names to HookConfig objects
        """
        return self.load_hook_configs()

    def get_tokens(self, chain_id: str) -> List[Dict[str, str]]:
        """
        Get all tokens for a specific chain.

        Args:
            chain_id: Chain ID as string

        Returns:
            List of token dictionaries with 'symbol' and 'address' keys
        """
        registry = self.load_address_registry()

        if "tokens" not in registry or chain_id not in registry["tokens"]:
            return []

        entries = registry["tokens"][chain_id]
        return [{"symbol": entry.symbol, "address": entry.address} for entry in entries]

    def get_yield_sources(self, chain_id: str) -> List[Dict[str, str]]:
        """
        Get all yield sources for a specific chain.

        Args:
            chain_id: Chain ID as string

        Returns:
            List of yield source dictionaries with 'symbol' and 'address' keys
        """
        registry = self.load_address_registry()

        if "yieldSources" not in registry or chain_id not in registry["yieldSources"]:
            return []

        entries = registry["yieldSources"][chain_id]
        return [{"symbol": entry.symbol, "address": entry.address} for entry in entries]

    def is_valid_token_address(self, token_address: str, chain_id: str) -> bool:
        """
        Check if a token address is valid for a specific chain.

        Args:
            token_address: Token address to validate
            chain_id: Chain ID as string

        Returns:
            True if token address exists in the registry for this chain
        """
        try:
            token_address = to_checksum_address(token_address)
            tokens = self.get_tokens(chain_id)
            token_addresses = [token["address"] for token in tokens]
            return token_address in token_addresses
        except Exception:
            return False

    def get_yield_source_address(self, yield_source_name: str, chain_id: str) -> Optional[str]:
        """
        Get the address for a yield source by name.

        Args:
            yield_source_name: Name/symbol of the yield source
            chain_id: Chain ID as string

        Returns:
            Yield source address or None if not found
        """
        try:
            yield_sources = self.get_yield_sources(chain_id)
            for source in yield_sources:
                if source["symbol"] == yield_source_name:
                    return source["address"]
            return None
        except Exception:
            return None

    def get_contracts(self, chain_id: str, subtype: Optional[str] = None) -> List[ContractEntry]:
        """
        Get contract entries for a specific chain, optionally filtered by subtype.

        Args:
            chain_id: Chain ID as string
            subtype: Optional subtype filter (e.g., 'pendle_market', 'swap', 'limit_order')

        Returns:
            List of ContractEntry objects
        """
        registry = self.load_address_registry()

        if "contracts" not in registry or chain_id not in registry["contracts"]:
            return []

        contracts = registry["contracts"][chain_id]

        if subtype:
            return [c for c in contracts if c.subtype == subtype]

        return contracts

    def get_address_entries(self, chain_id: str, addr_type: str) -> List[AddressEntry]:
        """
        Get AddressEntry objects for a specific chain and type.

        This returns the full AddressEntry objects with tags, unlike get_tokens/get_yield_sources
        which return simplified dicts.

        Args:
            chain_id: Chain ID as string
            addr_type: Type of address ('tokens', 'yieldSources', 'beneficiaries', 'staking')

        Returns:
            List of AddressEntry objects
        """
        registry = self.load_address_registry()

        if addr_type not in registry or chain_id not in registry[addr_type]:
            return []

        return registry[addr_type][chain_id]
