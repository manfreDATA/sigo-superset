#!/usr/bin/env bash
set -euo pipefail

# Top-level runner adapted to the "variables and config" approach:
# - loads scripts/lib.sh (provides run_step, info, success, require_root, ...)
# - prefers scripts/00_load_config.sh to export/configure variables
# - falls back to config/flags.env if loader is not present
# - runs the numbered pipeline steps via run_step

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SCRIPTS_DIR="${ROOT}/scripts"
CONFIG_DIR="${ROOT}/config"



# shellcheck disable=SC1091
if [ -f "${SCRIPTS_DIR}/lib.sh" ]; then
  # Load helper library (run_step, info, success, require_root, etc.)
  . "${SCRIPTS_DIR}/lib.sh"
else
  echo "ERROR: ${SCRIPTS_DIR}/lib.sh not found. Aborting." >&2
  exit 1
fi

require_root


# Prefer the canonical loader in scripts/ which exports and arranges all variables.
if [ -f "${SCRIPTS_DIR}/00_load_config.sh" ]; then
  info "Cargando configuración desde ${SCRIPTS_DIR}/00_load_config.sh"
  # shellcheck disable=SC1091
  . "${SCRIPTS_DIR}/00_load_config.sh"
else
  if [ -f "${CONFIG_DIR}/.env-local" ]; then
    info "Cargando flags desde ${CONFIG_DIR}/.env-local"
    set -a
    # shellcheck disable=SC1091
    . "${CONFIG_DIR}/.env-local"
    set +a
  else
    echo "ERROR: No configuration found (expected ${CONFIG_DIR}/.env-local)." >&2
    exit 1
  fi
fi
  # Fallback: source .env-local and export its variables



# Run pipeline steps (use the same names as in your original script)
run_step "01_docker.sh"
run_step "02_clone_superset.sh"
#run_step "02b_build_superset.sh"
run_step "03_node_npm.sh"
run_step "03b_pin_react17.sh"
run_step "04_create_plugin.sh"
run_step "05_register_plugin.sh"
run_step "06_copy_config_to_superset.sh"
run_step "07_build_and_up_superset.sh"

success "Pipeline completado. Visita http://localhost:${HOST_PORT} (usuario: ${SUPERSET_ADMIN_USERNAME}, ver config/.env-local)."
# ─────────────────────────────────────────────────────────────────────────────
# 1) Skeleton del plugin (idempotente)
# ─────────────────────────────────────────────────────────────────────────────
info "Creando/actualizando skeleton del plugin…"
PLUGIN_DIR="plugins/plugin-chart-echarts-sigo"
SRC_DIR="${PLUGIN_DIR}/src"
mkdir -p "${SRC_DIR}"/{shared,datasetLink,datasetSeriesLayoutBy,barYStack,barNegative,matrixMiniBarGeo}

# package.json (incluye plugin-chart-echarts para importar legendSection)
cat > "${PLUGIN_DIR}/package.json" <<'EOP'
{
  "name": "plugin-chart-echarts-sigo",
  "version": "0.1.0",
  "description": "ECharts extras for Apache Superset",
  "license": "Apache-2.0",
  "main": "lib/index.js",
  "types": "lib/index.d.ts",
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "dev": "tsc -w -p tsconfig.json"
  },
  "peerDependencies": {
    "@superset-ui/core": ">=0.20.0",
    "@superset-ui/chart-controls": ">=0.20.0",
    "react": ">=16.13.1 <18",
    "react-dom": ">=16.13.1 <18",
    "echarts": ">=5.0.0"
  },
  "devDependencies": {
    "typescript": "^5.4.0",
    "@types/react": "^17.0.0",
    "@types/react-dom": "^17.0.0",
    "@types/node": "^20.0.0",
    "echarts": "^5.4.0",
    "@superset-ui/core": "*",
    "@superset-ui/chart-controls": "*",
    "@superset-ui/plugin-chart-echarts": "*"
  }
}
EOP