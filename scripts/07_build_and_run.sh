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

: "${SUPERSET_ROOT:?Debes exportar SUPERSET_ROOT (p.ej. /root/superset)}"
: "${MODE:=prod}"   # prod|dev

cd "${SUPERSET_ROOT}"

# ──────────────────────────────────────────────────────────────────────────────
# 1) Normalizar overrides en superset-frontend/package.json (resolver $refs)
#    Evita "Unable to resolve reference $react-dom" en npm (npm valida $refs).
# ──────────────────────────────────────────────────────────────────────────────
FE_DIR="${SUPERSET_ROOT}/superset-frontend"
PKG_JSON="${FE_DIR}/package.json"
LOCK_JSON="${FE_DIR}/package-lock.json"

if [[ -f "${PKG_JSON}" ]]; then
  info "Normalizando overrides en superset-frontend/package.json (si aplica)…"

  # Pasamos la ruta a Node por env; here‑doc literal evita expansión de Bash.
  PKG_PATH="${PKG_JSON}" node - <<'NODE'
const fs = require("fs");
const p = process.env.PKG_PATH;
if (!p || !fs.existsSync(p)) {
  console.log("ℹ️ package.json no encontrado; salto normalización");
  process.exit(0);
}
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
    const pathHere = [...trail, k].join(".");
    if (typeof v === "string" && v.startsWith("$")) {
      const ref = v.slice(1);
      const ver = rootVer(ref);
      if (!ver) {
        console.error(`✖ Override referencia $${ref} en '${pathHere}', ` +
          `pero '${ref}' no está en dependencies/devDependencies del package.json raíz.`);
        process.exit(2);
      }
      obj[k] = ver;
      changed = true;
      console.log(`↺ Resuelto ${pathHere}: "${v}" -> "${ver}"`);
    } else if (v && typeof v === "object") {
      resolveDollar(v, [...trail, k]);
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
NODE
else
  warn "No se encontró ${PKG_JSON}; salto normalización de overrides."
fi

# ──────────────────────────────────────────────────────────────────────────────
# 2) Actualizar y DEJAR FIJO el lock en el repo
#    (npm ci exige package.json/package-lock.json sincronizados)
# ──────────────────────────────────────────────────────────────────────────────
if [[ -f "${PKG_JSON}" ]]; then
  info "Actualizando package-lock.json para que coincida con package.json…"
  pushd "${FE_DIR}" >/dev/null

  # Genera/actualiza el lock con el package.json vigente.
  # --legacy-peer-deps ayuda cuando vienes de locks antiguos con peers estrictos.
  npm install --package-lock-only --no-audit --no-fund --legacy-peer-deps

  # Si el repo es git, intenta comitear el cambio del lock.
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # ¿Hubo cambios reales?
    if ! git diff --quiet -- package-lock.json; then
      git add package-lock.json
      # Si el usuario no tiene identidad configurada, no forzamos; mostramos hint.
      if git -c user.useConfigOnly=true commit -m "chore(frontend): sync package-lock.json with package.json for CI (npm ci validation)" >/dev/null 2>&1; then
        success "Commit creado para package-lock.json actualizado"
      else
        warn "No se pudo crear el commit (¿falta user.name/user.email?). Deja el lock en staging y comitea manualmente:"
        printf "   git add superset-frontend/package-lock.json && git commit -m \"chore(frontend): sync package-lock\"\n"
      fi
    else
      info "package-lock.json ya estaba sincronizado; nada que comitear."
    fi
  else
    warn "Directorio no es un repo git; recuerda comitear el package-lock.json actualizado."
  fi

  popd >/dev/null
fi

# ──────────────────────────────────────────────────────────────────────────────
# 3) Build & run (igual que antes)
# ──────────────────────────────────────────────────────────────────────────────
if [[ "${MODE}" == "prod" ]]; then
  info "Modo producción (non-dev, imagen inmutable)…"
  info "Reconstruyendo imagen para incluir plugin y drivers locales (psycopg2-binary)…"
  docker compose -f docker-compose-non-dev.yml -f docker-compose-non-dev.override.yml up --build -d
else
  info "Modo desarrollo (dev compose)…"
  docker compose up -d
fi

# ──────────────────────────────────────────────────────────────────────────────
# 4) Inicialización (admin, DB, roles)
# ──────────────────────────────────────────────────────────────────────────────
info "Inicializando Superset…"
docker compose exec superset superset fab create-admin \
  --username  "${SUPERSET_ADMIN_USERNAME:-admin}" \
  --firstname "${SUPERSET_ADMIN_FIRSTNAME:-Admin}" \
  --lastname  "${SUPERSET_ADMIN_LASTNAME:-User}" \
  --email     "${SUPERSET_ADMIN_EMAIL:-admin@example.com}" \
  --password  "${SUPERSET_ADMIN_PASSWORD:-ChangeMe_Strong!}" \
  || true

docker compose exec superset superset db upgrade
docker compose exec superset superset init

success "Superset arriba. URL: http://localhost:${HOST_PORT:-8088}/"
