#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${SUPERSET_ROOT:?}"

FRONTEND_DIR="${SUPERSET_ROOT}/superset-frontend"
if [[ ! -d "${FRONTEND_DIR}" ]]; then
  error "No existe ${FRONTEND_DIR}. ¿Clonaste el repo?"
  exit 1
fi

info "Forzando React 17 en superset-frontend (dependencies + overrides)…"
cd "${FRONTEND_DIR}"

node <<'NODE'
const fs = require('fs');
const p = 'package.json';
const pkg = JSON.parse(fs.readFileSync(p,'utf8'));
pkg.dependencies = pkg.dependencies || {};
pkg.devDependencies = pkg.devDependencies || {};
pkg.dependencies['react'] = '17.0.2';
pkg.dependencies['react-dom'] = '17.0.2';
if (pkg.devDependencies['@types/react']) pkg.devDependencies['@types/react'] = '^17';
if (pkg.devDependencies['@types/react-dom']) pkg.devDependencies['@types/react-dom'] = '^17';
pkg.overrides = Object.assign({}, pkg.overrides, {
  'react': '17.0.2',
  'react-dom': '17.0.2',
  '@types/react': '^17',
  '@types/react-dom': '^17'
});
fs.writeFileSync(p, JSON.stringify(pkg, null, 2));
console.log('React 17 aplicado a package.json (dependencies + overrides).');
NODE

npm install
success "React 17 fijado y dependencias instaladas en superset-frontend."
