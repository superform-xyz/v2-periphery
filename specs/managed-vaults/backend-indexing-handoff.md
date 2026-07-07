# Managed Vaults — Backend Indexing Handoff

**Source of truth:** this repo (`v2-periphery`), `src/ManagedSuperVault/` + `src/interfaces/ManagedSuperVault/`. This is a **new vault family**, a sibling to SuperVaults — not a change to existing SuperVault indexing.

This document is intentionally backend-agnostic. The Erebor vs Persephone/datamat split is left to the two repo owners (see §7); everything here applies regardless of where the work lands.

## 1. Identity model (read this first)

Each Managed Vault is a **trio of clones**: `{ vault, controller, escrow }`, plus two singletons shared across all vaults (`aggregator`, `executor`).

- **`vault`** — the ERC-20 share token and ERC-7540 surface. This is the user-facing address.
- **`controller`** — holds deposit/redeem accounting, execution policy, fees, and **operational asset custody**. **The aggregator keys almost everything by `controller` address, not `vault`.**
- **`escrow`** — custody of pending-deposit assets and in-flight redeem shares.
- **`aggregator`** (singleton) — registry + the entire **attested-manual NAV lifecycle**, keyed by controller.
- **`executor`** (singleton) — session keys, keyed by controller.

Build the `vault ↔ controller ↔ escrow` map from `ManagedSuperVaultDeployed`. When you see an aggregator event keyed by `controller`, join back to `vault` for display.

## 2. Discovery / addresses

- **Aggregator address:** SuperGovernor registry under `keccak256("MANAGED_SUPER_VAULT_AGGREGATOR")`; also in `script/output/{prod|staging}/{chainId}/{Chain}-latest.json` as `ManagedSuperVaultAggregator`. Deterministic per environment.
- **New vaults:** subscribe to `ManagedSuperVaultDeployed` on the aggregator. Backfill via `getAllManagedVaults()` / `getAllManagedVaultControllers()`.
- **Executor address:** output JSON `ManagedSuperVaultExecutor` (optional; only if session keys are used).

## 3. Event catalog (grouped by concern)

### Creation & config — emitter: **aggregator**
```solidity
ManagedSuperVaultDeployed(address indexed vault, address indexed controller, address escrow,
                          address asset, string name, string symbol, uint256 indexed nonce)
ManagedVaultConfigRegistered(address indexed controller, DepositApprovalMode approvalMode, string metadataURI)
MetadataURIUpdated(address indexed controller, string metadataURI)   // metadataURI is EVENT-ONLY (no getter)
```

### NAV lifecycle — emitter: **aggregator**, keyed by controller
```solidity
NAVProposed(address indexed controller, uint256 indexed proposalId, uint256 previousPPS,
            uint256 proposedPPS, uint256 effectiveTimestamp, address indexed proposer,
            bytes32 evidenceHash, string evidenceURI)
NAVAttested(address indexed controller, uint256 indexed proposalId, address indexed attestor, uint8 attestationCount)
NAVFinalized(address indexed controller, uint256 indexed proposalId, uint256 finalizedPPS, uint256 timestamp)
NAVReviewRequired(address indexed controller, uint256 indexed proposalId, uint256 proposedPPS, uint256 currentPPS)
NAVProposalCanceled(address indexed controller, uint256 indexed proposalId, address indexed canceledBy)
NAVLargeDeviationResolved(address indexed controller, uint256 indexed proposalId, address indexed resolvedBy)
ManagedNAVUpdated(address indexed controller, uint256 previousPPS, uint256 newPPS, uint256 timestamp)  // the stored/finalized value
ManagedNAVDeviationExceeded(address indexed controller, uint256 proposedPPS, uint256 currentPPS, uint256 deviation)
PPSUpdatedAfterSkim(address indexed controller, uint256 oldPPS, uint256 newPPS, uint256 feeAmount, uint256 timestamp)
// attestor set (timelocked)
NAVAttestorAdded / NAVAttestorRemoved(address indexed controller, address indexed attestor)
NAVAttestationThresholdUpdated(address indexed controller, uint8 threshold)
NAVAttestationConfigProposed(address indexed controller, address[] attestors, uint8 threshold, uint256 effectiveTime)
NAVAttestationConfigCancelled(address indexed controller)
```

### Pause / freshness / registry params — emitter: **aggregator**
```solidity
ManagedVaultPaused / ManagedVaultUnpaused(address indexed controller)
ManagedVaultNAVStale / ManagedVaultNAVStaleReset(address indexed controller)
SecondaryManagerAdded / SecondaryManagerRemoved(address indexed controller, address indexed manager)
PrimaryManagerChangeProposed / PrimaryManagerChangeCancelled / PrimaryManagerChanged(...)   // timelocked
DeviationThresholdChangeProposed / DeviationThresholdUpdated / DeviationThresholdChangeCancelled(...)  // timelocked
MinUpdateIntervalChangeProposed / MinUpdateIntervalChanged / MinUpdateIntervalChangeCancelled(...)     // timelocked
HighWaterMarkReset(address indexed controller, uint256 newHwmPps)
```

### Async deposit state machine — emitters: **vault** (ERC-7540) + **controller**
```solidity
// vault (ERC-7540):
DepositRequest(address indexed controller, address indexed owner, uint256 indexed requestId, address sender, uint256 assets)
CancelDepositRequest(address indexed controller, uint256 indexed requestId, address sender)
CancelDepositClaim(address indexed receiver, address indexed controller, uint256 indexed requestId, address sender, uint256 assets)
Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares)  // the claim (mint)
// controller:
DepositRequestPlaced(address indexed controller, uint256 assets)
DepositRequestFulfilled(address indexed controller, uint256 assetsGross, uint256 assetsNet, uint256 shares, uint256 pps)
DepositRequestRejected(address indexed controller, uint256 assets, string reason)
DepositRequestCanceled(address indexed controller, uint256 assets)
DepositClaimed(address indexed controller, uint256 assets)
DepositPolicyUpdated(DepositApprovalMode approvalMode, bool depositsPaused, uint256 minDepositAssets, uint256 maxDepositAssets)
```
State: `Requested → (Fulfilled → Claimable → Claimed) | Rejected | Canceled`. `requestId` is always `0` (single-request model). Claimable is denominated in **assets**, minted at `averageDepositPrice` on claim.

### Async redeem state machine — emitters: **vault** + **controller**
```solidity
// vault: RedeemRequest, CancelRedeemRequest, CancelRedeemClaim, Withdraw(...)
// controller:
RedeemRequestPlaced(address indexed controller, address indexed owner, uint256 shares)
RedeemRequestsFulfilled(address[] controllers, uint256 processedShares, uint256 currentPPS)
RedeemClaimable(address indexed controller, uint256 assetsFulfilled, uint256 sharesFulfilled, uint256 averageWithdrawPrice)
RedeemRequestClaimed(address indexed controller, address indexed receiver, uint256 assets, uint256 shares)
RedeemCancelRequestPlaced / RedeemCancelRequestFulfilled / RedeemRequestCanceled(...)
```

### Approvals — emitter: **controller**
```solidity
DepositorApproved(address indexed depositor, bytes32 kycRef)   // kycRef is a HASH, event-only, never PII
DepositorRejected(address indexed depositor)
DepositorRevoked(address indexed depositor)
```

### Whitelisted execution — emitter: **controller**
```solidity
ManagedCallExecuted(address indexed executor, address indexed target, bytes4 indexed selector,
                    uint256 value, bytes32 operationId, bytes32 calldataHash)
CallRuleSet(address indexed target, bytes4 indexed selector, bool allowed, bool valueAllowed,
            uint256 maxValuePerCall, uint256 windowValueCap, uint64 windowDuration, uint8[] constrainedArgs)
CallRuleRemoved(address indexed target, bytes4 indexed selector)
ArgAllowedValueSet(address indexed target, bytes4 indexed selector, uint8 argIndex, address value, bool allowed)
```

### Fees — emitter: **controller**
```solidity
ManagementFeePaid(...)         // entry fee at deposit fulfillment
PerformanceFeeSkimmed(uint256 totalFee, uint256 superformFee)
HWMPPSUpdated(uint256 newHwmPps, uint256 previousPps, uint256 profit, uint256 feeCollected)
VaultFeeConfigProposed / VaultFeeConfigUpdated / FeeRecipientChanged(...)
```

### Session keys — emitter: **executor** (singleton), keyed by controller
```solidity
SessionKeyGranted(address indexed controller, address indexed sessionKey, uint256 expiry,
                  address indexed grantedByManager, uint80 generation, uint16 permissions)  // permissions = bitmask
SessionKeyRevoked(address indexed controller, address indexed sessionKey)
AllSessionKeysInvalidated(address indexed controller, uint80 newGeneration)
```

## 4. Enums to decode

- **DepositApprovalMode:** `0 Open · 1 Allowlist · 2 ManagerApproved · 3 KycApproved`
- **ApprovalStatus:** `0 None · 1 Approved · 2 Rejected · 3 Revoked`
- **NAVProposalStatus:** `0 None · 1 PendingAttestation · 2 ReviewRequired · 3 Finalized · 4 Canceled`
- **SessionKey `permissions`** = uint16 bitmask, `bit = 1 << enumValue`: `0 ExecuteCalls · 1 FulfillDeposits · 2 ManageApprovals · 3 FulfillRedeem · 4 FulfillCancelRedeem · 5 SkimFee · 6 ProposeNAV · 7 Pause · 8 Unpause`

## 5. Critical semantics — get these right

- **PPS/NAV units:** scaled to **asset decimals** (`10**assetDecimals == 1.0`). Initial PPS = 1.0. Read current via `aggregator.getPPS(controller)`.
- **`nav_mode` is always `"attested_manual"`** (aggregator `NAV_MODE()`, controller `navMode()`). **Every NAV/PPS read the backend exposes must carry `nav_mode`** — downstream must never render manager-proposed NAV as validator-attested PPS (spec 6.8).
- **A deviation breach is not a finalized NAV.** `NAVReviewRequired` + `ManagedNAVDeviationExceeded` + `ManagedVaultPaused` + `ManagedVaultNAVStale` means the value was **dropped**; the proposal sits in `ReviewRequired` until an explicit unpause + `resolveLargeDeviationNAV`. Don't treat `proposedPPS` as the vault's NAV.
- **Freshness:** `aggregator.isNAVStale(controller)`, `getLastUpdateTimestamp`, `getMaxStaleness`. Spec 6.4 also wants **NAV drift over time**, not just per-update deltas — derive from the `ManagedNAVUpdated` series.
- **NAV lifecycle lives on the aggregator, keyed by controller** (it was relocated there from the controller during development). All `NAV*` events come from the aggregator.
- **`metadataURI` and `kycRef` are event-only** — no onchain storage/getter. Source "latest metadataURI" from `ManagedVaultConfigRegistered` (creation) + `MetadataURIUpdated`. The URI points to offchain content (IPFS etc.) — index the URI, not the content.
- **Timelocked changes** emit a `*Proposed` → `*Updated`/`*Changed` (or `*Cancelled`) pair, each with an `effectiveTime`. Model "pending change + eta" for deviation threshold, min update interval, attestor config, and primary manager.
- **Manager/attestor changes invalidate in-flight NAV.** On a primary-manager change or an attestor-set swap, any active proposal is cancelled (`NAVProposalCanceled`) and pending attestor config cleared — reflect that in queues.

## 6. Do NOT index / not onchain

- **Redemption policy** (notice periods, windows) — intentionally not in the contracts for v1; it's a manager/offchain concern.
- **KYC PII** — only `bytes32` reference hashes are onchain.
- **metadataURI content** — offchain.

## 7. Suggested entities + the open Erebor-vs-Persephone split

Entities (spec §8): `ManagedVault`, `ManagedVaultPolicy`, `ManagedVaultNavProposal`/`NavUpdate`, `ManagedVaultApproval`, `ManagedVaultDepositRequest`, `ManagedVaultRedemptionRequest`, `ManagedVaultExecution`, `ManagedVaultRoleAssignment`/`SessionKey`, `ManagedVaultAuditEvent` (unified chronological log — every event above with `{timestamp, actor, txHash, human-readable summary}`).

**The Erebor vs Persephone decision is explicitly left open in spec §8** — that's for the two repo owners to settle. A reasonable default division, if it helps decide:
- **Erebor (operational API for Superman):** the live operate-console needs — deposit/redemption/approval queues, the active NAV proposal + attestation state, current policy (deposit/execution/fee/roles), pause state, and the audit log. "Current state + pending actions."
- **Persephone / datamat (normalized analytics/history):** NAV history + drift series, TVL/AUM time series (labeled manager-NAV-derived), fee history, execution history. "Time series over the event stream."

v2-periphery events are the source of truth for all onchain actions either way; nothing here dictates the split.
