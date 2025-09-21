#!/usr/bin/env bash
set -euo pipefail

# Run all scripts in scripts/ with numeric prefixes 00..07 in order.
#  - source 00_load_config.sh (so exported vars are available to child processes)
#  - execute other scripts (01..07) with bash in numeric order if present

ROOT="$(cd ""$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SCRIPTS_DIR="${ROOT}/scripts"

# Allow globs that don't match to expand to nothing
shopt -s nullglob

# Source loader if present so subsequent scripts inherit exported env vars
if [ -f "${SCRIPTS_DIR}/00_load_config.sh" ]; then
  echo "Sourcing ${SCRIPTS_DIR}/00_load_config.sh"
  # shellcheck disable=SC1091
  . "${SCRIPTS_DIR}/00_load_config.sh"
else
  echo "Warning: ${SCRIPTS_DIR}/00_load_config.sh not found; proceeding to execute other scripts."
fi

# Iterate numeric prefixes 00..07
for idx in 0 1 2 3 4 5 6 7; do
  prefix=$(printf "%02d" "$idx")
  # find files starting with the prefix and an underscore (e.g., 06_copy_config_to_superset.sh)
  for script in "${SCRIPTS_DIR}/${prefix}_