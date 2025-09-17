#!/usr/bin/env bash
set -euo pipefail

# Utilidades (si existen)
if [[ -f "$(dirname "$0")/lib.sh" ]]; then
  source "$(dirname "$0")/lib.sh"
else
  info()    { printf "\e[34m➤ %s\e[0m\n" "$*"; }
  warn()    { printf "\e[33m⚠ %s\e[0m\n" "$*"; }
  error()   { printf "\e[31m✖ %s\e[0m\n" "$*"; }
  success() { printf "\e[32m✔ %s\e[0m\n" "$*"; }
fi

: "${SUPERSET_ROOT:?}"
: "${MODE:=prod}"

cd "${SUPERSET_ROOT}"

# ──────────────────────────────────────────────────────────────────────────────
# Pre‑hook: normalizar `overrides` del package.json (resolver $referencias)
# Motivo: npm falla con "Unable to resolve reference $react-dom" si hay
# overrides con "$dep" y 'dep' no está declarado en dependencias raíz.
# Referencias: npm docs sobre overrides y limitaciones con $refs.
# ──────────────────────────────────────────────────────────────────────────────
FE_DIR="${SUPERSET_ROOT}/superset-frontend"
PKG_JSON="${FE_DIR}/package.json"
BACKUP="${FE_DIR}/package.json.bak_overrides"

if [[ -f "${PKG_JSON}" ]]; then
  info "Normalizando overrides en superset-frontend/package.json (si aplica)…"
  cp -f "${PKG_JSON}" "${BACKUP}"
  trap 'if [[ -f "'"${BACKUP}"'" ]]; then mv -f "'"${BACKUP}"'" "'"${PKG_JSON}"'"; fi' EXIT

  node -e '
    const fs = require("fs");
    const p = "'"${PKG_JSON}"'";
    const pkg = JSON.parse(fs.readFileSync(p, "utf8"));
    const rootVer = (name) =>
      (pkg.dependencies && pkg.dependencies[name]) ||
      (pkg.devDependencies && pkg.devDependencies[name]) ||
      null;

    let changed = false;
    function resolveDollar(obj, trail=[]) {
      if (!obj || typeof obj !== "object") return;
      for (const k of Object.keys(obj)) {
        const v = obj[k];
        const here = trail.concat(k).join(".");
        if (typeof v === "string" && v.startsWith("$")) {
          const ref = v.slice(1);
          const ver = rootVer(ref);
          if (!ver) {
            console.error(`✖ Override referencia $${ref} en '${here}', pero '${ref}' no está en dependencies/devDependencies del package.json raíz.`);
            process.exit(2);
          }
          obj[k] = ver;
          changed = true;
          console.log(`↺ Resuelto ${here}: "${v}" -> "${ver}"`);
        } else if (v && typeof v === "object") {
          resolveDollar(v, trail.concat(k));
        }
      }
    }

    if (pkg.overrides) {
      resolveDollar(pkg.overrides, ["overrides"]);
      if (changed) {
        fs.writeFileSync(p, JSON.stringify(pkg, null, 2));
        console.log("✅ Overrides normalizados en package.json");
      } else {
        console.log("ℹ️ No se encontraron $referencias en overrides");
      }
    } else {
      console.log("ℹ️ package.json no define overrides");
    }
  '
else
  warn "No se encontró ${PKG_JSON}; continuo sin normalizar overrides."
fi

# ──────────────────────────────────────────────────────────────────────────────
# Build & run (tu lógica original)
# ──────────────────────────────────────────────────────────────────────────────
if [[ "${MODE}" == "prod" ]]; then
  info "Modo producción (non-dev, imagen inmutable)…"
  info "Reconstruyendo imagen para incluir plugin y drivers locales (psycopg2-binary)…"
  docker compose -f docker-compose-non-dev.yml -f docker-compose-non-dev.override.yml up --build -d
else
  info "Modo desarrollo (dev compose)…"
  docker compose up -d
fi
# Restaurar el package.json original tras el build
if [[ -f "${BACKUP}" ]]; then
  mv -f "${BACKUP}" "${PKG_JSON}"
  trap - EXIT
fi

# ──────────────────────────────────────────────────────────────────────────────
# Inicialización (admin, DB, roles)
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
