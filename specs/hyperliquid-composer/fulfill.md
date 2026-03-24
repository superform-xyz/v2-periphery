# Configurable Deposit Lock for SuperVault Redeems

## Overview

Enforce a **configurable lock period** on redemptions for **specific vaults on specific chains**. If a user deposits into a locked vault, they can only redeem after the configured lock duration (e.g. 1 week, 2 weeks, 3 weeks). This is enforced at the **fulfillment service level** (not smart contract level) in the `superman` codebase.

The lock is **opt-in per vault+chain** via a config file. Each entry specifies its own lock duration. Vaults not listed in the config have no lock — fulfillment works normally.

## Current Architecture

### Subgraph Data Available

The subgraph already tracks deposit timestamps (`super-vault.ts:105`):
```typescript
deposit.timestamp = event.block.timestamp;
```

**Deposit Entity** (from `ENTITY_DOCUMENTATION.md`):
```graphql
type Deposit @entity(immutable: true) {
  id: String!          # Format: transactionHash-logIndex
  sender: String!      # Deposit initiator
  owner: String!       # Share recipient
  vault: Vault!        # Vault reference
  assets: BigInt!      # Assets deposited
  shares: BigInt!      # Shares received
  timestamp: BigInt!   # Block timestamp
}
```

### Fulfillment Service Flow

Location: `/Users/cosming/1.Coding/Superform/superman/src/services/fulfill_redeems/`

Current filtering pipeline (`service.py:346`):
1. Query pending redemptions from database
2. Get current PPS from subgraph
3. **Filter by slippage tolerance** (`filter_redemptions_by_slippage`)
4. Filter controllers with zero assets
5. Calculate withdrawal cascade
6. Execute `fulfillRedeemRequests` on-chain

## Implementation Plan

### 1. Create Deposit Lock Filter Module

Create `src/services/fulfill_redeems/deposit_lock.py`:

```python
"""
Deposit lock filter for FulfillRedeems service.

Enforces a configurable lock period after deposits before allowing redemption fulfillment.
Controllers whose latest deposit is within the lock period are skipped.
"""

from dataclasses import dataclass
from datetime import datetime, timezone, timedelta
from typing import List, Optional

from .types import PendingRedemption

# No default — lock duration comes from config per vault+chain


@dataclass
class DepositLockFilterResult:
    """Result of deposit lock filtering."""
    passing: List[PendingRedemption]  # Controllers eligible for fulfillment
    skipped: List[PendingRedemption]  # Controllers still in lock period

    @property
    def total_skipped_shares(self) -> int:
        return sum(r.shares for r in self.skipped)


def filter_redemptions_by_deposit_lock(
    redemptions: List[PendingRedemption],
    vault_address: str,
    subgraph_client,
    lock_duration: timedelta,
) -> DepositLockFilterResult:
    """
    Filter redemption requests by deposit lock period.

    Controllers whose latest deposit to the vault is within the lock period
    will be skipped. This prevents immediate withdrawal after deposit.

    Args:
        redemptions: List of pending redemption requests
        vault_address: Vault address to check deposits for
        subgraph_client: Client to query subgraph for deposit data
        lock_duration: Lock period duration (from config)

    Returns:
        DepositLockFilterResult with passing and skipped redemptions

    Example:
        >>> result = filter_redemptions_by_deposit_lock(
        ...     redemptions, vault_address, subgraph_client
        ... )
        >>> len(result.passing)   # Controllers past lock period
        5
        >>> len(result.skipped)   # Controllers still locked
        2
    """
    passing: List[PendingRedemption] = []
    skipped: List[PendingRedemption] = []
    now = datetime.now(timezone.utc)
    lock_cutoff = now - lock_duration

    # Batch query: get latest deposit for all controllers at once
    controllers = [r.controller for r in redemptions]
    latest_deposits = subgraph_client.get_latest_deposits_batch(
        vault=vault_address,
        owners=controllers
    )

    for redemption in redemptions:
        controller = redemption.controller.lower()
        latest_deposit_timestamp = latest_deposits.get(controller)

        if latest_deposit_timestamp is None:
            # No deposit found - this shouldn't happen for valid redemptions
            # but allow it to proceed (they have shares somehow)
            passing.append(redemption)
        elif latest_deposit_timestamp <= lock_cutoff:
            # Lock period has passed - allow redemption
            passing.append(redemption)
        else:
            # Still within lock period - skip
            skipped.append(redemption)

    return DepositLockFilterResult(passing=passing, skipped=skipped)


def check_deposit_lock(
    deposit_timestamp: datetime,
    lock_duration: timedelta,
) -> bool:
    """
    Check if a deposit has passed the lock period.

    Args:
        deposit_timestamp: When the deposit occurred (UTC)
        lock_duration: Required lock period

    Returns:
        True if lock period has passed, False if still locked
    """
    now = datetime.now(timezone.utc)
    return (now - deposit_timestamp) >= lock_duration
```

### 2. Add Subgraph Query Method

Add to subgraph client (e.g., `libs/subgraph_client/client.py`):

```python
def get_latest_deposits_batch(
    self,
    vault: str,
    owners: List[str]
) -> Dict[str, Optional[datetime]]:
    """
    Query latest deposit timestamp for multiple owners in a vault.

    Args:
        vault: Vault address
        owners: List of owner addresses to query

    Returns:
        Dict mapping owner address (lowercase) to their latest deposit timestamp,
        or None if no deposits found
    """
    # GraphQL query with batching
    query = """
    query GetLatestDeposits($vault: String!, $owners: [String!]!) {
      deposits(
        where: { vault: $vault, owner_in: $owners }
        orderBy: timestamp
        orderDirection: desc
        first: 1000
      ) {
        owner
        timestamp
      }
    }
    """

    result = self.execute(query, {
        "vault": vault.lower(),
        "owners": [o.lower() for o in owners]
    })

    # Build map of owner -> latest timestamp (first occurrence per owner)
    latest_by_owner: Dict[str, Optional[datetime]] = {}
    for deposit in result.get("deposits", []):
        owner = deposit["owner"].lower()
        if owner not in latest_by_owner:
            timestamp = datetime.fromtimestamp(
                int(deposit["timestamp"]),
                tz=timezone.utc
            )
            latest_by_owner[owner] = timestamp

    # Fill in None for owners with no deposits
    for owner in owners:
        if owner.lower() not in latest_by_owner:
            latest_by_owner[owner.lower()] = None

    return latest_by_owner
```

### 3. Integrate into Service

See **"Updated Integration (Section 3 Revision)"** below — the service checks the config first and only runs the filter when a lock is configured for the vault+chain.

### 4. Update Skip Tracking

Modify `_build_skipped_controllers_dict()` to include deposit lock skips:

```python
def _build_skipped_controllers_dict(
    zero_assets_controllers: List[str],
    slippage_skipped: List[PendingRedemption],
    deposit_lock_skipped: List[PendingRedemption] = None,  # Add new param
) -> Dict[str, List[str]]:
    """Build skipped controllers dict for result_data."""
    result = {
        'zero_assets': zero_assets_controllers,
        'slippage': [r.controller for r in slippage_skipped],
    }
    if deposit_lock_skipped:
        result['deposit_lock'] = [r.controller for r in deposit_lock_skipped]
    return result
```

### 5. Deposit Lock Config File (Required)

Create `src/services/fulfill_redeems/deposit_lock_config.json`:

This is the **source of truth** for which vaults have a deposit lock. If a vault+chain is not listed here, no lock is applied and fulfillment proceeds normally.

```json
{
  "deposit_locks": [
    {
      "chain_id": 42161,
      "vault": "0x1234...abcd",
      "lock_days": 14,
      "description": "Arbitrum HyperLiquid USDC SuperVault"
    },
    {
      "chain_id": 8453,
      "vault": "0xabcd...1234",
      "lock_days": 7,
      "description": "Base HyperLiquid USDC SuperVault — 1 week lock"
    },
    {
      "chain_id": 10,
      "vault": "0x5678...efgh",
      "lock_days": 21,
      "description": "Optimism SuperVault — 3 week lock"
    }
  ]
}
```

**Key behaviors:**
- The service reads this file on startup (or on each run cycle)
- Lookup is by `(chain_id, vault_address_lowercase)` tuple
- If no entry found for a vault+chain, **no lock is applied** — all redemptions pass through
- `lock_days` is configurable per entry (e.g. 7 = 1 week, 14 = 2 weeks, 21 = 3 weeks)
- Adding/removing entries is a config change, no code deploy needed

### 6. Config Loader

Add to `src/services/fulfill_redeems/deposit_lock.py`:

```python
import json
from pathlib import Path
from typing import Dict, Tuple, Optional

DepositLockKey = Tuple[int, str]  # (chain_id, vault_address_lowercase)

def load_deposit_lock_config(
    config_path: Optional[Path] = None,
) -> Dict[DepositLockKey, timedelta]:
    """
    Load deposit lock configuration from JSON file.

    Returns:
        Dict mapping (chain_id, vault_address) to lock duration.
        Empty dict if file not found or empty — meaning no locks.
    """
    if config_path is None:
        config_path = Path(__file__).parent / "deposit_lock_config.json"

    if not config_path.exists():
        return {}

    with open(config_path) as f:
        data = json.load(f)

    locks: Dict[DepositLockKey, timedelta] = {}
    for entry in data.get("deposit_locks", []):
        key = (entry["chain_id"], entry["vault"].lower())
        lock_days = entry["lock_days"]
        locks[key] = timedelta(days=lock_days)

    return locks


def get_lock_duration(
    config: Dict[DepositLockKey, timedelta],
    chain_id: int,
    vault_address: str,
) -> Optional[timedelta]:
    """
    Get lock duration for a vault+chain. Returns None if no lock configured.
    """
    return config.get((chain_id, vault_address.lower()))
```

## Updated Integration (Section 3 Revision)

The service should check the config before running the deposit lock filter:

```python
from .deposit_lock import (
    load_deposit_lock_config,
    get_lock_duration,
    filter_redemptions_by_deposit_lock,
)

# Load config once at service init (or per cycle)
deposit_lock_config = load_deposit_lock_config()

# In fulfill_pending_redeems(), before filtering:
lock_duration = get_lock_duration(deposit_lock_config, chain_id, vault_address)

if lock_duration is not None:
    # This vault+chain has a deposit lock configured
    deposit_lock_result = filter_redemptions_by_deposit_lock(
        redemptions=pending,
        vault_address=vault_address,
        subgraph_client=self.subgraph_manager.get_client(chain_id),
        lock_duration=lock_duration,
    )
    self.logger.info(
        f"Deposit lock active for {vault_address} on chain {chain_id}: "
        f"{len(deposit_lock_result.passing)} passing, "
        f"{len(deposit_lock_result.skipped)} skipped"
    )
    pending = deposit_lock_result.passing
    deposit_lock_skipped = deposit_lock_result.skipped
else:
    # No lock for this vault+chain — proceed normally
    deposit_lock_skipped = []

# Continue with slippage filter on remaining `pending`...
```

## Files to Modify

| File | Action |
|------|--------|
| `src/services/fulfill_redeems/deposit_lock.py` | **CREATE** - Filter module + config loader |
| `src/services/fulfill_redeems/deposit_lock_config.json` | **CREATE** - Per-vault+chain lock config |
| `src/services/fulfill_redeems/service.py` | **MODIFY** - Add config-driven filter to pipeline |
| `src/services/fulfill_redeems/__init__.py` | **MODIFY** - Export new functions |
| `libs/subgraph_client/client.py` | **MODIFY** - Add batch deposit query |
| `src/services/fulfill_redeems/formatting.py` | **MODIFY** - Format deposit lock skips |

## Testing

Create `src/services/fulfill_redeems/tests/test_deposit_lock.py`:

```python
import pytest
from datetime import datetime, timezone, timedelta
from ..deposit_lock import check_deposit_lock, load_deposit_lock_config

class TestCheckDepositLock:
    def test_deposit_within_lock_period_is_skipped(self):
        """Deposit 7 days ago with 14-day lock should be skipped."""
        deposit_time = datetime.now(timezone.utc) - timedelta(days=7)
        assert check_deposit_lock(deposit_time, timedelta(days=14)) is False

    def test_deposit_past_lock_period_passes(self):
        """Deposit 15 days ago with 14-day lock should pass."""
        deposit_time = datetime.now(timezone.utc) - timedelta(days=15)
        assert check_deposit_lock(deposit_time, timedelta(days=14)) is True

    def test_deposit_exactly_at_lock_boundary(self):
        """Deposit exactly at lock boundary should pass."""
        deposit_time = datetime.now(timezone.utc) - timedelta(days=14)
        assert check_deposit_lock(deposit_time, timedelta(days=14)) is True

    def test_one_week_lock(self):
        """7-day lock: deposit 8 days ago should pass."""
        deposit_time = datetime.now(timezone.utc) - timedelta(days=8)
        assert check_deposit_lock(deposit_time, timedelta(days=7)) is True

    def test_three_week_lock(self):
        """21-day lock: deposit 15 days ago should still be locked."""
        deposit_time = datetime.now(timezone.utc) - timedelta(days=15)
        assert check_deposit_lock(deposit_time, timedelta(days=21)) is False


class TestLoadDepositLockConfig:
    def test_missing_file_returns_empty(self, tmp_path):
        """Missing config file means no locks."""
        config = load_deposit_lock_config(tmp_path / "nonexistent.json")
        assert config == {}

    def test_loads_different_durations(self, tmp_path):
        """Each vault+chain can have a different lock duration."""
        config_file = tmp_path / "config.json"
        config_file.write_text('{"deposit_locks": ['
            '{"chain_id": 42161, "vault": "0xAAA", "lock_days": 14},'
            '{"chain_id": 8453, "vault": "0xBBB", "lock_days": 7}'
        ']}')
        config = load_deposit_lock_config(config_file)
        assert config[(42161, "0xaaa")] == timedelta(days=14)
        assert config[(8453, "0xbbb")] == timedelta(days=7)
```

## Edge Cases to Handle

1. **User with no deposits but has shares** (e.g., received via transfer)
   - Current plan: Allow redemption (no deposit timestamp to enforce)
   - Alternative: Track share acquisition time via Transfer events

2. **Multiple deposits**
   - Use the **latest** deposit timestamp (most restrictive)

3. **Partial redemptions**
   - Lock applies to all shares, not proportional to deposit timing

4. **Vault migration / share transfers**
   - May need to track Transfer events if strict enforcement is required

5. **Vault not in config**
   - No lock applied — all redemptions proceed normally
   - This is the default behavior for all vaults not explicitly listed

6. **Config file missing or empty**
   - Treated as no locks configured — all vaults proceed without lock
   - Service logs a warning but does not fail

## Rollout Considerations

1. **Retroactive application**: Existing depositors in configured vaults may be affected if their deposit is within the configured lock period
2. **User communication**: Frontend should show lock status and unlock time for configured vaults
3. **Monitoring**: Add metrics for deposit_lock skips to track impact
4. **Config management**: Adding/removing vault locks is a config-only change — no code deploy required. Just update `deposit_lock_config.json` and restart the service (or reload config on next cycle)
