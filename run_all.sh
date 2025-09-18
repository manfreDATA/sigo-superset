#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${BASE_DIR}/scripts/lib.sh"
require_root


info "Cargando flags desde config/.env"
set -a
source "${BASE_DIR}/config/.env"
set +a

info "Cargando flags desde config/flags.env"
set -a
source "${BASE_DIR}/config/flags.env"
set +a

run_step "01_docker.sh"
run_step "02_clone_superset.sh"
run_step "03_node_npm.sh"
run_step "03b_pin_react17.sh"
run_step "04_create_plugin.sh"
run_step "05_register_plugin.sh"
run_step "06_configure_env.sh"
run_step "07_build_and_run.sh"

success "Pipeline completado. Visita http://localhost:${HOST_PORT} (usuario: ${SUPERSET_ADMIN_USERNAME}, ver config/.env)."
