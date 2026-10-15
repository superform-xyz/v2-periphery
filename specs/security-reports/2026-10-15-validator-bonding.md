# ValidatorBonding — Security Review (2026-10-15)

**Target:** `src/ValidatorBonding.sol`, `src/interfaces/IValidatorBonding.sol`
**Branch:** `fix/validator-bonding-bondfor-approval-binding`, cut from `dev` at `6a6dbfae`
**Mode:** review (inline critical-pattern scan + 3 parallel agents)
**Trigger:** external bounty finding #182 against `bondFor`, plus a request for broader review
**Prior reviews:** `2026-05-07-validator-bonding.md`, `2026-05-11-validator-bonding.md`
**Spec:** `specs/validator-bonding-v1.md`

> The contract was edited during the review as findings landed. Everything below is confirmed
> against the branch head after the final fix, `d855fbcd`. Re-run before merge if it moves again.

## Summary

| Severity | Count | Fixed here | Blocks merge |
|---|---|---|---|
| P0 Critical | 0 | — | — |
| P1 High | 2 | 1 | yes |
| P2 Medium | 3 | 2 | no |
| P3 Low | 5 | 1 | no |

**Verdict: FAIL pending one decision.** No P0. Of the two P1s, the reported `bondFor` redirect is
fixed. The second, `cancelUnbond` not being initiator-restricted, is a conflict between two prior
decisions and needs an owner, not a patch.

## Fixed in this branch

### [H-1] `bondFor` let an operator redirect a funded bond to itself — FIXED (`e2c6be0b`)
External finding #182. `bondFor` read beneficiary and delegate key from the operator-controlled
approval and checked only the bonder, so the operator could rewrite itself as beneficiary between
the lender's verification and execution. The beneficiary is immutable for the life of the bond, so
the lender could not repair it and was locked out of every unbond path.

Fixed by taking both fields as arguments and reverting `APPROVAL_MISMATCH` on any difference. This
restores the four-argument signature the spec already specified and completes the P3-2 remediation
from the May 11 review, which asked for approval fields "that the bonder must match"; only the
operator-side half had shipped.

Residual, by design: an operator that rewrites or revokes its approval makes the bonder's
transaction revert. That costs gas, not principal.

### [M-1] Registry membership could desync from bond status — FIXED (`5642a868`)
Found by the new invariant suite, not by inspection. Two paths moved a record out of `Unbonded`
without re-adding it to `_operators`, both reachable by an unprivileged operator after a partial
slash below the minimum. The escalation: request, cancel, then top back up leaves a fully
collateralised operator that `isBonded` reports as bonded but neither enumeration returns, so
validator-set and monitoring tooling silently loses it. No funds at risk; slashing is unaffected
because it addresses records directly.

Fixed at all three transition sites. The third was not reachable from an unenumerated record, but
including it makes the invariant hold by construction rather than by reachability.

### [M-2] Stale unbond deadline and initiator after a consuming slash — FIXED (`d855fbcd`)
Two gaps, both leaving a deadline on a record with no pending unbond, against the interface's own
sentinel of zero. The review found the first: a full slash consumes the bucket exactly, so the
post-decrement guard skipped the reset and the next bond inherited the dirt under a different
beneficiary. A new invariant then found the second, which the review's analysis had missed: ceil
rounding takes a small slice whole for any slash, so the bucket empties while the bond stays above
the minimum and the reset block never runs at all.

Not exploitable. `unbondingAmount` gates both consumers and `requestUnbond` always rewrites the
deadline in the same transaction, so a stale deadline could never pair with a live request. It
becomes an authorisation concern only if H-2 is resolved by gating cancel on the initiator.

### [L-1] Approval struct built positionally — FIXED (`5642a868`)
All three members are `address`, and since H-1 two of them carry the consent property, so a
transposition would compile and still pass the new equality check. Also clears a live lint hit.

### Documentation corrected
`cancelProposedChange` NatSpec claimed governor-only; the implementation requires the admin role
for the timelock key. The slash rounding comment named the wrong party.

## Open — needs a decision, not a patch

### [H-2] `cancelUnbond` is not initiator-restricted
`src/ValidatorBonding.sol`, cancel path. Either party can cancel the other's unbond, immediately
and repeatedly, while execute must wait for the deadline. The canceller therefore always gets the
last word.

This breaks the stated purpose of the beneficiary mechanism. The spec says the arrangement "ensures
the Foundation (as beneficiary) can pull back a loan without needing the operator's cooperation".
It does not. An uncooperative operator can block the lender's exit indefinitely for the cost of one
transaction per round, leaving a governance slash as the only recovery — the punishment path used
to return capital.

The conflict is documented on both sides. The spec requires initiator-only and names this exact
vector as the reason. The May 11 review's P3-4 recommended allowing both parties, which is what
shipped. A third spec still defines a `NOT_UNBOND_INITIATOR` error that does not exist.

Three options, in rough order of cost:
1. Reinstate initiator-only. Matches the spec, makes `unbondingInitiator` load-bearing, and
   reintroduces exactly the concern P3-4 raised.
2. Let each party cancel only its own request, and refuse cancel inside a short window before the
   deadline so it cannot be used purely to reset a counterparty's clock.
3. Keep the open cancel, accept that the lender's remedy is a slash, and correct all three
   documents plus drop the now-dead field.

Current behaviour is pinned by `test_cancelGriefing_counterpartyCanBlockExitIndefinitely`, which is
written to be inverted if option 1 or 2 is taken. Externally this is bounty finding #121.

### [M-3] `updateDelegateKey` has the same last-write-wins shape
The spec justifies beneficiary access as a remedy for a compromised operator key. The function is
symmetric and unbounded, so in exactly that scenario the attacker holding the operator key rotates
straight back. The documented remedy is unavailable. Either make beneficiary rotation sticky, or
correct the spec and route key containment through the oracle's own permissioned set.

### [L-2] Approvals have no expiry, nonce, or amount
A forgotten approval stays usable forever, so the approved bonder can squat the record years later
and lock the operator out of self-bonding until a full unbond completes. The operator also cannot
bind the loan size. Bounded, since the bonder pays and revocation exists, but worth closing while
the struct is open.

### [L-3] Stray sUP is permanently locked
No sweep, no upgrade path. A mis-sent transfer instead of a bond is unrecoverable. Any sweep must
be surplus-only and never able to touch bonded principal.

### [L-4] Timelocked proposals never expire, execution is permissionless
Open from P3-3. A proposal governance decided against but forgot to cancel can be executed months
later at a chosen moment. A grace window would let stale proposals lapse instead of accumulating as
live options.

### [L-5] `unbondingInitiator` is a storage slot nothing reads
Resolved either way by H-2: option 1 or 2 makes it load-bearing, option 3 means it should move to
the event.

## Checked and found sound

Reported so they are not re-raised. Reentrancy across all seven mutating externals, with CEI
holding in all four token-touching paths. No second instance of the check-against-counterparty-
controlled-state pattern behind H-1. No path lets a re-bond inherit a live unbond and skip the
cooldown. Slash proportional math preserves the unbonding-slice invariant under ceil for all inputs.
A raised minimum cannot strand an exit, because the partial floor is skipped on a full unbond.
In-flight unbonds correctly capture an absolute deadline. sUP being an appreciating share is safe by
construction: the contract never prices shares and books everything in share units. Two operational
notes rather than findings — the minimum is share-denominated so its real value drifts with price
per share, and a slash sized in dollars off-chain is exposed to the same drift between proposal and
execution.

## Test coverage added

| Suite | Before | After |
|---|---|---|
| Unit | 188 | 195 |
| Invariant | none | 8 |
| Fork | 21 | 21 |
| Full unit sweep | 1267 | 1282 |

`test/unit/ValidatorBonding.invariant.t.sol` is new. A handler random-walks the full lifecycle and
runs two adversarial actions, a `bondFor` redirect attempt and third-party writes against every
entry point. It asserts: unbonding never exceeds the bond, solvency, beneficiary immutability per
bond epoch, registry and status agreement, active-set collateralisation, the unbond-field sentinel,
and that no redirected or third-party write ever lands. Two of the three fixes in this branch were
found by it rather than by review.

## Notes

The contract is deployed at `0x557760077fE26D9699D5dB779b0883EF96519B01` on Base and carries the
pre-fix ABI. It has never been bonded and holds no sUP, so a redeploy needs no migration.

`forge fmt --check` fails on this file, and has since before this branch. Fixing it reformats the
whole contract, so it was deliberately left alone to keep these diffs reviewable.

The spec has drifted from the implementation across roughly ten areas, including two view functions
it promises that do not exist. That is the largest open piece of work and is documentation only.
