#!/usr/bin/env bash
set -euo pipefail

# Carga helpers si existen
if [[ -f "$(dirname "$0")/lib.sh" ]]; then
  source "$(dirname "$0")/lib.sh"
else
  info()    { printf "\e[34m➤ %s\e[0m\n" "$*"; }
  warn()    { printf "\e[33m⚠ %s\e[0m\n" "$*"; }
  success() { printf "\e[32m✔ %s\e[0m\n" "$*"; }
fi

: "${SUPERSET_ROOT:?}"    # Debe apuntar al root del repo Superset
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${SUPERSET_ROOT}"

# 1) Copia .env si no existe
if [[ ! -f "${SUPERSET_ROOT}/.env" ]]; then
  cp "${BASE_DIR}/config/.env" "${SUPERSET_ROOT}/.env"
fi

# 2) Genera SECRET_KEY si hay placeholder
if grep -q "__GENERATE_ME__" "${SUPERSET_ROOT}/.env"; then
  SK=$(openssl rand -hex 32)
  sed -i "s/SUPERSET_SECRET_KEY=__GENERATE_ME__/SUPERSET_SECRET_KEY=${SK}/g" "${SUPERSET_ROOT}/.env"
  info "Generado SUPERSET_SECRET_KEY en .env"
fi

# 3) Copia superset_config_docker.py y requirements-local.txt (drivers)
mkdir -p docker/pythonpath_dev
cp -f "${BASE_DIR}/config/superset_config_docker.py" docker/pythonpath_dev/superset_config_docker.py

mkdir -p docker
if [[ -f "${BASE_DIR}/config/requirements-local.txt" ]]; then
  cp -f "${BASE_DIR}/config/requirements-local.txt" docker/requirements-local.txt
  info "Agregado requirements-local.txt (p.ej. psycopg2-binary) a docker/"
fi

# 4) Copia override compose para non-dev
cp -f "${BASE_DIR}/config/docker-compose-non-dev.override.yml" \
      "${SUPERSET_ROOT}/docker-compose-non-dev.override.yml"

# 5) Refuerzo npm en superset-frontend
if [[ -f "${SUPERSET_ROOT}/superset-frontend/package.json" ]]; then
  cat > "${SUPERSET_ROOT}/superset-frontend/.npmrc" <<'NPMRC'
legacy-peer-deps=true
audit=false
fund=false
NPMRC
fi

success "Configuración lista (.env, superset_config_docker.py, requirements-local.txt, override compose, .npmrc)."
