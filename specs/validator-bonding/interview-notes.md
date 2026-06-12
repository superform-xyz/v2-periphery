# ValidatorBonding Interview Notes

## Source
Interview conducted iteratively during spec development. Requirements gathered from:
- Product requirements (Slack discussion with team)
- [SIP-6 forum discussion](https://superform.discourse.group/t/sip-6-establish-validator-bonding-requirements/25/3)
- [Blog post: Become a SuperVault Validator](https://blog.superform.xyz/2026/05/05/become-a-supervault-validator/)
- Code review of existing spec (validator-bonding-v1.md)
- Detailed spec review identifying 10 critical issues and 5 design questions

## Key Decisions

### Scope
- **Base-only** deployment (no cross-chain at launch)
- **sUP token** bonding (not UP — avoids confusion with "staking UP to get sUP")
- **Non-upgradeable** — manual migration for V2 (5-10 validators at launch)
- **No automated disputes** — slashing is admin-governed via SuperGovernor
- **No oracle integration** — standalone bonding module, SuperGovernor still manages validator set

### Architecture
- ValidatorBonding is standalone — no on-chain coupling to ECDSAPPSOracle
- Slashing + validator removal happens atomically via SuperGovernor multicall
- Off-chain tooling cross-references bonded operators with oracle validator set

### Beneficiary Separation (Foundation Loans)
- `operator` = entity running the validator
- `beneficiary` = who gets sUP back on unbond (Foundation for loans)
- `beneficiary` is **immutable** after first bond
- `bondFor()` reverts if operator already has a bond (prevents beneficiary overwrite)

### Unbonding
- Both operator and beneficiary can initiate unbonding
- `cancelUnbond()` restricted to initiator only (prevents cancel-griefing)
- `unbondingDeadline` stored as absolute timestamp (not start time + period)
- 7-day unbonding period, configurable by governor

### Slashing
- Proportional across bonded and unbonding portions: `slashFromUnbonding = amount * unbondingAmount / bond.amount`
- Slash below minimumBond (but not zero) sets status = Unbonded, removes from registry
- No permanent exclusion — re-bonding requires `bond()` + re-addition to `setValidatorConfig()`
- `recipient` in `slash()` is caller-specified (intentional — GOVERNOR_ROLE directs funds)

### Parameters
- minimumBond = 1,000,000e18 (1M sUP)
- unbondingPeriod = 7 days
- DEFAULT_ADMIN_ROLE = Superform Foundation multisig
- GOVERNOR_ROLE = SuperGovernor address

### Delegation / LST (Deferred)
- The `bondFor()` + `beneficiary` pattern supports a future wrapper contract
- Wrapper would accept delegated sUP, bond on behalf of validator, mint receipt token
- Out of scope for V1 — architecture is validated as sufficient

### Security Assumptions
- sUP is the share token of a SuperVault (asset = UP), behaves as standard ERC20 for transfers
- delegateKey uniqueness NOT enforced on-chain (off-chain tooling detects)
- Zero-address validation required on all address params
