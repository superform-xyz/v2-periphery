"""Optimal skim frequency calculator.

Analyzes different skim frequencies to find the optimal balance between
fees captured and arbitrage opportunities.
"""

from dataclasses import dataclass
from typing import Dict, List, Optional
import numpy as np


# ============================================================================
# Vault Model
# ============================================================================

@dataclass
class SkimConfig:
    """Configuration for skim behavior."""
    performance_fee_bps: int = 2000  # 20% = 2000 bps
    superform_fee_bps: int = 500  # 5% of performance fee = 500 bps
    skim_interval_days: float = 1.0
    
    @property
    def performance_fee_pct(self) -> float:
        return self.performance_fee_bps / 10000.0
    
    @property
    def superform_fee_pct(self) -> float:
        return self.superform_fee_bps / 10000.0


@dataclass
class SkimResult:
    """Result of a skim operation."""
    timestamp: float
    pre_skim_pps: float
    post_skim_pps: float
    profit: float
    total_fee: float
    superform_fee: float
    recipient_fee: float
    pps_drop_pct: float


class VaultSimulator:
    """Simulates vault behavior with skim-based performance fees."""
    
    def __init__(
        self,
        initial_tvl: float = 1_000_000.0,
        daily_yield_pct: float = 0.1,
        skim_config: Optional[SkimConfig] = None,
    ):
        self.skim_config = skim_config or SkimConfig()
        self.daily_yield_pct = daily_yield_pct
        
        initial_supply = initial_tvl
        self.total_assets = initial_tvl
        self.total_supply = initial_supply
        self.vault_total_cost_basis = initial_tvl
        self.last_skim_timestamp = 0.0
    
    @property
    def pps(self) -> float:
        """Price per share."""
        if self.total_supply == 0:
            return 1.0
        return self.total_assets / self.total_supply
    
    def _apply_yield(self, days: float) -> None:
        """Apply yield over a given number of days."""
        multiplier = (1.0 + self.daily_yield_pct / 100.0) ** days
        self.total_assets *= multiplier
    
    def can_skim(self, current_time: float) -> bool:
        """Check if a skim can be performed."""
        return (current_time - self.last_skim_timestamp) >= self.skim_config.skim_interval_days
    
    def skim(self, timestamp: float) -> Optional[SkimResult]:
        """Perform a skim operation."""
        if not self.can_skim(timestamp):
            return None
        
        pre_skim_assets = self.total_assets
        pre_skim_pps = self.pps
        
        # Calculate profit above HWM
        profit = max(0.0, pre_skim_assets - self.vault_total_cost_basis)
        if profit <= 0:
            return None
        
        # Calculate fees
        total_fee = profit * self.skim_config.performance_fee_pct
        superform_fee = total_fee * self.skim_config.superform_fee_pct
        recipient_fee = total_fee - superform_fee
        
        # Transfer fees (reduce assets)
        self.total_assets -= total_fee
        
        # Reset HWM to post-skim assets
        self.vault_total_cost_basis = self.total_assets
        self.last_skim_timestamp = timestamp
        
        post_skim_pps = self.pps
        pps_drop_pct = ((pre_skim_pps - post_skim_pps) / pre_skim_pps) * 100.0
        
        return SkimResult(
            timestamp=timestamp,
            pre_skim_pps=pre_skim_pps,
            post_skim_pps=post_skim_pps,
            profit=profit,
            total_fee=total_fee,
            superform_fee=superform_fee,
            recipient_fee=recipient_fee,
            pps_drop_pct=pps_drop_pct,
        )


# ============================================================================
# Optimal Frequency Analysis
# ============================================================================

def calculate_fees_captured(
    initial_tvl: float,
    daily_yield_pct: float,
    days: int,
    skim_interval_days: float,
) -> Dict[str, float]:
    """Calculate total fees captured over a period with a given skim interval."""
    vault = VaultSimulator(
        initial_tvl=initial_tvl,
        daily_yield_pct=daily_yield_pct,
        skim_config=SkimConfig(skim_interval_days=skim_interval_days),
    )
    
    total_fees = 0.0
    total_superform_fees = 0.0
    total_recipient_fees = 0.0
    num_skims = 0
    
    for day in range(days):
        vault._apply_yield(1.0)
        skim_result = vault.skim(float(day))
        
        if skim_result:
            total_fees += skim_result.total_fee
            total_superform_fees += skim_result.superform_fee
            total_recipient_fees += skim_result.recipient_fee
            num_skims += 1
    
    return {
        "skim_interval_days": skim_interval_days,
        "num_skims": num_skims,
        "total_fees": total_fees,
        "total_superform_fees": total_superform_fees,
        "total_recipient_fees": total_recipient_fees,
        "avg_fee_per_skim": total_fees / num_skims if num_skims > 0 else 0.0,
        "fees_per_day": total_fees / days if days > 0 else 0.0,
    }


def find_optimal_frequency(
    initial_tvl: float = 1_000_000.0,
    daily_yield_pct: float = 0.1,
    days: int = 365,
    skim_intervals: List[float] = None,
) -> Dict:
    """
    Find optimal skim frequency by comparing fees captured.
    
    Returns:
        Dictionary with analysis results including optimal interval
    """
    if skim_intervals is None:
        # Include hourly (1/24 day) and 2-hour (1/12 day) intervals
        skim_intervals = [1.0/24.0, 1.0/12.0, 0.5, 1.0, 2.0, 3.0, 7.0, 14.0, 30.0]
    
    results = []
    
    for interval in skim_intervals:
        metrics = calculate_fees_captured(initial_tvl, daily_yield_pct, days, interval)
        results.append(metrics)
    
    # Find optimal (max fees per day)
    optimal_idx = max(range(len(results)), key=lambda i: results[i]["fees_per_day"])
    optimal_result = results[optimal_idx]
    
    return {
        "optimal_interval_days": optimal_result["skim_interval_days"],
        "optimal_fees_per_day": optimal_result["fees_per_day"],
        "all_results": results,
    }


def analyze_frequency_vs_arbitrage(
    initial_tvl: float = 1_000_000.0,
    daily_yield_pct: float = 0.1,
    days: int = 365,
    total_deposit_volume: float = None,  # Total deposits over period
    strategic_timing_pct: float = 1.0,  # % of deposits that are strategically timed (1.0 = 100%)
    skim_intervals: List[float] = None,
) -> Dict:
    """
    Analyze trade-off between skim frequency, fees captured, and arbitrage opportunities.
    
    Models strategic deposit timing: users wait for skims and deposit right after
    when PPS is lowest. Longer intervals = larger PPS drops = more exploitable arbitrage.
    
    Args:
        initial_tvl: Initial total value locked
        daily_yield_pct: Daily yield percentage
        days: Number of days to simulate
        total_deposit_volume: Total deposit volume over period (None = auto-calculate)
        strategic_timing_pct: Percentage of deposits strategically timed (0.0-1.0)
        skim_intervals: List of intervals to test
    
    Returns:
        Dictionary with comprehensive analysis
    """
    if skim_intervals is None:
        # Include hourly (1/24 day) and 2-hour (1/12 day) intervals
        skim_intervals = [1.0/24.0, 1.0/12.0, 0.5, 1.0, 2.0, 7.0, 14.0, 30.0]
    
    # Auto-calculate deposit volume if not provided
    # For large TVLs, assume deposits = 2x initial TVL over year (realistic growth)
    if total_deposit_volume is None:
        total_deposit_volume = initial_tvl * 2.0
    
    results = []
    
    for interval in skim_intervals:
        # Calculate fees
        fee_metrics = calculate_fees_captured(initial_tvl, daily_yield_pct, days, interval)
        
        # Simulate vault to get PPS drops
        vault = VaultSimulator(
            initial_tvl=initial_tvl,
            daily_yield_pct=daily_yield_pct,
            skim_config=SkimConfig(skim_interval_days=interval),
        )
        
        # Track PPS drops from each skim
        pps_drops = []
        num_skims = 0
        
        for day in range(days):
            vault._apply_yield(1.0)
            skim_result = vault.skim(float(day))
            
            if skim_result:
                pps_drops.append(skim_result.pps_drop_pct)
                num_skims += 1
        
        # Calculate arbitrage from strategic deposit timing
        # Users wait for skims and deposit right after when PPS drops
        if num_skims == 0 or len(pps_drops) == 0:
            total_arb = 0.0
            avg_pps_drop = 0.0
        else:
            # Average PPS drop per skim
            avg_pps_drop = np.mean(pps_drops)
            
            # Distribute deposits: strategically timed deposits happen right after each skim
            # Volume per skim = total_deposit_volume / num_skims
            strategically_timed_deposits = total_deposit_volume * strategic_timing_pct
            deposits_per_skim = strategically_timed_deposits / num_skims if num_skims > 0 else 0.0
            
            # Use accurate calculation
            total_arb_acc = 0.0
            
            # Reset vault for accurate calculation
            vault = VaultSimulator(
                initial_tvl=initial_tvl,
                daily_yield_pct=daily_yield_pct,
                skim_config=SkimConfig(skim_interval_days=interval),
            )
            
            for day in range(days):
                vault._apply_yield(1.0)
                skim_result = vault.skim(float(day))
                
                if skim_result:
                    # Simulate strategic deposits after this skim
                    deposit_amt = deposits_per_skim
                    
                    # Calculate arbitrage
                    pre_skim_shares = deposit_amt / skim_result.pre_skim_pps
                    post_skim_shares = deposit_amt / skim_result.post_skim_pps
                    extra_shares = post_skim_shares - pre_skim_shares
                    arbitrage_gain = extra_shares * skim_result.pre_skim_pps
                    
                    total_arb_acc += arbitrage_gain
                    
                    # Update vault state (for realism)
                    vault.total_assets += deposit_amt
                    vault.total_supply += post_skim_shares
                    vault.vault_total_cost_basis += deposit_amt
            
            total_arb = total_arb_acc
        
        arb_percentage = (total_arb / total_deposit_volume * 100.0) if total_deposit_volume > 0 else 0.0
        
        results.append({
            "skim_interval_days": interval,
            "fees_per_day": fee_metrics["fees_per_day"],
            "total_fees": fee_metrics["total_fees"],
            "num_skims": fee_metrics["num_skims"],
            "avg_pps_drop_pct": avg_pps_drop,
            "total_arb_profit": total_arb,
            "arb_percentage": arb_percentage,
            "net_benefit_before_gas": fee_metrics["total_fees"] - total_arb,
        })
    
    return {
        "results": results,
        "initial_tvl": initial_tvl,
        "total_deposit_volume": total_deposit_volume,
    }


# ============================================================================
# Gas Cost Calculation
# ============================================================================

def calculate_skim_gas_cost() -> Dict[str, int]:
    """
    Calculate gas costs for skimPerformanceFee() function.
    
    Based on opcode costs:
    - External call: 100 gas
    - SLOAD (cold): 2100 gas, (warm): 100 gas
    - SSTORE (cold, zero->non-zero): 20000 gas, (warm, non-zero->non-zero): 2900 gas
    - TIMESTAMP: 2 gas
    - Arithmetic ops: ~3-5 gas each
    - External calls (contract): 2300 gas base + 9000 gas per non-zero value transfer
    - Events: ~375 gas per topic + 8 gas per byte
    
    Returns:
        Dictionary with gas cost breakdown
    """
    # Access control check (_isManager)
    # - External call to aggregator: 100 gas
    # - SLOAD for manager check: 2100 gas (cold) or 100 gas (warm)
    access_control_gas = 100 + 2100  # Conservative: assume cold
    
    # Cooldown check
    # - SLOAD lastSkimTimestamp: 2100 gas (cold) or 100 gas (warm)
    # - TIMESTAMP: 2 gas
    # - Comparison: 3 gas
    cooldown_check_gas = 2100 + 2 + 3
    
    # Get vault state
    # - External call to ISuperVault: 100 gas
    # - SLOAD for totalAssets: 2100 gas (cold)
    # - External call to ISuperVault: 100 gas
    # - SLOAD for totalSupply: 2100 gas (cold)
    vault_state_gas = (100 + 2100) * 2
    
    # Calculate HWM
    # - SLOAD vaultTotalCostBasis: 2100 gas (cold) or 100 gas (warm)
    # - mulDiv operation: ~200 gas (includes multiple arithmetic ops)
    hwm_calculation_gas = 2100 + 200
    
    # Calculate profit and fee
    # - Comparison: 3 gas
    # - Subtraction: 3 gas
    # - mulDiv: ~200 gas
    profit_fee_calculation_gas = 3 + 3 + 200
    
    # Get SuperGovernor addresses/fees
    # - External call to SuperGovernor: 100 gas
    # - SLOAD for fee: 2100 gas (cold)
    # - External call to SuperGovernor: 100 gas
    # - SLOAD for treasury address: 2100 gas (cold)
    governor_calls_gas = (100 + 2100) * 2
    
    # Transfer fees (2 transfers)
    # - Each transfer: 2300 (base) + 9000 (non-zero value) = 11300 gas
    transfer_gas = 11300 * 2
    
    # Update storage
    # - SSTORE vaultTotalCostBasis: 2900 gas (warm, non-zero->non-zero)
    # - SSTORE lastSkimTimestamp: 2900 gas (warm, non-zero->non-zero)
    storage_update_gas = 2900 * 2
    
    # Emit event
    # - PerformanceFeeSkimmed event: ~375 * 2 topics + 64 bytes = ~848 gas
    event_gas = 375 * 2 + 64 * 8
    
    # Base transaction cost
    base_tx_gas = 21000
    
    # Total gas (conservative estimate)
    total_gas = (
        base_tx_gas +
        access_control_gas +
        cooldown_check_gas +
        vault_state_gas +
        hwm_calculation_gas +
        profit_fee_calculation_gas +
        governor_calls_gas +
        transfer_gas +
        storage_update_gas +
        event_gas
    )
    
    return {
        "base_tx": base_tx_gas,
        "access_control": access_control_gas,
        "cooldown_check": cooldown_check_gas,
        "vault_state": vault_state_gas,
        "hwm_calculation": hwm_calculation_gas,
        "profit_fee_calculation": profit_fee_calculation_gas,
        "governor_calls": governor_calls_gas,
        "transfers": transfer_gas,
        "storage_update": storage_update_gas,
        "event": event_gas,
        "total": total_gas,
    }


def analyze_gas_costs_vs_frequency_old(
    skim_intervals: List[float] = None,
    gas_price_gwei: float = 20.0,  # Gas price in gwei
    eth_price_usd: float = 3000.0,  # ETH price in USD
) -> Dict:
    """
    Analyze gas costs vs skim frequency.
    
    Returns:
        Dictionary with gas cost analysis
    """
    if skim_intervals is None:
        skim_intervals = [1.0/24.0, 1.0/12.0, 0.5, 1.0, 2.0, 7.0, 14.0, 30.0]
    
    gas_costs = calculate_skim_gas_cost()
    gas_per_skim = gas_costs["total"]
    
    results = []
    
    for interval in skim_intervals:
        skims_per_year = 365.0 / interval
        total_gas_per_year = gas_per_skim * skims_per_year
        gas_cost_eth = total_gas_per_year * gas_price_gwei / 1e9
        gas_cost_usd = gas_cost_eth * eth_price_usd
        
        results.append({
            "interval_days": interval,
            "interval_hours": interval * 24.0,
            "skims_per_year": skims_per_year,
            "gas_per_skim": gas_per_skim,
            "total_gas_per_year": total_gas_per_year,
            "gas_cost_usd_per_year": gas_cost_usd,
        })
    
    return {
        "gas_per_skim": gas_per_skim,
        "results": results,
    }


def analyze_comprehensive_frequency_analysis(
    tvls: List[float] = None,
    apy: float = 10.0,
    gas_price_gwei: float = 20.0,
    eth_price_usd: float = 3000.0,
    skim_intervals: List[float] = None,
) -> Dict:
    """
    Comprehensive analysis combining gas costs and arbitrage losses.
    
    For each TVL, analyzes:
    - Fees captured
    - Arbitrage losses (from strategic deposit timing)
    - Gas costs (from frequent skims)
    - Net benefit = Fees - Arbitrage - Gas
    
    Returns:
        Dictionary with comprehensive analysis for each TVL
    """
    if tvls is None:
        tvls = [100_000_000.0, 250_000_000.0, 500_000_000.0]
    
    if skim_intervals is None:
        skim_intervals = [1.0/24.0, 1.0/12.0, 0.5, 1.0, 2.0, 7.0, 14.0, 30.0]
    
    # Convert APY to daily yield
    daily_yield_pct = ((1.0 + apy / 100.0) ** (1.0 / 365.0) - 1.0) * 100.0
    
    # Calculate gas costs
    gas_costs = calculate_skim_gas_cost()
    gas_per_skim = gas_costs["total"]
    
    results_by_tvl = {}
    
    for tvl in tvls:
        # Analyze frequency vs arbitrage for this TVL
        freq_arb_analysis = analyze_frequency_vs_arbitrage(
            initial_tvl=tvl,
            daily_yield_pct=daily_yield_pct,
            days=365,
            total_deposit_volume=tvl * 2.0,  # 2x TVL deposits over year
            strategic_timing_pct=1.0,
            skim_intervals=skim_intervals,
        )
        
        # Add gas costs to each result
        results_with_gas = []
        for result in freq_arb_analysis["results"]:
            interval = result["skim_interval_days"]
            skims_per_year = 365.0 / interval
            gas_cost_per_year = (gas_per_skim * skims_per_year * gas_price_gwei / 1e9) * eth_price_usd
            
            net_benefit_after_gas = result["net_benefit_before_gas"] - gas_cost_per_year
            
            results_with_gas.append({
                **result,
                "gas_cost_per_year": gas_cost_per_year,
                "net_benefit_after_gas": net_benefit_after_gas,
                "gas_cost_pct_of_fees": (gas_cost_per_year / result["total_fees"] * 100.0) if result["total_fees"] > 0 else 0.0,
                "arb_loss_pct_of_fees": (result["total_arb_profit"] / result["total_fees"] * 100.0) if result["total_fees"] > 0 else 0.0,
                "net_benefit_pct_of_fees": (net_benefit_after_gas / result["total_fees"] * 100.0) if result["total_fees"] > 0 else 0.0,
            })
        
        # Find optimal (maximize net benefit after gas)
        optimal_idx = max(range(len(results_with_gas)), key=lambda i: results_with_gas[i]["net_benefit_after_gas"])
        optimal = results_with_gas[optimal_idx]
        
        results_by_tvl[tvl] = {
            "results": results_with_gas,
            "optimal": optimal,
        }
    
    return {
        "apy": apy,
        "daily_yield_pct": daily_yield_pct,
        "gas_price_gwei": gas_price_gwei,
        "eth_price_usd": eth_price_usd,
        "gas_per_skim": gas_per_skim,
        "results_by_tvl": results_by_tvl,
    }


# ============================================================================
# Main Entry Point
# ============================================================================

def main():
    """Run optimal frequency analysis."""
    print("=" * 80)
    print("OPTIMAL SKIM FREQUENCY ANALYSIS")
    print("=" * 80)
    
    # Use realistic yield: 10% APY = ~0.0261% daily
    apy = 10.0  # 10% APY
    daily_yield_pct = ((1.0 + apy / 100.0) ** (1.0 / 365.0) - 1.0) * 100.0
    print(f"\nUsing {apy}% APY ({daily_yield_pct:.6f}% daily yield)")
    
    # Comprehensive analysis across TVLs
    print("\nComprehensive analysis: Gas costs vs Arbitrage losses")
    print("  Analyzing across TVLs: $100M, $250M, $500M")
    print("\n  Calculation:")
    print("    Net Benefit = Fees Captured - Arbitrage Loss - Gas Costs")
    print("    - Fees Captured: Performance fees from vault yield")
    print("    - Arbitrage Loss: Users deposit after skims when PPS drops")
    print("    - Gas Costs: Transaction costs for each skim")
    
    comprehensive = analyze_comprehensive_frequency_analysis(
        tvls=[100_000_000.0, 250_000_000.0, 500_000_000.0],
        apy=10.0,
        gas_price_gwei=20.0,
        eth_price_usd=3000.0,
    )
    
    print(f"\n  Using {comprehensive['apy']}% APY, Gas: {comprehensive['gas_price_gwei']} gwei @ ${comprehensive['eth_price_usd']}/ETH")
    print(f"  Gas per skim: {comprehensive['gas_per_skim']:,} gas")
    
    for tvl, tvl_data in comprehensive["results_by_tvl"].items():
        print(f"\n  {'='*70}")
        print(f"  TVL: ${tvl/1e6:.0f}M")
        print(f"  {'='*70}")
        
        optimal = tvl_data["optimal"]
        
        print(f"\n  {'Interval':<12} {'Hours':<10} {'Fees $':<15} {'Arb Loss $':<15} {'Gas $':<15} {'Net $':<15}")
        print(f"  {'':<12} {'':<10} {'(Year)':<15} {'(Year)':<15} {'(Year)':<15} {'(Year)':<15}")
        print("  " + "-" * 82)
        
        for result in tvl_data["results"]:
            interval_hours = result["skim_interval_days"] * 24.0
            interval_str = f"{result['skim_interval_days']:.4f}" if result['skim_interval_days'] < 1.0 else f"{result['skim_interval_days']:.1f}"
            
            # Show net calculation breakdown for first row
            net_breakdown = ""
            if result == tvl_data["results"][0]:
                net_breakdown = f"  ({result['total_fees']:.0f} - {result['total_arb_profit']:.0f} - {result['gas_cost_per_year']:.0f})"
            
            print(
                f"  {interval_str:<12} "
                f"{interval_hours:<10.2f} "
                f"${result['total_fees']:<14,.0f} "
                f"${result['total_arb_profit']:<14,.0f} "
                f"${result['gas_cost_per_year']:<14,.0f} "
                f"${result['net_benefit_after_gas']:<14,.0f}"
            )
            if net_breakdown:
                print(net_breakdown)
        
        print(f"\n  Optimal interval: {optimal['skim_interval_days']:.4f} days ({optimal['skim_interval_days']*24:.2f} hours)")
        print(f"    Fees captured: ${optimal['total_fees']:,.0f}/year")
        print(f"    Arbitrage loss: ${optimal['total_arb_profit']:,.0f}/year ({optimal['arb_loss_pct_of_fees']:.2f}% of fees)")
        print(f"    Gas costs: ${optimal['gas_cost_per_year']:,.0f}/year ({optimal['gas_cost_pct_of_fees']:.2f}% of fees)")
        print(f"    Net benefit: ${optimal['net_benefit_after_gas']:,.0f}/year ({optimal['net_benefit_pct_of_fees']:.2f}% of fees)")
        print(f"    Calculation: ${optimal['total_fees']:,.0f} - ${optimal['total_arb_profit']:,.0f} - ${optimal['gas_cost_per_year']:,.0f} = ${optimal['net_benefit_after_gas']:,.0f}")
    
    print("\n" + "=" * 80)
    print("CONCLUSION")
    print("=" * 80)
    
    # Summary across all TVLs
    print("\nOptimal intervals by TVL:")
    for tvl, tvl_data in comprehensive["results_by_tvl"].items():
        optimal = tvl_data["optimal"]
        interval_hours = optimal["skim_interval_days"] * 24.0
        
        print(f"\n  ${tvl/1e6:.0f}M TVL:")
        print(f"    Optimal: {interval_hours:.2f} hours ({optimal['skim_interval_days']:.4f} days)")
        print(f"    Net benefit: ${optimal['net_benefit_after_gas']:,.0f}/year")
        print(f"    Arbitrage loss: {optimal['arb_loss_pct_of_fees']:.2f}% of fees")
        print(f"    Gas costs: {optimal['gas_cost_pct_of_fees']:.2f}% of fees")
    
    print("\nKey insights:")
    print("  - More frequent skims reduce arbitrage losses but increase gas costs")
    print("  - For large TVLs ($100M+), arbitrage losses dominate gas costs")
    print("  - Optimal frequency balances: fees - arbitrage - gas")
    print("  - At 10% APY with $100M+ TVL, daily (24h) skims are optimal")
    print("  - Gas costs are negligible compared to arbitrage losses at scale")


if __name__ == "__main__":
    main()

