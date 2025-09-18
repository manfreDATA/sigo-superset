#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Utilidades (si no está lib.sh, definimos helpers mínimos)
# ──────────────────────────────────────────────────────────────────────────────
if [[ -f "$(dirname "$0")/lib.sh" ]]; then
  source "$(dirname "$0")/lib.sh"
else
  info()    { printf "\e[34m➤ %s\e[0m\n" "$*"; }
  warn()    { printf "\e[33m⚠ %s\e[0m\n" "$*"; }
  error()   { printf "\e[31m✖ %s\e[0m\n" "$*"; }
  success() { printf "\e[32m✔ %s\e[0m\n" "$*"; }
fi
: "${SUPERSET_ROOT:?Debes exportar SUPERSET_ROOT (p.ej. /path/a/tu/repo/superset)}"
: "${MODE:=prod}"  # prod|dev

cd "${SUPERSET_ROOT}"

FE_DIR="${SUPERSET_ROOT}/superset-frontend"
PKG_JSON="${FE_DIR}/package.json"
LOCK_JSON="${FE_DIR}/package-lock.json"

# ──────────────────────────────────────────────────────────────────────────────
# 1) Pre-chequeos de entorno Node/npm (recomendado Node 20 para evitar sorpresas)
#    (npm ci requiere lockfile en sync; ver docs oficiales)
# ──────────────────────────────────────────────────────────────────────────────
if ! command -v npm >/dev/null 2>&1; then
  warn "npm no está en PATH. Aun así intentaremos continuar, pero se recomienda Node 20 local."
else
  NODEVER="$(node -v 2>/dev/null || echo "v?")"
  if [[ ! "${NODEVER}" =~ ^v20\. ]]; then
    warn "Se recomienda Node 20.x local (Docker usa Node 20 en la etapa superset-node-ci). Detectado: ${NODEVER}"
  fi
fi
# ──────────────────────────────────────────────────────────────────────────────
# 2) Sincronizar lockfile: generar/actualizar package-lock.json desde package.json
#    Esto evita el error 'npm ci can only install...' dentro del contenedor.
#    (npm ci es estricto y no actualiza el lock por ti)
# ──────────────────────────────────────────────────────────────────────────────
if [[ -f "${PKG_JSON}" ]]; then
  info "Sincronizando package-lock.json con package.json en superset-frontend…"
  pushd "${FE_DIR}" >/dev/null

  # Desactivar prompts/telemetría
  export npm_config_fund=false
  export npm_config_audit=false

  set +e
  npm install --package-lock-only --no-audit --no-fund
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    warn "Fallo 'npm install --package-lock-only'; reintentando con --legacy-peer-deps (locks antiguos/peers estrictos)…"
    npm install --package-lock-only --no-audit --no-fund --legacy-peer-deps
  fi

  if [[ ! -f "${LOCK_JSON}" ]]; then
    error "No se generó ${LOCK_JSON}. Revisa tu npm/node local."
    exit 1
  fi

  # Si es repo git, intentamos comitear el lock actualizado
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if ! git diff --quiet -- package-lock.json; then
      git add package-lock.json
      if git -c user.useConfigOnly=true commit -m "chore(frontend): sync package-lock.json with package.json for CI (npm ci)" >/dev/null 2>&1; then
        success "Commit creado para package-lock.json actualizado."
      else
        warn "No se pudo crear el commit (¿falta user.name/user.email?). Deja el lock en staging; comitea manualmente:
  git add superset-frontend/package-lock.json && git commit -m \"chore(frontend): sync package-lock\""
      fi
    else
      info "package-lock.json ya estaba sincronizado; nada que comitear."
    fi
  else
    warn "Directorio no es un repo git; recuerda comitear el package-lock.json actualizado."
  fi

  popd >/dev/null
else
  warn "No existe ${PKG_JSON}; salto sincronización de lockfile."
fi

# ──────────────────────────────────────────────────────────────────────────────
# 3) Build & Run (igual que antes)
#    Nota: el Dockerfile de Superset ejecuta `npm ci` en la etapa de frontend.
#          Con el lock en sync, ese paso debería pasar sin errores.
# ──────────────────────────────────────────────────────────────────────────────
if [[ "${MODE}" == "prod" ]]; then
  info "Modo producción (non-dev, imagen inmutable)…"
  # Ajusta los archivos compose según tu repo; aquí usamos overrides si existen
  if [[ -f docker-compose-non-dev.override.yml ]]; then
    docker compose -f docker-compose-non-dev.yml -f docker-compose-non-dev.override.yml up --build -d
  else
    docker compose -f docker-compose-non-dev.yml up --build -d
  fi
else
  info "Modo desarrollo (dev compose)…"
  docker compose up -d
fi

# ──────────────────────────────────────────────────────────────────────────────
# 4) Inicialización de Superset (usuario admin, DB, etc.)
# ──────────────────────────────────────────────────────────────────────────────
info "Inicializando Superset…"
docker compose exec superset superset fab create-admin \
  --username "${SUPERSET_ADMIN_USERNAME:-admin}" \
  --firstname "${SUPERSET_ADMIN_FIRSTNAME:-Admin}" \
  --lastname "${SUPERSET_ADMIN_LASTNAME:-User}" \
  --email "${SUPERSET_ADMIN_EMAIL:-admin@example.com}" \
  --password "${SUPERSET_ADMIN_PASSWORD:-ChangeMe_Strong!}" \
  || true

docker compose exec superset superset db upgrade
docker compose exec superset superset init
success "Superset arriba. URL: http://localhost:${HOST_PORT:-8088}/"
