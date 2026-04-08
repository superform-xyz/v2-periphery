# Security Analysis Report

## Metadata
- **Target:** `src/oracles/MorphoBorrowCostOracle.sol`, `src/oracles/MorphoLendYieldSourceOracle.sol`
- **Mode:** review
- **Date:** 2026-04-02
- **Contract Types Detected:** Oracle (read-only wrappers around Morpho Blue singleton)
- **Files Analyzed:** 2 (+ 4 dependencies reviewed)
- **Analysis Agents:** Vulnerability Scanner, Best Practices, EVM Security Researcher

## Summary
| Severity | Count | Blocks Merge |
|----------|-------|-------------|
| P0 Critical | 0 | Yes |
| P1 High | 0 | Yes |
| P2 Medium | 2 | No |
| P3 Low | 6 | No |

## Verdict
**PASS** - No P0 or P1 findings. Safe to proceed. Two P2 medium findings should be evaluated before merge.

---

## P0 Findings (Critical - Must Fix)

None found.

## P1 Findings (High - Must Fix)

None found.

---

## P2 Findings (Medium - Should Fix)

### [P2-1] Stale market data -- accrued interest not reflected in oracle readings

- **File:** `MorphoBorrowCostOracle.sol:146`, `MorphoLendYieldSourceOracle.sol:145`
- **SWC:** N/A
- **Category:** Oracle / Stale Data
- **Description:** Both oracles call `MORPHO.market(marketId)` to read `totalSupplyAssets`, `totalSupplyShares`, `totalBorrowAssets`, and `totalBorrowShares`. As documented in Morpho's `IMorpho.sol`, these values do **not** include interest accrued since the last `accrueInterest()` call. Morpho's `_accrueInterest` is only triggered by state-changing operations (`supply`, `withdraw`, `borrow`, `repay`, `liquidate`).

  For the **BorrowCostOracle** -- which states "all asset conversions round UP (conservative debt estimation)" -- stale data actually **understates** debt, undermining the contract's design goal. For the **LendYieldSourceOracle**, stale data undervalues supply positions.

  In active markets the staleness is typically seconds to minutes. In low-activity markets it could be hours or days -- material for accounting in SuperLedger.

- **Exploit Scenario:** A market has a 10% APR borrow rate and no interactions for 24 hours. The oracle underreports borrow cost by ~0.027%. Over a week with no interactions, the underreport reaches ~0.19%. Accounting systems relying on this oracle for debt valuation would systematically undervalue debt positions. An attacker who understands this could time withdrawals or accounting snapshots to periods of maximum staleness.

- **Real-World Precedent:** The dTRINITY exploit ($257K, March 2025) demonstrated how share accounting divergence from actual assets can be exploited. While Morpho's internal accounting is formally verified, the oracle layer introduces the staleness gap.

- **Vulnerable Code:**
  ```solidity
  // MorphoBorrowCostOracle.sol:146
  (,, uint128 totalBorrowAssets, uint128 totalBorrowShares,,) = MORPHO.market(marketId);

  // MorphoLendYieldSourceOracle.sol:145
  (uint128 totalSupplyAssets, uint128 totalSupplyShares,,,,) = MORPHO.market(marketId);
  ```

- **Secure Pattern:** Use Morpho's `MorphoBalancesLib` (specifically `expectedTotalSupplyAssets()` / `expectedTotalBorrowAssets()`) which computes interest-adjusted values off-chain in view functions. Alternatively, document this as a known limitation and ensure SuperLedger callers invoke `MORPHO.accrueInterest(marketParams)` before reading the oracle.

  ```solidity
  // Option A: Use MorphoBalancesLib (recommended)
  import { MorphoBalancesLib } from "morpho-blue/libraries/periphery/MorphoBalancesLib.sol";
  using MorphoBalancesLib for IMorpho;

  function getPricePerShare(address yieldSourceId) public view override returns (uint256) {
      Id marketId = _getMarketId(yieldSourceId);
      (address loanToken,,,,) = MORPHO.idToMarketParams(marketId);
      uint256 loanDecimals = IERC20Metadata(loanToken).decimals();

      uint256 totalBorrowAssets = IMorpho(address(MORPHO)).expectedTotalBorrowAssets(marketParams);
      uint256 totalBorrowShares = /* corresponding expected shares */;

      return (10 ** loanDecimals).toAssetsUp(uint128(totalBorrowAssets), uint128(totalBorrowShares));
  }
  ```

  ```solidity
  // Option B: Document as known limitation (pragmatic)
  /// @dev WARNING: Values may be stale if market hasn't been interacted with recently.
  ///      Callers requiring fresh data should call MORPHO.accrueInterest(marketParams)
  ///      in the same transaction before reading this oracle.
  ```

- **Reference:** Morpho Docs -- Interest Rates; IMorpho.sol lines 22-25 warning comments

---

### [P2-2] No uniqueness check on marketId allows multiple yieldSourceIds to map to the same market

- **File:** `MorphoBorrowCostOracle.sol:101-113`, `MorphoLendYieldSourceOracle.sol:101-113`
- **SWC:** N/A
- **Category:** Logic / Registration
- **Description:** `registerMarket` checks that a `yieldSourceId` is not already registered, but does **not** check whether the computed `marketId` is already mapped by a different `yieldSourceId`. A MANAGER_ROLE holder can register multiple different `yieldSourceId` addresses that all point to the same Morpho market. This could lead to:
  1. TVL double-counting if SuperLedger aggregates across yieldSourceIds without deduplication
  2. Confusion when different identifiers reference the same underlying market
  3. False sense of removal when one yieldSourceId is unregistered but another remains

  The E2E test `test_registerMarket_secondYieldSourceId` confirms this is tested/known behavior. If intentional, this should be explicitly documented. If not intentional, it should be guarded.

- **Exploit Scenario:** A compromised MANAGER_ROLE registers the same Morpho WETH/USDC market under 10 different yieldSourceIds. TVL aggregation in SuperLedger counts each one separately, inflating reported TVL by 10x.

- **Vulnerable Code:**
  ```solidity
  function registerMarket(address yieldSourceId, MarketParams calldata params) external onlyRole(MANAGER_ROLE) {
      if (yieldSourceId == address(0)) revert ZERO_ADDRESS();
      if (Id.unwrap(marketIds[yieldSourceId]) != bytes32(0)) revert MARKET_ALREADY_REGISTERED();

      Id marketId = MarketParamsLib.id(params);
      // No check: is marketId already registered under a different yieldSourceId?

      (,,,, uint128 lastUpdate,) = MORPHO.market(marketId);
      if (lastUpdate == 0) revert MARKET_DOES_NOT_EXIST();

      marketIds[yieldSourceId] = marketId;
      emit MarketRegistered(yieldSourceId, marketId);
  }
  ```

- **Secure Pattern:** If uniqueness is desired, add a reverse mapping:
  ```solidity
  mapping(Id marketId => address yieldSourceId) public registeredMarkets;
  error MARKET_ID_ALREADY_REGISTERED();

  function registerMarket(address yieldSourceId, MarketParams calldata params) external onlyRole(MANAGER_ROLE) {
      // ... existing checks ...
      Id marketId = MarketParamsLib.id(params);
      if (registeredMarkets[marketId] != address(0)) revert MARKET_ID_ALREADY_REGISTERED();

      // ... existing validation and assignment ...
      registeredMarkets[marketId] = yieldSourceId;
  }
  ```

  If multiple mappings to the same market is intentional, add a NatSpec comment:
  ```solidity
  /// @dev Multiple yieldSourceIds may intentionally point to the same Morpho market.
  ///      Callers must handle deduplication when aggregating TVL across yieldSourceIds.
  ```

---

## P3 Findings (Low - Consider Fixing)

### [P3-1] No validation that `superLedgerConfiguration_` is not `address(0)` in constructor

- **File:** `MorphoBorrowCostOracle.sol:85`, `MorphoLendYieldSourceOracle.sol:85`
- **SWC:** N/A
- **Category:** Input Validation
- **Description:** Both constructors validate `morpho_` and `admin_` but not `superLedgerConfiguration_`. If deployed with zero address, `getAssetOutputWithFees` (inherited from `AbstractYieldSourceOracle`) would silently disable fee calculations via its try/catch fallback.
- **Secure Pattern:**
  ```solidity
  if (morpho_ == address(0) || superLedgerConfiguration_ == address(0) || admin_ == address(0)) {
      revert ZERO_ADDRESS();
  }
  ```

### [P3-2] `IERC20Metadata.decimals()` external call may revert for non-compliant tokens

- **File:** `MorphoBorrowCostOracle.sol:136`, `MorphoLendYieldSourceOracle.sol:136`
- **SWC:** N/A
- **Category:** Token Integration / DoS
- **Description:** `decimals()` and `getPricePerShare()` call `IERC20Metadata(loanToken).decimals()` on every invocation. If a token doesn't implement `decimals()` (optional per EIP-20) or is an upgradeable token that removes it, both functions revert permanently for that market. Mitigated by MANAGER_ROLE gating and Morpho's standard token requirements.
- **Secure Pattern:** Cache decimals at registration time to eliminate repeated external calls and protect against token upgrades:
  ```solidity
  mapping(address yieldSourceId => uint8 cachedDecimals) public yieldSourceDecimals;

  // In registerMarket():
  yieldSourceDecimals[yieldSourceId] = IERC20Metadata(params.loanToken).decimals();

  // In decimals():
  function decimals(address yieldSourceId) external view override returns (uint8) {
      _getMarketId(yieldSourceId); // validate registration
      return yieldSourceDecimals[yieldSourceId];
  }
  ```

### [P3-3] Missing rounding-direction NatSpec on `MorphoLendYieldSourceOracle`

- **File:** `MorphoLendYieldSourceOracle.sol:139-140`
- **SWC:** N/A
- **Category:** Code Quality
- **Description:** `MorphoBorrowCostOracle.getPricePerShare` has explicit `@dev` documenting rounding direction. `MorphoLendYieldSourceOracle.getPricePerShare` and `getAssetOutput` lack equivalent documentation, despite using `toAssetsDown`. Inconsistent documentation for symmetrical contracts.
- **Secure Pattern:**
  ```solidity
  /// @inheritdoc AbstractYieldSourceOracle
  /// @dev Rounds DOWN -- supply PPS is conservative for protocol accounting (favors protocol)
  function getPricePerShare(address yieldSourceId) public view override returns (uint256) {
  ```

### [P3-4] Code duplication between contracts -- opportunity for shared base

- **File:** Both contracts in their entirety
- **SWC:** N/A
- **Category:** Code Quality / Maintainability
- **Description:** ~120 lines are identical between the two contracts: state variables, events, errors, constructor, `registerMarket`, `unregisterMarket`, `decimals`, `_getMarketId`. Only the oracle-direction-specific math functions differ. An `AbstractMorphoOracle` base contract would reduce maintenance surface and ensure changes are applied consistently.
- **Secure Pattern:** Extract shared logic into `AbstractMorphoOracle` base, leaving only the 7 direction-specific functions in each concrete contract.

### [P3-5] Empty market edge cases return misleading values

- **File:** Both contracts' `getPricePerShare()` and `getAssetOutput()`
- **SWC:** N/A
- **Category:** Logic / Edge Cases
- **Description:** When a market is empty (`totalAssets = 0`, `totalShares = 0`), SharesMathLib's virtual offsets (`VIRTUAL_SHARES = 1e6`, `VIRTUAL_ASSETS = 1`) prevent division by zero but produce technically valid yet semantically meaningless PPS values. For a 6-decimal token with zero supply: `1e6 / 1e6 = 1` (0.000001 USDC per share). For 18-decimal: `1e18 / 1e6 = 1e12`. These could confuse downstream accounting.
- **Secure Pattern:** Consider documenting expected behavior for empty markets, or adding a `totalBorrowShares > 0` / `totalSupplyShares > 0` guard in `getPricePerShare()`.

### [P3-6] Redundant external calls in `getPricePerShare` -- gas optimization

- **File:** `MorphoBorrowCostOracle.sol:141-148`, `MorphoLendYieldSourceOracle.sol:140-147`
- **SWC:** N/A
- **Category:** Gas Optimization
- **Description:** `getPricePerShare` makes 3 external calls per invocation: `MORPHO.idToMarketParams()`, `IERC20Metadata.decimals()`, and `MORPHO.market()`. Caching decimals at registration (as in P3-2's fix) would reduce this to 1 external call + 1 SLOAD.

---

## Attack Surface Summary

- **External Entry Points:** `registerMarket` (MANAGER_ROLE), `unregisterMarket` (MANAGER_ROLE), `decimals`/`getPricePerShare`/`getAssetOutput`/`getShareOutput`/`getWithdrawalShareOutput`/`getBalanceOfOwner`/`getTVLByOwnerOfShares`/`getTVL` (all view, permissionless)
- **Value Transfer Points:** None -- purely read-only oracle contracts
- **Oracle Dependencies:** Morpho Blue singleton (`MORPHO.market()`, `MORPHO.position()`, `MORPHO.idToMarketParams()`), ERC20 loan tokens (`IERC20Metadata.decimals()`)
- **Cross-Contract Interactions:** Morpho Blue core (formally verified with Certora), ERC20 loan tokens
- **Upgrade Mechanisms:** None -- non-upgradeable contracts with immutable state

## Security Knowledge Sources
- **Morpho Blue formal verification:** Certora-verified reentrancy safety, accounting correctness
- **Morpho Blue audit history:** Cantina competition (Jan 2024), Spearbit audit
- **Real-world Morpho exploits referenced:** PAXG/USDC oracle misconfiguration ($230K, Oct 2024), frontend vulnerability ($2.6M, Apr 2025, white-hat intercepted) -- both in periphery/frontend, core unaffected
- **General patterns checked:** Read-only reentrancy (not applicable -- Morpho formally verified), flash loan oracle manipulation (mitigated by proportional share minting), ERC4626 inflation attacks (mitigated by virtual offsets), interest accrual staleness (primary finding)
- **OWASP Smart Contract Top 10 (2025):** SC02 Price Oracle Manipulation (checked), SC06 Access Control Vulnerabilities (checked)
