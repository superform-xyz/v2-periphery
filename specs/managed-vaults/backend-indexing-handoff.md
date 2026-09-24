# Managed Vaults — Backend Indexing Handoff (reuse architecture)

**Source of truth:** this repo (`v2-periphery`), `src/ManagedSuperVault/` + `src/interfaces/ManagedSuperVault/`.

**Architecture note (supersedes the previous version of this doc):** Managed Vaults are no longer a from-scratch contract family. They are **minimal forks of the SuperVault family running on a second aggregator instance**, plus two new contracts. Consequence for indexing: the vault/strategy/aggregator emit **the same event signatures as the main SuperVault family** — most existing SuperVault subgraph handlers are reused as-is, and the *new* indexing surface is only the deposit queue + the NAV oracle. **Everything must be scoped by contract address (the managed aggregator and its clone set), never by event signature alone, or the two families will merge.**

## 1. Identity model (read this first)

Each Managed Vault is a **quartet of clones**: `{ vault, strategy, escrow, depositQueue }`, plus two singletons shared across all managed vaults (`aggregator`, `navOracle`).

- **`vault`** (`ManagedSuperVault`, fork of `SuperVault`) — the ERC-20 share token. Sync `deposit`/`mint` are **gated to the deposit queue**; the async ERC-7540 **redeem** side is byte-identical to the main family. Users hold NATIVE vault shares.
- **`strategy`** (`ManagedSuperVaultStrategy`, fork) — custody, hook execution, fees, redeem accounting. Identical events to the main family.
- **`escrow`** — the main family's `SuperVaultEscrow` implementation, reused unmodified (redeem-side custody only).
- **`depositQueue`** (`ManagedSuperVaultDepositQueue`, NEW, per-vault clone) — the async ERC-7540 **deposit leg**: request/fulfill/claim/cancel + deposit approval policy. Holds pending assets and pre-minted claimable shares.
- **`aggregator`** (`ManagedSuperVaultAggregator`, fork, singleton) — factory/registry + PPS store. Same rails as the main aggregator (deviation → auto-pause + stale, rate limiting, staleness); differences: PPS is pushed by the `navOracle` (not the validator oracle), no upkeep subsystem, governance functions called directly by SuperGovernor role-holders (not via the SuperGovernor contract).
- **`navOracle`** (`ManagedNAVOracle`, NEW, singleton) — the **attested-manual NAV lifecycle**, keyed by `strategy`: manager proposes (evidence hash/URI), M-of-N attestors attest, at threshold the oracle pushes into `aggregator.forwardPPS`.

Build the `vault ↔ strategy ↔ escrow ↔ depositQueue` map from `ManagedVaultDeployed`. NAV-oracle events are keyed by `strategy`; queue events are keyed by `controller` (the user). Join back to `vault` for display.

## 2. Discovery / addresses

- **Aggregator:** SuperGovernor registry under `keccak256("MANAGED_SUPER_VAULT_AGGREGATOR")` (discovery-only — unlike the main family, managed clones store their aggregator internally); also in `script/output/{prod|staging}/{chainId}/{Chain}-latest.json` as `ManagedSuperVaultAggregator`. `ManagedNAVOracle` in the same JSON; onchain via `aggregator.navOracle()`.
- **New vaults:** subscribe to `ManagedVaultDeployed(vault, strategy, escrow, depositQueue, asset, name, symbol, nonce)` on the aggregator. `getAllSuperVaults()/getAllSuperVaultStrategies()/getAllDepositQueues()/getDepositQueue(vault)` are reconciliation tools.
- **Escrow reuse caveat:** the escrow *implementation* address equals the main family's — per-vault escrow *clones* are distinct and come from `ManagedVaultDeployed`.

## 3. Event catalog (grouped by emitter)

### Aggregator (fork — same signatures as main `SuperVaultAggregator`, MUST be scoped by address)
Reused handlers: `PPSUpdated`, `PPSUpdatedAfterSkim`, `StrategyPaused`, `StrategyUnpaused`, `StrategyPPSStale`, `StrategyPPSStaleReset`, `StrategyCheckFailed` (reason `"HIGH_PPS_DEVIATION"` = deviation breach), `TimestampNotMonotonic`, `UpdateTooFrequent`, `StaleUpdate`, `StaleSignatureAfterUnpause`, `SecondaryManagerAdded/Removed`, `PrimaryManagerChanged/ChangeProposed/ChangeCancelled` (7-day timelock), `DeviationThresholdUpdated`, `MinUpdateIntervalChange*` (3-day timelock), `HighWaterMarkReset`, hooks-root events (`GlobalHooksRoot*`, `StrategyHooksRoot*`, `GlobalLeavesStatusChanged`, `HooksRootUpdateTimelockChanged`).
New (managed-only):
```solidity
ManagedVaultDeployed(address indexed vault, address indexed strategy, address escrow, address depositQueue,
                     address asset, string name, string symbol, uint256 indexed nonce)
MetadataURIUpdated(address indexed strategy, string metadataURI)   // EVENT-ONLY (no getter); also emitted at creation
NavOracleProposed(address indexed proposedOracle, uint256 effectiveTime)   // 7-day timelock
NavOracleChanged(address indexed oldOracle, address indexed newOracle)
NavOracleChangeCancelled(address indexed cancelledOracle)
```
Removed vs main family: all `Upkeep*` events (no upkeep subsystem).

### NAV oracle (NEW singleton, keyed by strategy)
```solidity
NAVProposed(address indexed strategy, uint256 indexed proposalId, uint256 previousPPS, uint256 proposedPPS,
            uint256 effectiveTimestamp, address indexed proposer, bytes32 evidenceHash, string evidenceURI)
NAVAttested(address indexed strategy, uint256 indexed proposalId, address indexed attestor, uint8 attestationCount)
NAVFinalized(address indexed strategy, uint256 indexed proposalId, uint256 finalizedPPS, uint256 timestamp)
NAVRejected(address indexed strategy, uint256 indexed proposalId, uint256 proposedPPS)   // push dropped by rails
NAVProposalCanceled(address indexed strategy, uint256 indexed proposalId, address indexed canceledBy)
NAVAttestorAdded / NAVAttestorRemoved(address indexed strategy, address indexed attestor)
NAVAttestationThresholdUpdated(address indexed strategy, uint8 threshold)
NAVAttestationConfigInitialized(address indexed strategy, address[] attestors, uint8 threshold)
NAVAttestationConfigProposed(address indexed strategy, address[] attestors, uint8 threshold, uint256 effectiveTime)
NAVAttestationConfigCancelled(address indexed strategy)   // manager cancel OR auto-cancel on manager change
```
Proposal status enum: `0 None · 1 PendingAttestation · 2 Finalized · 3 Rejected · 4 Canceled`. **There is no ReviewRequired state** (see §5, deviation runbook). The stored/canonical PPS series is the aggregator's `PPSUpdated` (+ `PPSUpdatedAfterSkim`); `NAVFinalized` is the attestation-level record.

### Deposit queue (NEW per-vault clone, keyed by controller = user)
```solidity
// ERC-7540 standard:
DepositRequest(address indexed controller, address indexed owner, uint256 indexed requestId, address sender, uint256 assets)
CancelDepositRequest(address indexed controller, uint256 indexed requestId, address sender)
CancelDepositClaim(address indexed receiver, address indexed controller, uint256 indexed requestId, address sender, uint256 assets)
Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares)   // the CLAIM (share transfer)
// queue-specific:
DepositRequestPlaced(address indexed controller, uint256 assets)
DepositRequestFulfilled(address indexed controller, uint256 assetsGross, uint256 assetsNet, uint256 shares, uint256 pps)
DepositRequestRejected(address indexed controller, uint256 assets, string reason)
DepositRequestCanceled(address indexed controller, uint256 assets)
DepositClaimed(address indexed controller, uint256 assets)
DepositPolicyUpdated(DepositApprovalMode approvalMode, bool depositsPaused, uint256 minDepositAssets, uint256 maxDepositAssets)
DepositorApproved(address indexed depositor, bytes32 kycRef)   // kycRef is a HASH, event-only, never PII
DepositorRejected / DepositorRevoked(address indexed depositor)
```
State machine: `Requested → (Fulfilled → Claimable → Claimed) | Rejected | Canceled`. `requestId` is always `0` (single-request model). Cancels are instant (never pending). Claimable is tracked in **both assets and shares**; claims are **pro-rata** (`shares = claimableShares·assets/claimableAssets`); `getAverageDepositPrice(controller)` is a derived view for price display.

### Vault + strategy (forks — same signatures as main family, reuse existing SuperVault handlers, scope by address)
Redeem lifecycle (`RedeemRequest`, `RedeemRequestPlaced/Fulfilled/Claimable/Claimed`, cancel-redeem events, `Withdraw`), fees (`ManagementFeePaid`, `PerformanceFeeSkimmed`, `HWMPPSUpdated`, `VaultFeeConfig*`, `FeeRecipientChanged`), hooks (`HooksExecuted`/`HookExecuted`), operator events (`OperatorSet`, EIP-7741) — all identical to main-family indexing.

**Fee/flow attribution (get this right):** at fulfillment the **vault** emits `Deposit(sender=depositQueue, owner=depositQueue, gross, sharesNet)` and the **strategy** emits `ManagementFeePaid`/`DepositHandled` attributed to the queue address. Treat vault-level `Deposit` where `sender == depositQueue` as **internal plumbing** — index user deposit flows from the QUEUE's events (`DepositRequest` → `DepositRequestFulfilled` → queue-level `Deposit` claim). Redeem-side flows are user-attributed as in the main family.

## 4. Enums to decode

- **DepositApprovalMode:** `0 Open · 1 Allowlist · 2 ManagerApproved · 3 KycApproved`
- **ApprovalStatus:** `0 None · 1 Approved · 2 Rejected · 3 Revoked`
- **NAVProposalStatus:** `0 None · 1 PendingAttestation · 2 Finalized · 3 Rejected · 4 Canceled`

## 5. Critical semantics — get these right

- **PPS/NAV units:** scaled to **asset decimals** (`10**assetDecimals == 1.0`). Initial PPS = 1.0. Read via `aggregator.getPPS(strategy)`. `vault.totalAssets()` = `totalSupply × PPS`, so existing ERC-4626 stats paths remain valid.
- **`nav_mode` is `"attested_manual"`** (`navOracle.NAV_MODE()`). Any manager/user-facing NAV render must be distinguishable from validator-attested PPS (spec 6.8) — the labeling lands on whichever layer feeds the frontend.
- **NAVRejected ≠ NAV update.** The proposed value was **dropped** by the aggregator rails. Determine why from the paired aggregator event in the same tx (`StrategyCheckFailed("HIGH_PPS_DEVIATION")` + `StrategyPaused` + `StrategyPPSStale` = deviation breach; `TimestampNotMonotonic`/`UpdateTooFrequent`/`StaleUpdate` = timing).
- **Deviation runbook (replaces ReviewRequired/resolve):** deviation breach → auto-pause + PPS stale (value dropped, proposal `Rejected`) → manager `unpauseStrategy` (`StrategyUnpaused`; PPS stays stale) → manager re-proposes with a fresh observation timestamp → attestors attest → push lands (`_forwardPPS` skips the deviation check while stale) → `PPSUpdated` + `StrategyPPSStaleReset` + `NAVFinalized`. Surface this whole sequence in the ops console.
- **Manager/attestor changes invalidate in-flight NAV lazily:** a primary-manager change doesn't emit a cancel by itself; the next `attestNAVUpdate` (or attestor-config `execute`) auto-cancels (`NAVProposalCanceled` / `NAVAttestationConfigCancelled`). Queues should treat a proposal as dead once `getMainManager(strategy)` ≠ the proposal's snapshot (view: `getNAVProposal`).
- **Freshness:** `aggregator.isPPSStale(strategy)`, `getLastUpdateTimestamp`, `getMaxStaleness`; the strategy's `ppsExpiration` (default 1 day, **hard cap 1 week**) gates deposits/fulfills — **operating requirement: NAV attested at least weekly** (typically at the vault's configured cadence).
- **Timelocked changes** (`*Proposed` → `*Changed`/`*Updated` or `*Cancelled`, model "pending + eta"): attestor config (3d, on navOracle), NAV oracle swap (7d, on aggregator), primary manager (7d), min update interval (3d), **deviation threshold (3d — `DeviationThresholdChangeProposed`/`DeviationThresholdUpdated`/`DeviationThresholdChangeCancelled`, managed-only; the main family's instant setter does not exist here)**, fee config (1w, on strategy), hooks roots (15min default).
- **Deviation threshold** is main-manager-proposed behind the 3-day timelock and **capped to (0, 1e18]** — it can never be disabled. Pending proposals are cleared on a primary-manager change.
- **Unpause is main-manager-only** in the managed family (any manager may pause). Unpausing arms the stale-skip that lets a large-deviation NAV land, so the elevation is deliberate — don't treat a secondary manager's failed unpause as a bug.
- **`metadataURI` and `kycRef` are event-only** — no onchain storage/getter.
- **Sync-deposit gating:** direct `vault.deposit`/`mint` reverts for anyone but the queue; `vault.maxDeposit(anyone-but-queue) == 0`. Don't flag these as anomalies.

## 6. Do NOT index / not onchain

- **Redemption policy** (notice periods/windows) — intentionally not in contracts for v1.
- **KYC PII** — only `bytes32` hashes onchain.
- **metadataURI content** — offchain; index the URI only.
- **Upkeep** — does not exist in the managed family.

## 7. Where the work lands

Same four lanes as before, but the indexing lane shrinks substantially because the family reuses main-family events:

- **subgraphs-monorepo/v2-periphery** — extend the existing SuperVault subgraph: new dataSources for the **managed aggregator** + **navOracle** singletons; a **queue template** instantiated per `ManagedVaultDeployed`; vault/strategy handled by the **existing SuperVault templates** instantiated for managed clone addresses (scoped by the managed aggregator's registry). Goldsky sinks mirror hot entities as today. **Still the gating lane.**
- **supervaults-data-pipeline** — NAV/PPS history + drift (from `PPSUpdated` series), flows, TVL, fee history, pending-request reconcilers; redeem side reuses the existing `supervault_redeem_requests` machinery pointed at managed addresses.
- **erebor** — Superman console API: deposit/approval queues, active NAV proposal + attestation state, pending timelocked changes, pause/policy/fee views, audit log. **No keepers in v1** (fulfillment is manager-initiated). Note: no session keys in v1 (the managed executor was dropped; revisit for v2 keeper automation).
- **persephone/datamat** — consumer-app lane unchanged in shape: vault-family labeling, catalog, NAV history, ERC-4626 stats via `totalAssets()`.

## 8. Deployment scope

Ethereum + Base at launch. Aggregator + navOracle are deterministic per environment; dev/staging deployments will exist for pre-prod indexing. Wiring order: deploy family → `runRegister` (sets the registry key AND wires the NAV oracle via `setInitialNavOracle`; the family is inert until then).
