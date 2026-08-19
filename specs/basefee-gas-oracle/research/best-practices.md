# Best Practices — Basefee-Anchored Keeper-Gas Oracles

Source: best-practices-researcher agent, 2026-08-18.

> **Spec-author note on §4:** the agent found the Fast Gas feed live and absent from Chainlink's
> *public* deprecation list as of 2026-08-18. The team, however, has direct written notice from
> Chainlink: "It will be deprecated by or shortly after 9/2/26." Private outreach precedes the
> public list; the spec treats the notice as authoritative and the feed as end-of-life on ~Sep 2.

## 1. EIP-1559 mechanics

- Effective gas price = `min(maxFeePerGas, basefee + maxPriorityFeePerGas)`; basefee burned, tip to proposer. `basefee × multiplier + priorityConstant` mirrors the real cost structure.
- Per-block basefee movement bounded ±12.5% (`BASE_FEE_MAX_CHANGE_DENOMINATOR = 8`).
- **EIP-3198's own motivation section names this exact use case**: contracts setting poke bounties to `BASEFEE + x` or `BASEFEE * (1 + x)` "will always pay 'enough' regardless of market conditions" — the proposed formula is the canonical intended use of the opcode.
- Basefee floor: decrement rounds to 0 below ~7 wei → effective mainnet floor ~7 wei; `block.basefee == 0` unreachable in a real mainnet tx.
- **But basefee IS 0 in fee-field-less `eth_call`** (geth PR #23027; deliberate London design): off-chain reads see `answer = priorityFeeWei` only. On-chain same-tx charging unaffected. The additive tip conveniently keeps `answer > 0` even there.

## 2. Precedents

| Protocol | Formula shape | Lesson |
|---|---|---|
| Chainlink Automation (KeeperRegistry) | `tx.gasprice × gasUsed × (1+premium%) + overhead × tx.gasprice`, capped at `min(tx.gasprice, fastGas × gasCeilingMultiplier)` with staleness + fallbackGasPrice | Bound the price input; `tx.gasprice` alone is keeper-manipulable (self-dealing via absurd tip). Our basefee-anchored + governance-set tip is exactly that mitigation. |
| Gelato Relay | Off-chain fee oracle, ~10-30% real-world markup; historically capped executor-billed gas price via Chainlink gas oracles | 1.0x multiplier empirically too tight for third-party keepers; 1.1-1.3x is observed reality (for protocol-run keepers 1.0x acceptable). |
| MakerDAO Liquidations 2.0 | Flat `tip` (DAI) + `chip` (% of debt); no gas indexing | Flat incentives overpay in calm and underpay in spikes — the problem a basefee-indexed oracle solves. Misparameterized incentives are farming vectors (ChainSecurity audit). |
| Compound v3 `absorb` | `gasUsed × block.basefee` | **OpenZeppelin's audit flagged basefee-alone as undercounting** (misses priority fee). Our `+ priorityFeeWei` term is precisely the fix an auditor demanded elsewhere — cite in spec. |

Convergent shape across all: `price_per_gas × gas × (1+premium) + constant`. Two recurring failure modes: (a) trusting keeper-controlled price input uncapped; (b) omitting the priority-fee component.

## 3. Manipulation economics

- **Upward** (block stuffing): +12.5% costs burning basefee on ~15M extra gas; attacker gain here is 12.5% of charged gas volume. Break-even needs ~100M+ reimbursed gas in the next block — deeply irrational for a flow charging ~135k gas/update. (arXiv:2304.11478; Leonardos et al. arXiv:2012.00854 price sustained attacks in hundreds of thousands of ETH.)
- **Downward** (empty blocks): cheaper (forgone tips only) but only under-reimburses — self-griefing for a protocol-run keeper. One sentence in spec, no mitigation needed.
- **Private relays/bundles**: BASEFEE reads the inclusion block → charge is always internally consistent with cost (the key correctness property of same-tx read-and-charge; strictly better than a heartbeat-lagged pushed feed). Residual mismatch is tip only; note bundles sometimes pay via coinbase transfer (tx.gasprice − basefee ≈ 0), another reason a fixed tip beats reading tx.gasprice.
- **Multiplier calibration**: since read and charge share a tx, drift headroom is moot; the multiplier is purely a premium knob. 110-130% matches Gelato observed reality; 100% fine for a protocol-run keeper.

## 4. Chainlink Fast Gas feed status & deprecation behavior

- Verified live 2026-08-18: answer 74,160,520 wei (~0.074 gwei), updatedAt minutes old, `decimals()=0`, `description()="Fast Gas / Gwei"`, aggregator phase 5. Not yet on the public deprecation schedule (April 2026 batch was long-tail assets only). *(See spec-author note above — team has direct deprecation notice for ~9/2/26.)*
- Deprecation mechanics per Chainlink policy: announcement → data-quality monitoring ceases 2 weeks before shutdown → aggregator **stops updating**; proxy stays on-chain returning the last round forever (`updatedAt` freezes; no revert, no garbage). Staleness bound on `updatedAt` is the only signal — which SuperOracle already enforces (1 day).
- A `block.basefee`-computed adapter stamping `updatedAt = block.timestamp` is immune to the entire frozen-feed failure class — strongest single argument for the migration.
- Incumbent conformance: wei-denominated answer with `decimals()=0` despite "Gwei" name — match this exactly for drop-in compatibility.

## 5. AggregatorV3 conformance for custom adapters

- `answeredInRound` officially deprecated, but long-tail consumers still check `answeredInRound >= roundId` and `roundId != 0` → return the same nonzero value for both; `uint80(block.number)` preferred (monotonic, unique per block, supports progress checks).
- `startedAt = updatedAt = block.timestamp`; never return 0 for `startedAt` (some consumers treat 0 as round-incomplete).
- `getRoundData(uint80)`: computed oracles either revert (proxy-faithful) or return current data for any round (consumer-friendly; sibling SuperformGasOracle does this — keep consistent). Never emit decreasing roundIds.
- `decimals() = 0`, wei answer; implement `version()` (some integrators call it); `description()` human-readable — recommend `"Basefee Gas / Wei"` or similar honest string (do NOT copy "Fast Gas / Gwei" verbatim; the misleading "Gwei" name is a documented 1e9-trap).
- `answer` int256: always positive here; explicit cast keeps auditors happy.

## Synthesized recommendations

1. Keep the formula shape — canonical EIP-3198 pattern; fixes the basefee-only deficiency OZ flagged in Compound v3.
2. Document the eth_call zero-basefee behavior; off-chain consumers must pass gas-price fields for true quotes.
3. State the manipulation analysis (upward ~8x cost vs gain at realistic volumes; downward self-griefs).
4. Bound the output — every production precedent bounds its gas price input (setter bounds serve this; an answer-level cap is optional defense-in-depth).
5. Frame migration timing per the direct Chainlink notice (public list lags private outreach).
6. Round semantics: `roundId = answeredInRound = uint80(block.number)`, `startedAt = updatedAt = block.timestamp`, `decimals()=0`, implement `version()`.

Full source list preserved in the agent transcript; key: EIP-1559/EIP-3198 specs, geth PR #23027, Chainlink Automation economics + KeeperRegistry.sol, Gelato fee docs, Maker Dog/Clipper + ChainSecurity audit, Compound III + OpenZeppelin audit, arXiv 2304.11478 / 2012.00854, Flashbots MEV-1559, Chainlink deprecation policy + API reference, 0xMacro consumer guide.
