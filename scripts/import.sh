#!/usr/bin/env bash
# Snapshot a live contract into a draft watch config.
#
#   RPC_URL=https://... scripts/import.sh <name> <address> <abi-path> [chain-id] [chain-name]
#
# Writes watch/<name>.hcl. Review it before committing:
#   - move managed (top-level) attributes into the `expect` block — this repo
#     watches, it never proposes calls
#   - delete values that change on their own (prices, supplies, round ids,
#     timestamps); keep owners, admins, fees, flags, pointers to other contracts
#   - add a comment with an explorer link for every address
set -euo pipefail

if [ $# -lt 3 ]; then
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
fi

name=$1
address=$2
abi=$3
chain_id=${4:-1}
chain_name=${5:-ethereum}
out="watch/${name}.hcl"

: "${RPC_URL:?set RPC_URL to a JSON-RPC endpoint}"

if [ -e "$out" ]; then
  echo "error: ${out} already exists" >&2
  exit 1
fi

chainform import \
  --address "$address" \
  --abi "$abi" \
  --name "$name" \
  --chain-id "$chain_id" \
  --chain-name "$chain_name" \
  --rpc "$RPC_URL" \
  -o "$out"

chainform validate -f "$out"
echo "Wrote ${out} — review it (see the notes at the top of this script) before committing."
