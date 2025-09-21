#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${BASE_DIR}/scripts/lib.sh"

detect_compose_cmd
ensure_docker_running

# Prepara args de compose (-f para cada archivo)
IFS=',' read -r -a COMPOSE_FILES <<< "${DOCKER_COMPOSE_FILES:?Define DOCKER_COMPOSE_FILES}"
COMPOSE_ARGS=()
for f in "${COMPOSE_FILES[@]}"; do
  if [[ -f "${BASE_DIR}/${f}" ]]; then
    COMPOSE_ARGS+=( -f "${BASE_DIR}/${f}" )
  else
    warn "Archivo docker-compose no encontrado: ${f}"
  fi
done

# Usa el .env del proyecto si lo tienes fuera de raíz
COMPOSE_ENV_ARGS=()
if [[ -f "${BASE_DIR}/config/.env" ]]; then
  COMPOSE_ENV_ARGS+=( --env-file "${BASE_DIR}/config/.env" )
fi

# Nombre del proyecto (para aislar redes/volúmenes)
: "${COMPOSE_PROJECT_NAME:=superset}"
export COMPOSE_PROJECT_NAME

info "Archivos Compose: ${DOCKER_COMPOSE_FILES}"
info "Proyecto Compose: ${COMPOSE_PROJECT_NAME}"

# Opcionalmente actualiza imágenes base (no falla si no hay registry)
$DOCKER_COMPOSE "${COMPOSE_ENV_ARGS[@]}" "${COMPOSE_ARGS[@]}" pull || true

# Levanta con build y orphans fuera; intenta esperar healthchecks si la versión lo soporta
if $DOCKER_COMPOSE version >/dev/null 2>&1 && $DOCKER_COMPOSE version 2>/dev/null | grep -q "Docker Compose version"; then
  # Compose v2: soporta --wait (según versión)
  if $DOCKER_COMPOSE "${COMPOSE_ENV_ARGS[@]}" "${COMPOSE_ARGS[@]}" up -d --build --remove-orphans --wait; then
    success "Stack levantado y saludable (healthchecks OK)."
  else
    warn "Tu Compose podría no soportar --wait. Levantando sin esperar healthchecks…"
    $DOCKER_COMPOSE "${COMPOSE_ENV_ARGS[@]}" "${COMPOSE_ARGS[@]}" up -d --build --remove-orphans
  fi
else
  # Compose v1
  $DOCKER_COMPOSE "${COMPOSE_ENV_ARGS[@]}" "${COMPOSE_ARGS[@]}" up -d --build --remove-orphans
fi

# Muestra estado y cómo ver logs
$DOCKER_COMPOSE "${COMPOSE_ENV_ARGS[@]}" "${COMPOSE_ARGS[@]}" ps
info "Logs (Ctrl+C para salir):"
echo "$DOCKER_COMPOSE ${COMPOSE_ENV_ARGS[*]} ${COMPOSE_ARGS[*]} logs -f --tail=200"

HOST_PORT_SHOW="${HOST_PORT:-8088}"
success "Superset debería estar en: http://localhost:${HOST_PORT_SHOW}"
