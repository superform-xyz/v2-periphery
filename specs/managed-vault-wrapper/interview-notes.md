# Interview Notes — Managed Vault Wrapper

**Date:** 2026-07-10
**Interviewer:** Claude Code
**Feature:** Managed Vault Wrapper

---

## Summary

Managed Vaults is a new vault type within SuperformOS for portfolio managers who need:
- **Async ERC-7540 deposit/redeem rails** (not instant ERC-4626)
- **Manual/attested NAV updates** (manager calls updatePPS directly)
- **Optional investor allowlist** (per-vault configurable)
- **No full SuperVault strategy engine** (no strategy, no epoch-based rebalancing)

The architecture avoids forking the SuperVault family (SuperVault, SuperVaultStrategy, SuperVaultAggregator) by introducing two new components:
1. **`ManagedECDSAAppsOracle`** — replaces the existing `ECDSAPPSOracle` as `_activePPSOracle` in SuperGovernor
2. **`ManagedVaultWrapper`** — a standalone ERC-7540 vault that wraps SuperVault shares

---

## Q&A Transcript

### Round 1

**Q: What is the core user-facing product?**
A: Manager attests NAV; investors deposit/redeem async (ERC-7540). Manager calls `updatePPS(strategy, value)` with any attested value. Investors submit deposit/redeem requests which the manager or keeper fulfills in batches.

**Q: What does ManagedVaultWrapper hold / invest into?**
A: **SuperVault shares** as the underlying asset. The wrapper holds shares of an existing SV strategy. NAV is still manager-attested (not auto-derived from SV PPS).

**Q: Should ManagedECDSAAppsOracle replace ECDSAPPSOracle entirely or run alongside?**
A: **Replace entirely** — ManagedECDSAAppsOracle becomes the single `_activePPSOracle`. It handles both:
  - Automated ECDSA path (existing signers → `forwardPPS` for regular SV strategies)
  - Manual attestation path (`updatePPS(strategy, value)` for managed vault strategies)

**Q: Investor gating model?**
A: **Configurable at vault creation** — factory param `isGated bool`. Gated vaults require manager-signed allowlist entries before deposits are accepted.

### Round 2

**Q: NAV attestation flow?**
A: **Single-call** — manager calls `updatePPS(strategy, value)` directly, no timelock/delay. Rationale: the manager is a trusted party (whitelisted by governor); adding a delay creates UX friction without meaningful protection since the manager already controls when to fulfill requests.

**Q: Manager execution capabilities?**
A: **NAV update only** — no arbitrary hook execution inside the wrapper. The wrapper holds SV shares; capital deployment is handled by the underlying SV strategy. Manager's only on-chain action is NAV attestation.

**Q: Which chains?**
A: **All chains where SuperVault is deployed** — Base mainnet, Optimism, Ethereum (and any future SV chains). Same factory deployment pattern.

**Q: ERC-7540 queue mechanics?**
A: **Manager/keeper fulfills manually** — similar to `SuperVaultStrategy.fulfillDepositRequests` / `fulfillRedeemRequests`. Off-chain trigger: manager or keeper bot decides when to batch-fulfill. **Verify against the PR #326 spec for exact function signatures.**

---

## Key Technical Decisions

1. **No SV family fork** — ManagedVaultWrapper is NOT a SuperVault variant. It's a new standalone contract.
2. **Oracle consolidation** — ManagedECDSAAppsOracle replaces ECDSAPPSOracle. One oracle controls all strategy pricing.
3. **NAV derivation** — even though wrapper holds SV shares, NAV is NOT auto-derived from SV PPS. Manager explicitly attests the value.
4. **ERC-7540 standard** — async deposits/redeems following the ERC-7540 spec (request → fulfill → claim pattern).
5. **Wrapper-in-wrapper design** — investor → ManagedVaultWrapper (ERC-7540) → SV shares → SuperVaultStrategy (ERC-4626-like)

---

## Open Questions

- Exact `fulfillDepositRequests` / `fulfillRedeemRequests` function signatures: verify against PR #326
- Is there a minimum deposit / dust prevention mechanism?
- How is allowlist managed — on-chain mapping or off-chain signature?
- ManagedVaultFactory: minimal proxy (clone) or full deploy?
- Fee structure inside ManagedVaultWrapper (performance fee, management fee)?
- What governor role can whitelist a strategy as "managed" in ManagedECDSAAppsOracle?

---

## Risks Identified

- **Oracle attack surface expansion**: ManagedECDSAAppsOracle is a critical singleton. A bug in the managed attestation path could affect all automated SV strategies.
- **NAV manipulation**: Single-call no-delay NAV update means manager can front-run withdrawals by submitting a lower NAV before fulfilling redeems. Mitigation: manager trust model + governor whitelisting.
- **ERC-7540 complexity**: Async pattern introduces pending state; accounting must handle pending deposits not yet converted to shares.
