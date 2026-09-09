#!/usr/bin/env bash

set -e

# Create the base directory if it doesn't exist
mkdir -p contract_bindings

# Find all ABI files directly
find ./out -name "*.abi" | while read abi_file; do
  # Extract contract name and directory from the ABI file path
  dir_path=$(dirname "$abi_file")
  base_name=$(basename "$abi_file" .abi)
  
  # Extract directory name to check if it's a test file
  dir_name=$(basename "$dir_path")
  
  # Convert to lowercase for comparison
  base_name_lower=$(echo "$base_name" | tr '[:upper:]' '[:lower:]')
  dir_name_lower=$(echo "$dir_name" | tr '[:upper:]' '[:lower:]')

  # Define allowed contract prefixes and suffixes for flexible matching
declare -a ALLOWED_PREFIXES=(
  "SuperGovernor"
  "FixedPriceOracle"
  "SuperOracle"
  "SuperOracleL2"
  "SuperBank"
  "SuperVault"
  "SuperVaultAggregator"
  "SuperVaultStrategy"
)

declare -a ALLOWED_SUFFIXES=(
  "PPSOracle"
)

# Check if contract name matches any allowed prefix or suffix
contract_allowed=false

# Check prefixes
for prefix in "${ALLOWED_PREFIXES[@]}"; do
  if [[ "$base_name" == "$prefix"* ]]; then
    contract_allowed=true
    break
  fi
done

# If no prefix match, check suffixes
if [[ "$contract_allowed" == false ]]; then
  for suffix in "${ALLOWED_SUFFIXES[@]}"; do
    if [[ "$base_name" == *"$suffix" ]]; then
      contract_allowed=true
      break
    fi
  done
fi

if [[ "$contract_allowed" == false ]]; then
  continue
fi

# Skip interface contracts (starting with I), mock contracts, and test helpers
if [[ "$base_name" == I* || "$base_name" == Mock* || "$base_name" == *Targets || "$base_name" == *TestHelpers || "$base_name" == *Lib ]]; then
  continue
fi
  
  # Only process contracts that start with Super and don't end with hook
  if [[ "$base_name_lower" == *hook || "$dir_name" == *.t.sol ]]; then
    continue
  fi
  
  # Create directory for this contract
  mkdir -p "contract_bindings/${base_name}"
  

    abigen --abi "$abi_file" \
        --pkg "$base_name" \
        --type "$base_name" \
        --alias "_asset=${base_name}Asset" \
        --alias "_totalAssets=${base_name}TotalAssets" \
        --out "contract_bindings/${base_name}/${base_name}.go"
done

# Disable debugging
set +x

echo "Contract bindings generated successfully" 