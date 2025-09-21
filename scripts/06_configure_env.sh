#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${SUPERSET_ROOT:?}"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${SUPERSET_ROOT}"

# Copia .env-local al root del repo (al nivel del compose)
if [[ ! -f "${SUPERSET_ROOT}/.env" ]]; then
  cp "${BASE_DIR}/config/.env" "${SUPERSET_ROOT}/.env"
fi

# Genera SECRET_KEY si placeholder
if grep -q "__GENERATE_ME__" "${SUPERSET_ROOT}/.env"; then
  SK=$(openssl rand -hex 32)
  sed -i "s|SUPERSET_SECRET_KEY=__GENERATE_ME__|SUPERSET_SECRET_KEY=${SK}|g" "${SUPERSET_ROOT}/.env"
  info "Generado SUPERSET_SECRET_KEY en .env"
fi

# Crea directorio pythonpath_dev y copia superset_config_docker.py
mkdir -p docker/pythonpath_dev
cp -f "${BASE_DIR}/config/superset_config_docker.py" docker/pythonpath_dev/superset_config_docker.py

# Drivers adicionales (PostgreSQL)
mkdir -p docker
if [[ -f "${BASE_DIR}/config/requirements-local.txt" ]]; then
  cp -f "${BASE_DIR}/config/requirements-local.txt" docker/requirements-local.txt
  info "Agregado driver de PostgreSQL (psycopg2-binary) en docker/requirements-local.txt"
fi

# Copia override para non-dev
cp -f "${BASE_DIR}/config/docker-compose-non-dev.override.yml" "${SUPERSET_ROOT}/docker-compose-non-dev.override.yml"

# Refuerzo opcional: asegurar .npmrc en superset-frontend
if [[ -f "${SUPERSET_ROOT}/superset-frontend/package.json" ]]; then
  cat > "${SUPERSET_ROOT}/superset-frontend/.npmrc" <<'NPMRC'
legacy-peer-deps=true
audit=false
fund=false
NPMRC
fi


success "Archivos de configuración listos (.env, superset_config_docker.py, requirements-local.txt, override compose)."
