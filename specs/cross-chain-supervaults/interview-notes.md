# Cross-Chain SuperVaults - Interview Notes

**Date:** 2026-08-25
**Interviewee:** Cosmin Grigore (Superform Labs)

---

## Feature Summary

Enable SuperVaults to accept deposits from any chain and deploy yield across chains. Generic architecture that works for any vault, with FXRP (Flare) + Bizantine/Stellar as the first implementation.

**Key use cases:**
- Singular stock product that bridges to find best yield
- Sending funds to HyperCore for basis trades on equity
- Carry/leverage strategies
- FXRP vault with Stellar yield sources (Bizantine)

---

## Architecture Decisions

### Hub Chain
- **Decision:** Per-vault. Each vault chooses its own hub chain based on the underlying asset.
- FXRP vault would likely hub on Flare (where FXRP is native).
- Other vaults (USDC, etc.) could hub on Ethereum or Base.

### Stellar/Non-EVM Bridging
- **Decision:** Out of scope for SuperVaults. Bridging assets between Stellar and EVM chains is handled externally (by Bizantine or similar).
- SuperVault only needs to **account for** positions on Stellar, not bridge to them.
- This significantly simplifies scope - no non-EVM bridge adapter needed.

### OFT Share Token
- **Decision:** Not needed. No changes to share token.
- Shares remain plain ERC20Upgradeable on the hub chain.
- Users who deposit from spoke chains hold shares on the hub chain.
- Rationale: Making shares an OFT adds cross-chain total supply tracking, cross-chain redemption routing, and bridging latency for no clear benefit if shares can just live on hub.

### Cross-Chain Deposit Mechanism
- **Decision:** Reuse existing SuperExecutor intent flow.
- User signs merkle root intent on source chain.
- Bridge hook (Across/deBridge) sends assets + execution calldata to hub chain.
- SuperDestinationExecutor on hub validates signature and executes deposit into SuperVault.
- Shares mint to user's smart account on hub chain.
- No new DepositRouter contract needed - existing infra handles this.

### PPS Oracle / Multi-Chain Accounting
- **Decision:** Hybrid approach.
- **On-chain:** Position registry tracks metadata (what's deployed where, amounts, chain IDs).
- **Off-chain:** Oracle aggregates actual balances/values across all chains, computes PPS, pushes to SuperVaultAggregator.forwardPPS().

### Cross-Chain Position Registration
- **Decision:** Role-based off-chain registration.
- A privileged registrar role tracks bridge events off-chain and registers positions on-chain.
- Avoids the security problem of hooks auto-registering positions (anyone could invoke a hook to register false positions).
- The registrar is a trusted role (likely the oracle/keeper infrastructure).

### Withdrawal / Redemption Flow
- **Decision:** Liquidity buffer with manager discretion.
- Hub chain maintains some assets for immediate redemptions (buffer amount at manager's discretion).
- Redemptions that exceed the buffer go through existing ERC7540 async flow.
- Manager bridges assets back from remote chains when needed, then calls fulfillRedeemRequests().
- No enforced buffer target - manager decides how much to keep liquid.

### Cross-Chain Position Caps
- **Decision:** On-chain enforcement.
- Max percentage of AUM that can be deployed cross-chain is enforced on-chain during executeHooks().
- This prevents a manager from bridging 100% of assets off the hub chain.
- Hard cap provides tamper-proof protection.

### AUM Calculation for Cap Enforcement
- **Decision:** Separate AUM oracle.
- A dedicated AUM feed is pushed alongside PPS to avoid circular dependency.
- AUM = hub-chain assets + cross-chain position values (from oracle).
- Cap check: `crossChainPositionValue / totalAUM <= maxCrossChainAllocationBps`

### Oracle Security Model
- **Decision:** All protections layered.
  1. Existing PPS guards (deviation threshold, staleness checks) in SuperVaultAggregator
  2. Cross-chain position caps (on-chain enforcement)
  3. Multi-oracle quorum for cross-chain position values

### Integration Approach
- **Decision:** New composable contracts.
- Build `CrossChainPositionRegistry` and AUM oracle as separate contracts.
- Existing SuperVault, SuperVaultStrategy, SuperVaultAggregator remain untouched.
- New contracts compose with existing system - non-breaking.

---

## FXRP / Bizantine Specifics

### Yield Sources
- **Decision:** TBD with Bizantine.
- Need to finalize which yield sources on Stellar (and possibly EVM chains) will be used.
- SuperVault architecture is generic enough to support any combination.

### Bridge Mechanism
- Bizantine handles Stellar <-> EVM bridging externally.
- SuperVault just sees: assets left hub chain, position registered, PPS accounts for it.

---

## Security Considerations

### Position Registry Attack Vectors
- False position registration could inflate PPS, stealing from new depositors.
- Mitigation: Role-based registration with trusted registrar (not hook-based).
- Multi-oracle quorum provides additional validation.

### Cross-Chain Position Cap Enforcement
- On-chain enforcement prevents manager from draining hub chain.
- AUM oracle needed to calculate percentages without circular dependency.

### Oracle Trust Model
- Cross-chain positions inherently require more oracle trust than single-chain.
- Layered protections: PPS deviation checks + position caps + multi-oracle quorum.
- Worst case bounded by position cap (e.g., if max 50% cross-chain, oracle manipulation limited to 50% of AUM impact).

### Liquidity Buffer Risks
- No enforced buffer means manager could leave hub chain with zero liquidity.
- Position cap partially mitigates this (ensures some % stays on hub).
- Async ERC7540 flow is the fallback for illiquid scenarios.

---

## Testing Strategy
- **Decision:** Fork tests + mocked bridges.
- Fork mainnet for each chain, mock bridge message delivery.
- Test full flow with simulated cross-chain messaging.
- Unit test each new contract (position registry, AUM oracle) in isolation.

---

## New Contracts (Scoped)

1. **CrossChainPositionRegistry** - Tracks cross-chain positions with privileged registrar role
2. **CrossChainAUMOracle** (or extension to SuperVaultAggregator) - Receives AUM feed for cap enforcement
3. **Position cap guard** - Hook validation layer that checks cross-chain allocation caps

## Existing Infra Reused (No Changes)
- SuperExecutor + bridge hooks for cross-chain deposits
- SuperDestinationExecutor for receiving bridged deposits
- SuperVault + SuperVaultStrategy for core vault logic
- ERC7540 async redeem for over-buffer withdrawals
- SuperVaultAggregator.forwardPPS() for PPS updates (oracle just aggregates more data)
- Across V3 / deBridge hooks for EVM-to-EVM bridging

---

## Open Questions (Resolved)

| Question | Answer | Decided By |
|----------|--------|------------|
| Hub chain selection | Per-vault decision | Cosmin |
| Stellar bridging | External to SuperVaults | Cosmin |
| OFT for shares | Not needed | Cosmin |
| Deposit mechanism | Reuse SuperExecutor flow | Cosmin |
| Position tracking | Role-based registrar | Cosmin |
| Buffer management | Manager discretion | Cosmin |
| Position caps | On-chain enforcement | Cosmin |
| AUM for caps | Separate AUM oracle | Cosmin |
| Integration style | New composable contracts | Cosmin |
| FXRP yield sources | TBD with Bizantine | Pending |
