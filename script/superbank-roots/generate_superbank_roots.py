#!/usr/bin/env python3
"""
Generate SuperBank per-hook merkle trees and save to disk.

SuperBank uses one merkle tree PER HOOK (unlike SuperVault's single global tree).
This script generates the trees and saves them as JSON files for consumption
by external tooling that handles on-chain root proposals (SuperGovernor
proposeSuperBankHookMerkleRoot / executeSuperBankHookMerkleRootUpdate).

Migrated from the archived superman repo (scripts/roots_management/prod/).

Usage:
    python3 generate_superbank_roots.py --chain-id 8453
    ENVIRONMENT=prod python3 generate_superbank_roots.py --chain-id 1
    python3 generate_superbank_roots.py --chain-id 999 --hooks SwapKyberSwapHook

Inputs (config/):
    superbank_hook_config.json   Per-hook argument specs (leaf definitions)
    address_registry.json        Per-chain token whitelists + tags
    deployments.json             Hook name -> deployed address per chain/env

Output:
    generated/{env}/{chain_id}/
    ├── trees_summary.json          # All hooks → roots mapping
    └── hook_0x{address}.json       # Per-hook tree with leaves and proofs
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from superbank_tree_builder import SuperBankTreeBuilder


def parse_args() -> argparse.Namespace:
    """Parse CLI arguments."""
    parser = argparse.ArgumentParser(
        description="Generate SuperBank per-hook merkle trees",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 generate_superbank_roots.py --chain-id 8453
  ENVIRONMENT=prod python3 generate_superbank_roots.py --chain-id 1
  python3 generate_superbank_roots.py --chain-id 999 --hooks SwapKyberSwapHook
        """,
    )
    parser.add_argument(
        "--chain-id",
        type=str,
        required=True,
        help="Chain id (e.g. 1, 14, 999, 8453)",
    )
    parser.add_argument(
        "--hooks",
        type=str,
        nargs="+",
        help="Only generate trees for these hooks (e.g. ApproveAndSwapOdosV3Hook SwapKyberSwapHook)",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    environment = os.getenv("ENVIRONMENT", "prod")
    chain_id = args.chain_id

    print("=" * 60)
    print("SUPERBANK MERKLE TREE GENERATION")
    print("=" * 60)
    print(f"Environment: {environment}")
    print(f"Chain ID:    {chain_id}")
    print("=" * 60)

    # Build per-hook merkle trees
    print(f"\nBuilding SuperBank merkle trees for chain {chain_id}...")
    builder = SuperBankTreeBuilder()
    trees = builder.build_all_hook_trees(
        chain_id=chain_id, environment=environment, hook_filter=args.hooks
    )

    if not trees:
        print("No hook trees generated. Check hook deployments and configuration.")
        sys.exit(1)

    print(f"\nGenerated {len(trees)} hook tree(s)")

    # Save generated trees to disk
    output_dir = builder.save_trees_to_json(trees, chain_id, environment)
    print(f"\nSaved to: {output_dir}")

    # Print summary
    print(f"\n{'=' * 60}")
    print("SUMMARY")
    print(f"{'=' * 60}")
    for hook_address, tree_data in trees.items():
        display_name = " + ".join(tree_data.hook_names)
        print(f"  {display_name}")
        print(f"    Address: {hook_address}")
        print(f"    Leaves:  {tree_data.total_leaves}")
        print(f"    Root:    0x{tree_data.root.hex()}")

    print(f"\nDone. {len(trees)} tree(s) saved to {output_dir}")


if __name__ == "__main__":
    main()
