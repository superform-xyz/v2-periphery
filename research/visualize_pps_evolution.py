"""
PPS Evolution Visualization

Creates charts showing how PPS evolves over time for different yield strategies,
highlighting the "jumps" from yield accrual and "corrections" from skim events.

This helps visualize the pre-skim loss window and understand why harvest frequency matters.

Author: Superform Labs
Date: 2025-01-04
Usage: cd research && uv run python visualize_pps_evolution.py
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from dataclasses import dataclass
from typing import List, Tuple
import sys


@dataclass
class VaultConfig:
    """Vault economic parameters"""
    initial_tvl: float = 100_000_000.0
    apy: float = 10.0
    performance_fee_bps: int = 2000  # 20%
    superform_fee_bps: int = 5000  # 50% of performance fee

    @property
    def daily_yield_rate(self) -> float:
        return (1.0 + self.apy / 100.0) ** (1.0 / 365.0) - 1.0

    @property
    def performance_fee_pct(self) -> float:
        return self.performance_fee_bps / 10000.0


class PPSTracker:
    """Tracks PPS evolution over time"""

    def __init__(self, config: VaultConfig):
        self.config = config
        self.total_assets = config.initial_tvl
        self.total_supply = config.initial_tvl
        self.hwm_pps = 1.0

        # History tracking
        self.hours = []
        self.pps_values = []
        self.hwm_values = []
        self.skim_events = []  # (hour, pre_pps, post_pps)
        self.harvest_events = []  # (hour, pre_pps, post_pps)

    @property
    def pps(self) -> float:
        if self.total_supply == 0:
            return 1.0
        return self.total_assets / self.total_supply

    def record(self, hour: float):
        """Record current state"""
        self.hours.append(hour)
        self.pps_values.append(self.pps)
        self.hwm_values.append(self.hwm_pps)

    def accrue_yield(self, hours: float):
        """Accrue continuous yield"""
        days = hours / 24.0
        multiplier = (1.0 + self.config.daily_yield_rate) ** days
        self.total_assets *= multiplier

    def harvest_yield(self, days_since_last: float):
        """Apply discrete yield harvest"""
        pre_pps = self.pps
        growth_rate = (1.0 + self.config.apy / 100.0) ** (days_since_last / 365.0) - 1.0
        harvest_amount = self.total_assets * growth_rate
        self.total_assets += harvest_amount
        post_pps = self.pps
        return pre_pps, post_pps

    def skim(self, hour: float):
        """Extract performance fees"""
        pre_pps = self.pps

        if pre_pps <= self.hwm_pps:
            return

        # Calculate fee
        pps_growth = pre_pps - self.hwm_pps
        profit = pps_growth * self.total_supply
        fee = profit * self.config.performance_fee_pct

        # Extract fee
        self.total_assets -= fee

        # Update HWM
        post_pps = self.pps
        self.hwm_pps = post_pps

        # Record event
        self.skim_events.append((hour, pre_pps, post_pps))


def simulate_continuous_yield(days: int = 30) -> PPSTracker:
    """Simulate continuous yield with daily skim"""
    config = VaultConfig()
    tracker = PPSTracker(config)

    for hour in range(days * 24):
        # Accrue yield every hour
        tracker.accrue_yield(1.0)
        tracker.record(hour)

        # Skim once per day
        if hour > 0 and hour % 24 == 0:
            tracker.skim(hour)

    return tracker


def simulate_discrete_harvest(days: int = 30, harvest_freq_days: int = 7) -> PPSTracker:
    """Simulate discrete harvest with skim after each harvest"""
    config = VaultConfig()
    tracker = PPSTracker(config)

    last_harvest_hour = 0.0

    for hour in range(days * 24):
        tracker.record(hour)

        # Harvest at specified frequency
        if hour > 0 and (hour - last_harvest_hour) >= (harvest_freq_days * 24):
            days_since = (hour - last_harvest_hour) / 24.0
            pre_pps, post_pps = tracker.harvest_yield(days_since)
            tracker.harvest_events.append((hour, pre_pps, post_pps))
            last_harvest_hour = hour

            # Skim 1 hour after harvest
            tracker.record(hour)

        # Skim 1 hour after harvest
        if hour > 0 and (hour - last_harvest_hour) == 1:
            tracker.skim(hour)

    return tracker


def plot_pps_evolution(
    tracker: PPSTracker,
    title: str,
    filename: str,
    show_user_loss_windows: bool = True
):
    """Plot PPS evolution over time with skim events highlighted"""

    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 10))

    hours = np.array(tracker.hours)
    pps = np.array(tracker.pps_values)
    hwm = np.array(tracker.hwm_values)

    # Top plot: Full timeline
    ax1.plot(hours / 24, pps, 'b-', linewidth=2, label='Current PPS', zorder=3)
    ax1.plot(hours / 24, hwm, 'g--', linewidth=1.5, label='HWM PPS', zorder=2, alpha=0.7)

    # Highlight skim events
    for hour, pre_pps, post_pps in tracker.skim_events:
        day = hour / 24
        ax1.axvline(day, color='red', alpha=0.3, linestyle='--', linewidth=1)
        ax1.annotate('SKIM', xy=(day, post_pps), xytext=(day, post_pps * 0.9995),
                    fontsize=8, color='red', ha='center',
                    arrowprops=dict(arrowstyle='->', color='red', lw=1.5))

        # Highlight user loss window (between last data point and skim)
        if show_user_loss_windows and len(tracker.skim_events) > 0:
            # Find the time window before this skim where PPS was elevated
            idx = np.where(hours <= hour)[0]
            if len(idx) > 24:  # Look back 24 hours
                start_idx = idx[-24]
                end_idx = idx[-1]
                ax1.axvspan(hours[start_idx] / 24, day, alpha=0.15, color='orange',
                           label='User Loss Window' if day == tracker.skim_events[0][0] / 24 else '')

    # Highlight harvest events
    for hour, pre_pps, post_pps in tracker.harvest_events:
        day = hour / 24
        ax1.annotate('HARVEST', xy=(day, post_pps), xytext=(day, post_pps * 1.0005),
                    fontsize=8, color='purple', ha='center',
                    arrowprops=dict(arrowstyle='->', color='purple', lw=1.5))

    ax1.set_xlabel('Days', fontsize=12)
    ax1.set_ylabel('Price Per Share (PPS)', fontsize=12)
    ax1.set_title(f'{title}\nPPS Evolution Over Time', fontsize=14, fontweight='bold')
    ax1.legend(loc='upper left', fontsize=10)
    ax1.grid(True, alpha=0.3)

    # Bottom plot: Zoomed into first skim cycle
    if len(tracker.skim_events) > 0:
        first_skim_hour = tracker.skim_events[0][0]
        zoom_start = max(0, first_skim_hour - 48)  # 2 days before first skim
        zoom_end = min(len(hours), first_skim_hour + 24)  # 1 day after

        zoom_hours = hours[zoom_start:zoom_end]
        zoom_pps = pps[zoom_start:zoom_end]
        zoom_hwm = hwm[zoom_start:zoom_end]

        ax2.plot(zoom_hours, zoom_pps, 'b-', linewidth=2, label='Current PPS', marker='o', markersize=3)
        ax2.plot(zoom_hours, zoom_hwm, 'g--', linewidth=1.5, label='HWM PPS')

        # Highlight the skim event
        pre_skim, post_skim = tracker.skim_events[0][1], tracker.skim_events[0][2]
        ax2.axvline(first_skim_hour, color='red', alpha=0.5, linestyle='--', linewidth=2)
        ax2.axhspan(post_skim, pre_skim, alpha=0.2, color='red',
                   label=f'PPS Drop ({((pre_skim - post_skim) / pre_skim * 100):.4f}%)')

        # Annotate the loss
        loss_pct = (pre_skim - post_skim) / pre_skim * 100
        ax2.text(first_skim_hour + 2, (pre_skim + post_skim) / 2,
                f'User Loss\nif deposited\nbefore skim:\n{loss_pct:.4f}%',
                fontsize=9, bbox=dict(boxstyle='round', facecolor='yellow', alpha=0.7))

        # Highlight harvest if any in this window
        for hour, pre_h, post_h in tracker.harvest_events:
            if zoom_start <= hour <= zoom_end:
                ax2.axvline(hour, color='purple', alpha=0.5, linestyle='--', linewidth=2)
                ax2.text(hour - 5, post_h * 1.0001, 'HARVEST',
                        fontsize=9, color='purple', fontweight='bold')

        ax2.set_xlabel('Hours', fontsize=12)
        ax2.set_ylabel('Price Per Share (PPS)', fontsize=12)
        ax2.set_title('Zoomed View: First Skim Cycle', fontsize=13, fontweight='bold')
        ax2.legend(loc='upper left', fontsize=10)
        ax2.grid(True, alpha=0.3)

        # Format y-axis to show more decimal places
        ax2.ticklabel_format(useOffset=False, style='plain')

    plt.tight_layout()
    plt.savefig(f'/Users/timepunk/work/v2-periphery/research/{filename}', dpi=300, bbox_inches='tight')
    print(f"✅ Saved: {filename}")


def create_comparison_chart(trackers: dict, filename: str):
    """Create side-by-side comparison of different strategies"""

    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    axes = axes.flatten()

    strategies = [
        ('continuous', 'Continuous Yield\n(Lending, AMMs)'),
        ('discrete_1d', 'Daily Harvest\n(Daily reward claims)'),
        ('discrete_7d', 'Weekly Harvest\n(Weekly reward farming)'),
        ('discrete_30d', 'Monthly Harvest\n(Monthly reward farming)'),
    ]

    for idx, (key, title) in enumerate(strategies):
        if key not in trackers:
            continue

        tracker = trackers[key]
        ax = axes[idx]

        hours = np.array(tracker.hours)
        pps = np.array(tracker.pps_values)

        # Plot PPS
        ax.plot(hours / 24, pps, 'b-', linewidth=2, label='PPS')

        # Mark skim events
        for hour, pre_pps, post_pps in tracker.skim_events[:3]:  # First 3 skims
            day = hour / 24
            ax.axvline(day, color='red', alpha=0.3, linestyle='--')
            loss_pct = (pre_pps - post_pps) / pre_pps * 100
            ax.text(day, post_pps * 0.999, f'-{loss_pct:.4f}%',
                   fontsize=8, color='red', ha='center')

        # Mark harvest events
        for hour, pre_h, post_h in tracker.harvest_events[:3]:  # First 3 harvests
            day = hour / 24
            ax.axvline(day, color='purple', alpha=0.3, linestyle='-', linewidth=2)
            gain_pct = (post_h - pre_h) / pre_h * 100
            ax.text(day, post_h * 1.0001, f'+{gain_pct:.3f}%',
                   fontsize=8, color='purple', ha='center')

        # Calculate average loss
        if len(tracker.skim_events) > 0:
            avg_loss = np.mean([(pre - post) / pre * 100
                               for _, pre, post in tracker.skim_events])
            ax.text(0.02, 0.98, f'Avg PPS Drop:\n{avg_loss:.4f}%',
                   transform=ax.transAxes, fontsize=10,
                   verticalalignment='top',
                   bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.8))

        ax.set_xlabel('Days', fontsize=11)
        ax.set_ylabel('Price Per Share', fontsize=11)
        ax.set_title(title, fontsize=12, fontweight='bold')
        ax.grid(True, alpha=0.3)
        ax.legend(['PPS', 'Skim', 'Harvest'], fontsize=9, loc='lower right')

        # Limit to first 30 days for clarity
        ax.set_xlim(0, 30)

    plt.suptitle('PPS Evolution Comparison: Impact of Harvest Frequency on User Losses',
                fontsize=16, fontweight='bold', y=0.995)
    plt.tight_layout()
    plt.savefig(f'/Users/timepunk/work/v2-periphery/research/{filename}', dpi=300, bbox_inches='tight')
    print(f"✅ Saved: {filename}")


def main():
    """Generate all visualization charts"""

    print("=" * 80)
    print("GENERATING PPS EVOLUTION VISUALIZATIONS")
    print("=" * 80)
    print()

    trackers = {}

    # Continuous yield
    print("Simulating continuous yield...")
    tracker_continuous = simulate_continuous_yield(days=60)
    trackers['continuous'] = tracker_continuous
    plot_pps_evolution(
        tracker_continuous,
        "CONTINUOUS YIELD STRATEGY",
        "pps_continuous_yield.png"
    )

    # Daily harvest
    print("Simulating daily discrete harvest...")
    tracker_daily = simulate_discrete_harvest(days=60, harvest_freq_days=1)
    trackers['discrete_1d'] = tracker_daily
    plot_pps_evolution(
        tracker_daily,
        "DISCRETE HARVEST - DAILY",
        "pps_discrete_daily.png"
    )

    # Weekly harvest
    print("Simulating weekly discrete harvest...")
    tracker_weekly = simulate_discrete_harvest(days=60, harvest_freq_days=7)
    trackers['discrete_7d'] = tracker_weekly
    plot_pps_evolution(
        tracker_weekly,
        "DISCRETE HARVEST - WEEKLY (Larger PPS Jumps)",
        "pps_discrete_weekly.png"
    )

    # Monthly harvest
    print("Simulating monthly discrete harvest...")
    tracker_monthly = simulate_discrete_harvest(days=90, harvest_freq_days=30)
    trackers['discrete_30d'] = tracker_monthly
    plot_pps_evolution(
        tracker_monthly,
        "DISCRETE HARVEST - MONTHLY (LARGEST PPS Jumps)",
        "pps_discrete_monthly.png"
    )

    # Comparison chart
    print("Creating comparison chart...")
    create_comparison_chart(trackers, "pps_comparison_all_strategies.png")

    print()
    print("=" * 80)
    print("VISUALIZATION COMPLETE")
    print("=" * 80)
    print()
    print("Generated files:")
    print("  • pps_continuous_yield.png - Continuous yield (lending, AMMs)")
    print("  • pps_discrete_daily.png - Daily harvest strategy")
    print("  • pps_discrete_weekly.png - Weekly harvest strategy")
    print("  • pps_discrete_monthly.png - Monthly harvest strategy")
    print("  • pps_comparison_all_strategies.png - Side-by-side comparison")
    print()
    print("KEY OBSERVATIONS FROM CHARTS:")
    print("  1. Continuous yield: Small, frequent PPS increases → tiny drops from skim")
    print("  2. Daily harvest: Moderate jumps every 24h → small drops from skim")
    print("  3. Weekly harvest: Larger jumps every 7d → larger drops from skim")
    print("  4. Monthly harvest: HUGE jumps every 30d → significant drops from skim")
    print()
    print("The 'User Loss Window' (orange shading) shows when users are exposed to")
    print("inflated PPS. The longer between skims, the larger the exposure.")
    print()


if __name__ == "__main__":
    main()
