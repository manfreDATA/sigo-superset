#!/usr/bin/env bash
set -euo pipefail

# Top-level runner: load config, copy files, build & run superset.
# Accepts optional first argument indicating mode: "dev" or "non-dev" (default non-dev).
#
# Example:
#  ./run_all.sh           # run non-dev (production-like) compose
#  ./run_all.sh dev       # run dev compose

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SCRIPTS_DIR="${ROOT}/scripts"

MODE="${1:-non-dev}"

# Source config loader to ensure environment variables and defaults are present
# shellcheck disable=SC1091
. "${SCRIPTS_DIR}/00_load_config.sh"

echo "run_all: mode=${MODE}"
echo "run_all: ROOT=${ROOT}"
echo "run_all: using SUPERSET_DIR=${SUPERSET_DIR}"
echo "run_all: copying config files..."
# run script 06 (copy)
bash "${SCRIPTS_DIR}/06_copy_config_to_superset.sh"

echo "run_all: building & starting superset (mode=${MODE})..."
if [ "${MODE}" = "dev" ] || [ "${MODE}" = "development" ]; then
  bash "${SCRIPTS_DIR}/07_build_and_up_superset.sh" dev
else
  bash "${SCRIPTS_DIR}/07_build_and_up_superset.sh" non-dev
fi

echo "run_all: done."