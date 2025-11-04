"""
Comprehensive Skim Fee Analysis: Integrated vs Separate

This analysis answers the key question:
  "Is it worth combining fee skimming with forwardPPS updates to nullify
   arbitrage attacks, despite increased gas costs?"

Key Insights:
- Scenario A (Current): Separate PPS updates and skims
  * Arbitrage window exists between skim and next PPS update
  * Users can deposit during this window and get inflated PPS
  * Manager can skim whenever needed (flexibility)

- Scenario B (Proposed): Integrated PPS + skim
  * ELIMINATES arbitrage window (PPS drops immediately with skim)
  * Forces skim on EVERY PPS update (24x/day if hourly updates)
  * Saves gas per skim (21k base tx + warm storage ~8k)
  * BUT costs more total (many more skims)

The Analysis:
  Net Benefit = Fees Captured - Arbitrage Loss - Gas Costs

  We model:
  1. Gas costs from PPS updates (ECDSAPPSOracle -> Aggregator -> forwardPPS)
  2. Gas costs from skimming (SuperVaultStrategy.skimPerformanceFee)
  3. Arbitrage from strategic deposit timing (deposit after skim during stale PPS window)

Author: Superform Labs
Usage: cd research && uv run python comprehensive_skim_analysis.py
"""

from dataclasses import dataclass
from typing import Dict, List
import numpy as np


# ============================================================================
# GAS COST CONFIGURATION (from Solidity analysis)
# ============================================================================

@dataclass
class GasCosts:
    """
    Gas costs derived from Solidity code analysis:

    PPS Update Flow (ECDSAPPSOracle.updatePPS -> SuperVaultAggregator.forwardPPS):
    - ECDSA signature recovery per validator: ~3,000 gas
    - Oracle validation logic: ~12,000 gas
    - Aggregator forwardPPS per strategy: ~55,000 gas
    - Base transaction: 21,000 gas

    Skim Flow (SuperVaultStrategy.skimPerformanceFee):
    - Separate call (cold storage): ~66,273 gas
    - Integrated call (warm storage, same tx): ~58,000 gas
    - Savings from integration: 21k (base tx) + 8k (warm storage) = 29,273 gas
    """
    # PPS Update components (per strategy)
    ecdsa_recovery_per_validator: int = 3_000
    oracle_validation: int = 12_000
    aggregator_forward_pps: int = 55_000
    base_transaction: int = 21_000

    # Skim components
    skim_cold: int = 66_273  # Separate skimPerformanceFee call
    skim_warm: int = 58_000  # Integrated skim in same transaction

    @property
    def pps_update_total(self) -> int:
        """Total gas for PPS update (oracle validation + aggregator forward)"""
        return self.oracle_validation + self.aggregator_forward_pps

    @property
    def separate_skim_total(self) -> int:
        """Total gas for separate skim transaction"""
        return self.base_transaction + self.skim_cold

    @property
    def integrated_skim_marginal(self) -> int:
        """Marginal cost to add skim to existing PPS update"""
        return self.skim_warm

    @property
    def gas_savings_per_skim(self) -> int:
        """Gas saved per skim when integrated vs separate"""
        return self.separate_skim_total - self.skim_warm


# ============================================================================
# ARBITRAGE MODEL
# ============================================================================

@dataclass
class SkimConfig:
    """Configuration for performance fee skim"""
    performance_fee_bps: int = 2000  # 20%
    superform_fee_bps: int = 500  # 5% of performance fee

    @property
    def performance_fee_pct(self) -> float:
        return self.performance_fee_bps / 10000.0

    @property
    def superform_fee_pct(self) -> float:
        return self.superform_fee_bps / 10000.0


class VaultSimulator:
    """Simulates vault behavior with skim-based performance fees"""

    def __init__(
        self,
        initial_tvl: float,
        daily_yield_pct: float,
        skim_config: SkimConfig = SkimConfig(),
    ):
        self.skim_config = skim_config
        self.daily_yield_pct = daily_yield_pct

        self.total_assets = initial_tvl
        self.total_supply = initial_tvl
        self.vault_total_cost_basis = initial_tvl

    @property
    def pps(self) -> float:
        """Price per share"""
        if self.total_supply == 0:
            return 1.0
        return self.total_assets / self.total_supply

    def apply_yield(self, hours: float) -> None:
        """Apply yield over a given number of hours"""
        days = hours / 24.0
        multiplier = (1.0 + self.daily_yield_pct / 100.0) ** days
        self.total_assets *= multiplier

    def skim(self) -> tuple[float, float, float]:
        """
        Perform a skim operation
        Returns: (pre_skim_pps, post_skim_pps, pps_drop_pct)
        """
        pre_skim_pps = self.pps
        pre_skim_assets = self.total_assets

        # Calculate profit above HWM
        profit = max(0.0, pre_skim_assets - self.vault_total_cost_basis)
        if profit <= 0:
            return (pre_skim_pps, pre_skim_pps, 0.0)

        # Calculate and transfer fees
        total_fee = profit * self.skim_config.performance_fee_pct
        self.total_assets -= total_fee

        # Reset HWM to post-skim assets
        self.vault_total_cost_basis = self.total_assets

        post_skim_pps = self.pps
        pps_drop_pct = ((pre_skim_pps - post_skim_pps) / pre_skim_pps) * 100.0

        return (pre_skim_pps, post_skim_pps, pps_drop_pct)

    def deposit(self, amount: float) -> float:
        """
        Simulate deposit and return shares received
        """
        shares = amount / self.pps
        self.total_assets += amount
        self.total_supply += shares
        self.vault_total_cost_basis += amount
        return shares


def calculate_arbitrage_from_stale_pps(
    tvl: float,
    daily_yield_pct: float,
    skim_frequency_hours: float,
    pps_update_frequency_hours: float,
    deposit_volume_pct_of_tvl: float = 200.0,  # 200% = 2x TVL deposits over year
    days_simulated: int = 365,
) -> Dict:
    """
    Calculate arbitrage profit from strategic deposit timing.

    Key insight: After a skim, PPS drops. If PPS updates happen between skims,
    those PPS values are "overstated" (don't reflect the skim). Users can
    deposit during this window and get extra shares.

    Args:
        tvl: Total value locked
        daily_yield_pct: Daily yield percentage
        skim_frequency_hours: Hours between skims
        pps_update_frequency_hours: Hours between PPS updates
        deposit_volume_pct_of_tvl: Annual deposit volume as % of TVL
        days_simulated: Number of days to simulate

    Returns:
        Dict with arbitrage calculations
    """
    # Create vault simulator
    vault = VaultSimulator(tvl, daily_yield_pct)

    # Calculate number of operations
    hours_simulated = days_simulated * 24
    num_skims = int(hours_simulated / skim_frequency_hours)
    num_pps_updates_per_skim = int(skim_frequency_hours / pps_update_frequency_hours)

    # Deposit volume
    total_deposit_volume = tvl * (deposit_volume_pct_of_tvl / 100.0)

    # Strategic depositors wait for skims, then deposit during the stale PPS window
    # We model: after each skim, strategic deposits happen at the next PPS update
    deposits_per_skim = total_deposit_volume / num_skims if num_skims > 0 else 0

    total_arbitrage = 0.0
    total_fees_captured = 0.0
    pps_drops = []

    current_hour = 0.0
    hours_since_last_skim = 0.0

    for skim_i in range(num_skims):
        # Apply yield until skim
        vault.apply_yield(skim_frequency_hours)
        current_hour += skim_frequency_hours

        # Perform skim
        pre_skim_pps, post_skim_pps, pps_drop_pct = vault.skim()
        pps_drops.append(pps_drop_pct)

        # Calculate fees captured (profit * 20%)
        profit = vault.total_assets * (vault.skim_config.performance_fee_pct / (1 - vault.skim_config.performance_fee_pct))
        fees_captured = profit * vault.skim_config.performance_fee_pct
        total_fees_captured += fees_captured

        # Model arbitrage: strategic depositors deposit right after skim
        # They get shares at post_skim_pps, but their shares will eventually
        # appreciate back to pre_skim_pps equivalent
        #
        # Arbitrage gain = extra shares received * pre_skim_pps value
        if post_skim_pps > 0 and pre_skim_pps > post_skim_pps:
            deposit_amt = deposits_per_skim

            # Shares if deposited before skim
            shares_before = deposit_amt / pre_skim_pps

            # Shares actually received after skim
            shares_after = deposit_amt / post_skim_pps

            # Extra shares gained
            extra_shares = shares_after - shares_before

            # Arbitrage value (extra shares * current PPS)
            arbitrage_gain = extra_shares * pre_skim_pps
            total_arbitrage += arbitrage_gain

            # Actually execute deposit in simulator
            vault.deposit(deposit_amt)

    avg_pps_drop_pct = np.mean(pps_drops) if pps_drops else 0.0

    return {
        "total_arbitrage_loss": total_arbitrage,
        "total_fees_captured": total_fees_captured,
        "num_skims": num_skims,
        "avg_pps_drop_pct": avg_pps_drop_pct,
        "arbitrage_pct_of_fees": (total_arbitrage / total_fees_captured * 100.0) if total_fees_captured > 0 else 0.0,
        "arbitrage_pct_of_deposit_volume": (total_arbitrage / total_deposit_volume * 100.0) if total_deposit_volume > 0 else 0.0,
    }


# ============================================================================
# SCENARIO ANALYSIS
# ============================================================================

def analyze_scenario_a(
    tvl: float,
    apy: float,
    pps_updates_per_day: float,
    skims_per_day: float,
    gas_price_gwei: float,
    eth_price_usd: float,
    gas_costs: GasCosts,
) -> Dict:
    """
    Analyze Scenario A: Separate PPS updates and fee skims

    Key characteristics:
    - PPS updates: pps_updates_per_day times (e.g., 24x/day = hourly)
    - Fee skims: skims_per_day times (e.g., 1x/day = daily)
    - Arbitrage window: Time between skim and next PPS update
    - Manager pays: PPS upkeep + skim gas
    """
    days_per_year = 365

    # Calculate daily yield from APY
    daily_yield_pct = ((1.0 + apy / 100.0) ** (1.0 / 365.0) - 1.0) * 100.0

    # Gas costs
    pps_updates_per_year = pps_updates_per_day * days_per_year
    skims_per_year = skims_per_day * days_per_year

    # PPS update gas (each needs base tx + oracle + aggregator)
    pps_gas_per_update = gas_costs.base_transaction + gas_costs.pps_update_total
    pps_gas_total = pps_updates_per_year * pps_gas_per_update

    # Skim gas (separate transaction)
    skim_gas_total = skims_per_year * gas_costs.separate_skim_total

    # Total gas
    total_gas = pps_gas_total + skim_gas_total

    # USD costs
    gas_to_usd = lambda gas: gas * gas_price_gwei * 1e-9 * eth_price_usd
    total_gas_cost_usd = gas_to_usd(total_gas)

    # Arbitrage calculation
    # Key: PPS updates happen MORE frequently than skims
    # After each skim, there are (pps_updates_per_day / skims_per_day - 1) PPS updates
    # before the next skim. During this time, PPS is "stale" (doesn't reflect skim).
    skim_frequency_hours = 24.0 / skims_per_day
    pps_update_frequency_hours = 24.0 / pps_updates_per_day

    arb_data = calculate_arbitrage_from_stale_pps(
        tvl=tvl,
        daily_yield_pct=daily_yield_pct,
        skim_frequency_hours=skim_frequency_hours,
        pps_update_frequency_hours=pps_update_frequency_hours,
        deposit_volume_pct_of_tvl=200.0,
        days_simulated=365,
    )

    # Fees captured (20% performance fee on yield)
    annual_yield = tvl * (apy / 100.0)
    fees_captured = annual_yield * 0.20  # 20% performance fee

    # Net benefit
    net_benefit = fees_captured - arb_data["total_arbitrage_loss"] - total_gas_cost_usd

    return {
        "scenario": "A (Separate)",
        "pps_updates_per_day": pps_updates_per_day,
        "pps_updates_per_year": int(pps_updates_per_year),
        "skims_per_day": skims_per_day,
        "skims_per_year": int(skims_per_year),
        "total_gas": int(total_gas),
        "gas_cost_usd_per_year": total_gas_cost_usd,
        "fees_captured_per_year": fees_captured,
        "arbitrage_loss_per_year": arb_data["total_arbitrage_loss"],
        "arbitrage_pct_of_fees": arb_data["arbitrage_pct_of_fees"],
        "net_benefit_per_year": net_benefit,
        "avg_pps_drop_pct": arb_data["avg_pps_drop_pct"],
    }


def analyze_scenario_b(
    tvl: float,
    apy: float,
    operations_per_day: float,  # Same as PPS updates (skim on every update)
    gas_price_gwei: float,
    eth_price_usd: float,
    gas_costs: GasCosts,
) -> Dict:
    """
    Analyze Scenario B: Integrated PPS updates + fee skims

    Key characteristics:
    - Combined operations: operations_per_day times (e.g., 24x/day = hourly)
    - Skim happens on EVERY operation (forced coupling)
    - NO arbitrage window (PPS drops immediately with skim)
    - Manager pays: All via upkeep
    """
    days_per_year = 365

    # Calculate daily yield from APY
    daily_yield_pct = ((1.0 + apy / 100.0) ** (1.0 / 365.0) - 1.0) * 100.0

    # Gas costs
    operations_per_year = operations_per_day * days_per_year

    # Gas per operation = base tx + PPS update + marginal skim cost
    gas_per_operation = (
        gas_costs.base_transaction +
        gas_costs.pps_update_total +
        gas_costs.integrated_skim_marginal
    )

    total_gas = operations_per_year * gas_per_operation

    # USD costs
    gas_to_usd = lambda gas: gas * gas_price_gwei * 1e-9 * eth_price_usd
    total_gas_cost_usd = gas_to_usd(total_gas)

    # Arbitrage calculation
    # Key: PPS updates AND skims happen together, so NO stale PPS window
    # Arbitrage is MINIMAL (only during same transaction, which is negligible)
    operation_frequency_hours = 24.0 / operations_per_day

    arb_data = calculate_arbitrage_from_stale_pps(
        tvl=tvl,
        daily_yield_pct=daily_yield_pct,
        skim_frequency_hours=operation_frequency_hours,  # Skim every operation
        pps_update_frequency_hours=operation_frequency_hours,  # Update every operation
        deposit_volume_pct_of_tvl=200.0,
        days_simulated=365,
    )

    # Fees captured (20% performance fee on yield)
    annual_yield = tvl * (apy / 100.0)
    fees_captured = annual_yield * 0.20  # 20% performance fee

    # Net benefit
    net_benefit = fees_captured - arb_data["total_arbitrage_loss"] - total_gas_cost_usd

    return {
        "scenario": "B (Integrated)",
        "operations_per_day": operations_per_day,
        "operations_per_year": int(operations_per_year),
        "skims_per_day": operations_per_day,  # Every operation!
        "skims_per_year": int(operations_per_year),
        "total_gas": int(total_gas),
        "gas_cost_usd_per_year": total_gas_cost_usd,
        "fees_captured_per_year": fees_captured,
        "arbitrage_loss_per_year": arb_data["total_arbitrage_loss"],
        "arbitrage_pct_of_fees": arb_data["arbitrage_pct_of_fees"],
        "net_benefit_per_year": net_benefit,
        "avg_pps_drop_pct": arb_data["avg_pps_drop_pct"],
    }


# ============================================================================
# COMPARISON AND OUTPUT
# ============================================================================

def compare_scenarios(
    tvl: float = 100_000_000.0,
    apy: float = 10.0,
    pps_updates_per_day: float = 24.0,  # Hourly
    skims_per_day_scenario_a: float = 1.0,  # Daily
    gas_price_gwei: float = 20.0,
    eth_price_usd: float = 3000.0,
) -> Dict:
    """
    Compare Scenario A vs B with comprehensive analysis
    """
    gas_costs = GasCosts()

    # Analyze both scenarios
    result_a = analyze_scenario_a(
        tvl=tvl,
        apy=apy,
        pps_updates_per_day=pps_updates_per_day,
        skims_per_day=skims_per_day_scenario_a,
        gas_price_gwei=gas_price_gwei,
        eth_price_usd=eth_price_usd,
        gas_costs=gas_costs,
    )

    result_b = analyze_scenario_b(
        tvl=tvl,
        apy=apy,
        operations_per_day=pps_updates_per_day,
        gas_price_gwei=gas_price_gwei,
        eth_price_usd=eth_price_usd,
        gas_costs=gas_costs,
    )

    # Calculate differences
    gas_diff = result_b["gas_cost_usd_per_year"] - result_a["gas_cost_usd_per_year"]
    arb_diff = result_a["arbitrage_loss_per_year"] - result_b["arbitrage_loss_per_year"]
    net_diff = result_b["net_benefit_per_year"] - result_a["net_benefit_per_year"]

    return {
        "scenario_a": result_a,
        "scenario_b": result_b,
        "comparison": {
            "extra_gas_cost_b": gas_diff,
            "arbitrage_saved_b": arb_diff,
            "net_benefit_diff": net_diff,
            "winner": "B (Integrated)" if net_diff > 0 else "A (Separate)",
        }
    }


def print_analysis(results: Dict) -> None:
    """Print comprehensive analysis results"""

    print("=" * 80)
    print("COMPREHENSIVE SKIM FEE ANALYSIS")
    print("=" * 80)

    a = results["scenario_a"]
    b = results["scenario_b"]
    comp = results["comparison"]

    print(f"\nConfiguration:")
    print(f"  TVL: ${a['fees_captured_per_year'] / 0.2 / 0.1:,.0f}")
    print(f"  APY: 10.0%")
    print(f"  PPS Update Frequency: {a['pps_updates_per_day']:.1f}x/day (hourly)")
    print(f"  Gas Price: 20 gwei @ $3,000/ETH")

    print("\n" + "=" * 80)
    print("SCENARIO A: Separate PPS Updates + Fee Skims (Current)")
    print("=" * 80)
    print(f"  PPS Updates: {a['pps_updates_per_day']:.1f}x/day ({a['pps_updates_per_year']:,}/year)")
    print(f"  Fee Skims:   {a['skims_per_day']:.1f}x/day ({a['skims_per_year']:,}/year)")
    print(f"  ")
    print(f"  Fees Captured:       ${a['fees_captured_per_year']:,.0f}/year")
    print(f"  Gas Costs:           ${a['gas_cost_usd_per_year']:,.0f}/year")
    print(f"  Arbitrage Loss:      ${a['arbitrage_loss_per_year']:,.0f}/year ({a['arbitrage_pct_of_fees']:.2f}% of fees)")
    print(f"  ")
    print(f"  NET BENEFIT:         ${a['net_benefit_per_year']:,.0f}/year")
    print(f"  ")
    print(f"  Avg PPS Drop:        {a['avg_pps_drop_pct']:.3f}%")
    print(f"  Arbitrage Window:    {24.0 / a['skims_per_day']:.1f} hours between skims")

    print("\n" + "=" * 80)
    print("SCENARIO B: Integrated PPS Updates + Fee Skims (Proposed)")
    print("=" * 80)
    print(f"  Combined Ops: {b['operations_per_day']:.1f}x/day ({b['operations_per_year']:,}/year)")
    print(f"  Fee Skims:    {b['skims_per_day']:.1f}x/day (EVERY UPDATE!)")
    print(f"  ")
    print(f"  Fees Captured:       ${b['fees_captured_per_year']:,.0f}/year")
    print(f"  Gas Costs:           ${b['gas_cost_usd_per_year']:,.0f}/year")
    print(f"  Arbitrage Loss:      ${b['arbitrage_loss_per_year']:,.0f}/year ({b['arbitrage_pct_of_fees']:.2f}% of fees)")
    print(f"  ")
    print(f"  NET BENEFIT:         ${b['net_benefit_per_year']:,.0f}/year")
    print(f"  ")
    print(f"  Avg PPS Drop:        {b['avg_pps_drop_pct']:.3f}%")
    print(f"  Arbitrage Window:    ~0 hours (PPS updates with skim)")

    print("\n" + "=" * 80)
    print("COMPARISON")
    print("=" * 80)
    print(f"  Extra Gas Cost (B vs A):         ${comp['extra_gas_cost_b']:+,.0f}/year")
    print(f"  Arbitrage Saved (B vs A):        ${comp['arbitrage_saved_b']:+,.0f}/year")
    print(f"  Net Benefit Difference (B - A):  ${comp['net_benefit_diff']:+,.0f}/year")
    print(f"  ")
    print(f"  WINNER: {comp['winner']}")

    if comp['net_benefit_diff'] > 0:
        print(f"\n  ✅ SCENARIO B IS BETTER by ${comp['net_benefit_diff']:,.0f}/year")
        print(f"     Arbitrage savings (${comp['arbitrage_saved_b']:,.0f}) outweigh extra gas (${comp['extra_gas_cost_b']:,.0f})")
    else:
        print(f"\n  ⚠️  SCENARIO A IS BETTER by ${-comp['net_benefit_diff']:,.0f}/year")
        print(f"     Extra gas costs (${comp['extra_gas_cost_b']:,.0f}) outweigh arbitrage savings (${comp['arbitrage_saved_b']:,.0f})")

    print("\n" + "=" * 80)
    print("KEY INSIGHTS")
    print("=" * 80)
    print(f"  1. Scenario B does {b['skims_per_year'] - a['skims_per_year']:,} MORE skims/year")
    print(f"     ({b['skims_per_year']:,} vs {a['skims_per_year']:,})")
    print(f"  ")
    print(f"  2. Gas savings per skim: {GasCosts().gas_savings_per_skim:,} gas")
    print(f"     (21k base tx + 8k warm storage savings)")
    print(f"  ")
    print(f"  3. Arbitrage window in Scenario A: {24.0 / a['skims_per_day']:.1f} hours")
    print(f"     During this time, PPS is 'stale' (doesn't reflect skim)")
    print(f"     Strategic depositors can exploit this for ${a['arbitrage_loss_per_year']:,.0f}/year")
    print(f"  ")
    print(f"  4. Scenario B eliminates arbitrage window entirely")
    print(f"     PPS drops immediately when skim happens")
    print(f"  ")
    print(f"  5. The trade-off:")
    print(f"     - Extra gas: ${comp['extra_gas_cost_b']:,.0f}/year")
    print(f"     - Arbitrage saved: ${comp['arbitrage_saved_b']:,.0f}/year")
    print(f"     - Net: ${comp['net_benefit_diff']:+,.0f}/year")

    print("\n" + "=" * 80)
    print("RECOMMENDATION")
    print("=" * 80)
    if comp['net_benefit_diff'] > 0:
        print("  ✅ INTEGRATE FEE SKIMMING WITH PPS UPDATES")
        print("  ")
        print("  Why?")
        print("  - Eliminates arbitrage window (saves more than gas costs)")
        print("  - Simplifies manager operations (no manual skim calls)")
        print("  - More capital efficient (no MEV opportunity)")
        print("  ")
        print("  Implementation:")
        print("  - Add skim call to SuperVaultAggregator._forwardPPS()")
        print("  - Check if profit exists before skimming")
        print("  - Use try-catch to handle skim failures gracefully")
    else:
        print("  ⚠️  KEEP SEPARATE PPS UPDATES AND FEE SKIMS")
        print("  ")
        print("  Why?")
        print("  - Gas costs outweigh arbitrage savings")
        print("  - Manager retains flexibility on skim timing")
        print("  - Simpler oracle logic (agnostic to fee logic)")
        print("  ")
        print("  Consider:")
        print("  - Increase skim frequency manually if arbitrage becomes significant")
        print("  - Monitor arbitrage activity and adjust accordingly")
        print("  - Hybrid approach: allow opt-in integration per strategy")

    print("\n")


# ============================================================================
# MAIN
# ============================================================================

def main():
    """Run comprehensive analysis across multiple TVL scenarios"""

    # Test multiple TVL scenarios to show TVL-dependent decision
    tvl_scenarios = [
        (100_000_000.0, "$100M"),
        (250_000_000.0, "$250M"),
        (500_000_000.0, "$500M"),
    ]

    all_results = []

    for tvl, tvl_label in tvl_scenarios:
        print("\n" + "=" * 80)
        print(f"ANALYZING TVL: {tvl_label}")
        print("=" * 80)

        results = compare_scenarios(
            tvl=tvl,
            apy=10.0,  # 10% APY
            pps_updates_per_day=24.0,  # Hourly PPS updates
            skims_per_day_scenario_a=1.0,  # Daily skims in Scenario A
            gas_price_gwei=20.0,
            eth_price_usd=3000.0,
        )

        print_analysis(results)
        all_results.append((tvl_label, results))

    # Summary comparison across TVLs
    print("\n" + "=" * 80)
    print("SUMMARY: TVL-DEPENDENT DECISION")
    print("=" * 80)
    print("\n{:<15} {:<20} {:<25} {:<15}".format(
        "TVL", "Winner", "Net Benefit Diff", "Decision"
    ))
    print("-" * 80)

    for tvl_label, results in all_results:
        winner = results["comparison"]["winner"]
        net_diff = results["comparison"]["net_benefit_diff"]
        decision = "Integrate (B)" if net_diff > 0 else "Keep Separate (A)"

        print("{:<15} {:<20} ${:<24,.0f} {:<15}".format(
            tvl_label,
            winner,
            abs(net_diff),
            decision
        ))

    print("\n" + "=" * 80)
    print("KEY TAKEAWAY")
    print("=" * 80)
    print("\n  The decision to integrate fee skimming with PPS updates is TVL-DEPENDENT:")
    print()
    print("  • Low TVL (<$250M):   Keep separate - gas costs dominate")
    print("  • High TVL (>$250M):  Integrate - arbitrage savings dominate")
    print("  • Breakeven: ~$250M TVL")
    print()
    print("  Gas costs are FIXED (~$28,574/year extra for integration)")
    print("  Arbitrage scales with TVL (larger deposits = larger arbitrage)")
    print()
    print("  Recommendation: Implement TVL-based threshold or manager opt-in")
    print()

    print("=" * 80)
    print("For more details, see:")
    print("  - src/oracles/ECDSAPPSOracle.sol:61 (updatePPS)")
    print("  - src/SuperVault/SuperVaultAggregator.sol:213 (forwardPPS)")
    print("  - src/SuperVault/SuperVaultAggregator.sol:1079 (_forwardPPS)")
    print("  - src/SuperVault/SuperVaultStrategy.sol:372 (skimPerformanceFee)")
    print("=" * 80)
    print()


if __name__ == "__main__":
    main()
