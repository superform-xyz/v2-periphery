# ValidatorBonding — Security Review (2026-10-15)

**Target:** `src/ValidatorBonding.sol`, `src/interfaces/IValidatorBonding.sol`
**Branch:** `fix/validator-bonding-bondfor-approval-binding`, cut from `dev` at `6a6dbfae`
**Mode:** review (inline critical-pattern scan + 3 parallel agents: vulnerability database,
coding standards, external exploit-precedent research)
**Trigger:** external bounty finding #182 against `bondFor`, plus a request for broader review
**Prior reviews:** `2026-05-07-validator-bonding.md`, `2026-05-11-validator-bonding.md`
**Spec:** `specs/validator-bonding-v1.md`

> The contract was edited during the review as findings landed. Everything below is confirmed
> against the branch head after the final fix, `d855fbcd`. Re-run before merge if it moves again.

## Summary

| Severity | Count | Fixed here | Blocks merge |
|---|---|---|---|
| P0 Critical | 0 | — | — |
| P1 High | 2 | 2 | yes |
| P2 Medium | 4 | 2 | no |
| P3 Low | 5 | 1 | no |

**Verdict: PASS.** No P0, and both P1s are fixed: the reported `bondFor` redirect, and the
unrestricted `cancelUnbond` that left a lender without a unilateral exit. What remains is one P2
on delegate-key rotation, one on a slash resetting a counterparty's exit clock, four P3s and three
design notes, none of which block the merge. The operational gate before any Foundation funding is
retiring the superseded deployment, not a code change.

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

### [H-2] `cancelUnbond` was not restricted, so the beneficiary had no unilateral exit — FIXED
Either party could cancel the other's unbond, immediately and repeatedly, while execute had to
wait out the cooldown. The canceller therefore always got the last word, and an uncooperative
operator could block a lender's recall indefinitely for one transaction per round. The spec says
the arrangement "ensures the Foundation (as beneficiary) can pull back a loan without needing the
operator's cooperation"; it did not.

A companion problem constrained the obvious fixes. `requestUnbond` rejects a second request while
one is pending, so a 1 wei request parks the only slot. Open cancellation was the sole escape from
that squat, which is why restricting cancellation to the initiator would have converted griefing
into a hard block, and why a no-cancel window near the deadline does not help either: neither gives
the other party a way to clear an occupied slot.

**Resolved by gating cancellation on the beneficiary alone.** The reasoning starts from
`executeUnbond`, which always pays `bond_.beneficiary` whoever requested or executed it. Both
parties' requests therefore send funds to the same address: an operator's request is a repayment, a
beneficiary's is a recall, and neither party can route money to itself by requesting. Cancelling is
consequently not a claim on the funds but a decision about whether the bond stays outstanding, and
that belongs to the payee. Gating it there closes both halves at once:

- the operator cannot veto a recall, so the beneficiary's exit is genuinely unilateral;
- a squat is survivable, since the beneficiary can clear any pending request and open its own, and
  the operator cannot clear that one back out;
- the operator keeps its repayment route, because its own request still matures and still pays the
  beneficiary, it simply cannot cancel one;
- a self-bond is unaffected, the two addresses being the same.

Reverts `NOT_BENEFICIARY`. This supersedes two earlier positions: the original initiator-only rule,
and P3-4 from the 2026-05-11 review which broadened cancellation to either party. Externally this
was bounty finding #121.

## Open — needs a decision, not a patch

### [M-3] `updateDelegateKey` has the same last-write-wins shape
The spec justifies beneficiary access as a remedy for a compromised operator key. The function is
symmetric and unbounded, so in exactly that scenario the attacker holding the operator key rotates
straight back. The documented remedy is unavailable. Either make beneficiary rotation sticky, or
correct the spec and route key containment through the oracle's own permissioned set.

### [M-4] A slash across the minimum resets the counterparty's exit clock
When a slash drops the bond below the minimum, the pending unbond is cancelled outright. A
beneficiary six days into a seven-day exit loses the whole period to a partial slash of the
operator's bond, and governance can reset any exit clock at will by slashing one wei past the
margin. Preserving the deadline and scaling the pending amount down would match how the residual
state is handled everywhere else. Raised by the external-precedent agent; not previously reported.

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
Now definitively dead: H-2 gates cancellation on the beneficiary rather than the initiator, so
nothing on-chain will ever read this field. Dropping it saves a slot and roughly 20k gas per
`requestUnbond`, and the initiator is better carried on `UnbondRequested` for observability. Left
in place here because removing a struct field changes the storage layout and is worth its own
change rather than riding along with a security fix.

## Design notes, not defects

**The minimum bond is denominated in appreciating shares.** The threshold is a count of sUP, which
is a vault share whose value floats. Upward drift raises the real entry barrier with no governance
action and grandfathers existing cohorts. Downward drift is the dangerous half: if the vault takes a
loss, the economic security behind every validator shrinks, nothing changes state, nothing is
emitted, and the bonded check keeps passing. Lido's community staking module splits exactly this —
the bond is *held* in shares so the operator earns the yield, while the *requirement* is denominated
in the underlying and reconciled continuously. Worth a decision, either denominating the requirement
in UP or running an off-chain monitor on the converted value. Note that converting on-chain would
introduce a share-price read, which is its own well-documented hazard class and must not be read
spot.

**A matured unbond request never expires.** Once the deadline passes the holder has a standing
option to exit at any future block, including the block they learn a slash is coming. This is the
previously accepted P2-3. **Correction, raised in review of PR #343:** an earlier draft of this
report argued the window is wide because the governor is a Safe whose signature collection is
public. That is wrong. The configured `GOVERNOR_ROLE` holder `0x9e01…48eC` is codeless at the
pinned block, so slashing is a single-key EOA action, not a multisig one. The admin Safe
`0x89226a5F…` is a different address, and the SuperGovernor contract is a third. The ordering risk
is real either way, but it should be argued from the actual execution path rather than an assumed
multisig delay, and a single-key slasher cuts both ways: faster to land against a maturing exit,
and a single point of compromise. A cheap freeze outside the parameter timelock would close it
without redesigning anything. Worth re-weighing the earlier acceptance in light of H-2, since the beneficiary cannot
reliably reach its own deadline either.

**Arbitrary slash recipient, uncapped, with no delay.** Documented as deliberate in the contract
header and bounded by the trusted-multisig model, so this is the shape rather than a dispute. Two
things make it worth revisiting: the latency is inverted, with a harmless parameter tweak waiting two
days while total irreversible loss is synchronous, and the admin role can grant itself the governor
role in one transaction, so the parameter timelock protects no funds.

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
| Unit | 188 | 199 |
| Invariant | none | 8 |
| Fork | 21 | 21 |
| Full unit sweep | 1267 | 1286 |

`test/unit/ValidatorBonding.invariant.t.sol` is new. A handler random-walks the full lifecycle and
runs two adversarial actions, a `bondFor` redirect attempt and third-party writes against every
entry point. It asserts: unbonding never exceeds the bond, solvency, beneficiary immutability per
bond epoch, registry and status agreement, active-set collateralisation, the unbond-field sentinel,
and that no redirected or third-party write ever lands. Two of the three fixes in this branch were
found by it rather than by review.

## On the external research agent's severity ratings

That agent rated four items P0. I have not carried those ratings across, for reasons worth
recording. Two of them, the permissionless parameter execute and the non-expiring matured unbond,
are previously reviewed and accepted items rather than new discoveries. A third, the arbitrary slash
recipient, is documented as deliberate in the contract header. The fourth is H-2, which I agree is
the most serious open item but which is a conflict between two prior decisions rather than an
unrecognised flaw. Its exploit-precedent work is genuinely valuable, but the ratings are calibrated
for an unreviewed contract and would overstate the position here. Its Safe-visibility argument,
which I repeated in an earlier draft, turned out to rest on a false premise: the slashing role is
held by an EOA, not a Safe.

One of its findings I assess as weaker than rated. It argues that topping up a bond during a pending
unbond dilutes a subsequent slash by inflating the proportional denominator. The split does move,
but the total slashed is unchanged and both buckets ultimately pay the same beneficiary, so this
shifts the timing of receipt rather than sheltering value.

## Notes

The fixed contract is deployed at `0x2466b82212f3ee3ee5FFA1b925eF5ec3Fa3c67C7` on Base.

The previous instance at `0x557760077fE26D9699D5dB779b0883EF96519B01` still carries the pre-fix
ABI and is still live. A new address does not disable the old one's public bonding functions, and
it has never been bonded and holds no sUP. Before any Foundation funding, repoint addresses, ABI
consumers and any prepared multisig payloads together, and reject the old address explicitly in
funding and enrolment tooling. The selector moves from `bondFor(address,uint256)` `0xc105a332` to
`bondFor(address,uint256,address,address)` `0xa193c110`. Note that per-operator approvals on the
old instance are not enumerable, so their absence cannot be proven from chain state.

`forge fmt --check` fails on this file, and has since before this branch. Fixing it reformats the
whole contract, so it was deliberately left alone to keep these diffs reviewable.

The spec has drifted from the implementation across roughly ten areas, including two view functions
it promises that do not exist. That is the largest open piece of work and is documentation only.
