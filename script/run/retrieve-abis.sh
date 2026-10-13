#!/usr/bin/env bash

set -euo pipefail

# Optional exact contract name keeps standalone component exports scoped.
requested_contract="${1:-}"
found_contract=false

# Navigate to the out directory
cd ./out

# Loop over all directories
for contract_dir in */; do
  # Find the JSON file inside the contract directory
  for json_file in "$contract_dir"*.json; do
    # Check if the JSON file exists
    if [[ -f "$json_file" ]]; then
      # Check if the JSON file contains the "abi" field
      if jq -e '.abi' "$json_file" > /dev/null 2>&1; then
        # Extract the base name of the contract (without extension)
        contract_name=$(basename "$json_file" .json)
        if [[ -n "$requested_contract" && "$contract_name" != "$requested_contract" ]]; then
          continue
        fi
        found_contract=true

        # Generate the ABI file path
        abi_file="${contract_dir}${contract_name}.abi"

        # Extract the ABI from the JSON and write it to the ABI file
        jq '.abi' "$json_file" > "$abi_file"
      fi
    fi
  done
done

if [[ -n "$requested_contract" && "$found_contract" == false ]]; then
  echo "No compiled ABI found for $requested_contract" >&2
  exit 1
fi
