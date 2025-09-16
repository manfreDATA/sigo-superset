#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${SUPERSET_ROOT:?}"
: "${MODE:=prod}"

cd "${SUPERSET_ROOT}"

if [[ "${MODE}" == "prod" ]]; then
  info "Modo producción (non-dev, imagen inmutable)…"
  info "Reconstruyendo imagen para incluir plugin y drivers locales (psycopg2-binary)…"
  docker compose -f docker-compose-non-dev.yml -f docker-compose-non-dev.override.yml up --build -d
else
  info "Modo desarrollo (dev compose)…"
  docker compose up -d
fi

# Inicialización (admin, DB, roles)
info "Inicializando Superset…"
docker compose exec superset superset fab create-admin \
  --username "${SUPERSET_ADMIN_USERNAME:-admin}" \
  --firstname "${SUPERSET_ADMIN_FIRSTNAME:-Admin}" \
  --lastname "${SUPERSET_ADMIN_LASTNAME:-User}" \
  --email "${SUPERSET_ADMIN_EMAIL:-admin@example.com}" \
  --password "${SUPERSET_ADMIN_PASSWORD:-ChangeMe_Strong!}" || true

docker compose exec superset superset db upgrade
docker compose exec superset superset init

success "Superset arriba. URL: http://localhost:${HOST_PORT:-8088}/"
