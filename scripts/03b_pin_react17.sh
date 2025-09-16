#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${SUPERSET_ROOT:?}"

FRONTEND_DIR="${SUPERSET_ROOT}/superset-frontend"
if [[ ! -d "${FRONTEND_DIR}" ]]; then
  error "No existe ${FRONTEND_DIR}. ¿Clonaste el repo?"
  exit 1
fi

info "Fijando React 17 en superset-frontend (dependencies + overrides) y configurando .npmrc…"
cd "${FRONTEND_DIR}"

# 1) package.json: dependencies + devDependencies + overrides ($alias)
node <<'NODE'
const fs = require('fs');
const p = 'package.json';
const pkg = JSON.parse(fs.readFileSync(p,'utf8'));

pkg.dependencies = pkg.dependencies || {};
pkg.devDependencies = pkg.devDependencies || {};
pkg.overrides = pkg.overrides || {};

// Runtime en 17
pkg.dependencies['react'] = '17.0.2';
pkg.dependencies['react-dom'] = '17.0.2';

// Types en 17 como dependencias *directas* (evita conflictos de TS)
const desiredTypesReact = '17.0.83';   // ajustable si cierras en otra 17.x
const desiredTypesReactDom = '17.0.20';// idem
pkg.devDependencies['@types/react'] = desiredTypesReact;
pkg.devDependencies['@types/react-dom'] = desiredTypesReactDom;

// Overrides: usa $alias para NO chocar con dependencias directas (evita EOVERRIDE)
pkg.overrides['react'] = '$react';
pkg.overrides['react-dom'] = '$react-dom';
pkg.overrides['@types/react'] = '$@types/react';
pkg.overrides['@types/react-dom'] = '$@types/react-dom';

fs.writeFileSync(p, JSON.stringify(pkg, null, 2));
console.log('✅ React 17 + types 17 fijados; overrides con $alias listos.');
NODE


# 2) .npmrc local para evitar recálculo estricto de peers y silenciar auditorías
cat > .npmrc <<'NPMRC'
legacy-peer-deps=true
audit=false
fund=false
NPMRC

# 3) Instalar respetando overrides (la .npmrc ya aplica legacy-peer-deps=true)
npm install --no-audit --no-fund

# 4) Verificación dura de React 17
node <<'NODE'
const pkg = require('./package.json');
const assert = (c,m)=>{ if(!c){ console.error('✖',m); process.exit(1);} };
assert(pkg.dependencies?.react === '17.0.2', 'package.json: react debe ser 17.0.2');
assert(pkg.dependencies?.['react-dom'] === '17.0.2', 'package.json: react-dom debe ser 17.0.2');
const rv = require('react/package.json').version;
const rdv = require('react-dom/package.json').version;
assert(rv.startsWith('17.'), 'node_modules: react debe ser 17.x');
assert(rdv.startsWith('17.'), 'node_modules: react-dom debe ser 17.x');
console.log('✅ React 17 verificado:', rv, rdv);
NODE

success "React 17 fijado, overrides aplicados y .npmrc creado en superset-frontend."
