"""Minimal contract-address resolver for SuperBank merkle root generation.

Reads config/deployments.json (snapshot of the archived superman repo's
contracts/deployments.json). Replaces superman's clients.utils.deployments,
dropping the web3/RPC dependencies that root generation never needed.
"""

import json
import os
from typing import Any, Dict, Optional

_DEPLOYMENTS_PATH = os.path.join(os.path.dirname(__file__), 'config', 'deployments.json')

_deployments: Optional[Dict[str, Any]] = None


def _load() -> Dict[str, Any]:
    global _deployments
    if _deployments is None:
        with open(_DEPLOYMENTS_PATH, 'r', encoding='utf-8') as f:
            _deployments = json.load(f)
    return _deployments


def _chain_contracts(chain_id: str, environment: Optional[str]) -> Dict[str, Any]:
    if environment is None:
        environment = os.getenv('ENVIRONMENT', 'prod')
    env_deployments = _load().get('environments', {}).get(environment, {})
    return env_deployments.get('networks', {}).get(str(chain_id), {}).get('contracts', {})


def get_contract_address(
    contract_name: str, chain_id: str = '1', environment: Optional[str] = None
) -> Optional[str]:
    """Get a contract address for a chain/environment, or None if not deployed."""
    return _chain_contracts(chain_id, environment).get(contract_name)


def get_chain_deployments(chain_id: str = '1', environment: Optional[str] = None) -> Dict[str, Any]:
    """Get all contract addresses for a chain/environment."""
    return _chain_contracts(chain_id, environment)
