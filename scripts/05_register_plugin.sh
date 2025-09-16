#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${SUPERSET_ROOT:?}"

cd "${SUPERSET_ROOT}/superset-frontend"

# Registrar el plugin en MainPreset.js
node <<'NODE'
const fs = require('fs'), p='src/visualizations/presets/MainPreset.js';
let s = fs.readFileSync(p,'utf8');
if(!s.includes("superset-plugin-chart-echarts-extras")){
  s = s.replace(/(^import .*\n)(?=export default)/m,
`$1import {
  EchartsDatasetLinkPlugin,
  EchartsDatasetSeriesLayoutByPlugin,
  EchartsBarYStackPlugin,
  EchartsBarNegativePlugin,
  EchartsMatrixMiniBarGeoPlugin,
} from 'superset-plugin-chart-echarts-extras';
`);
  s = s.replace(/plugins:\s*\[/m, `plugins: [
    new EchartsDatasetLinkPlugin().configure({ key: 'echarts-dataset-link' }),
    new EchartsDatasetSeriesLayoutByPlugin().configure({ key: 'echarts-dataset-layout' }),
    new EchartsBarYStackPlugin().configure({ key: 'echarts-bar-y-stack' }),
    new EchartsBarNegativePlugin().configure({ key: 'echarts-bar-negative' }),
    new EchartsMatrixMiniBarGeoPlugin().configure({ key: 'echarts-matrix-mini-bar-geo' }),`);
  fs.writeFileSync(p,s);
  console.log("✅ Registrado en MainPreset.js");
} else {
  console.log("ℹ️ Ya estaba registrado.");
}
NODE
# Verificación dura de React 17 (no permitir upgrades accidentales)
node <<'NODE'
const pkg = require('./package.json');
const assert = (c,m)=>{ if(!c){ console.error('✖',m); process.exit(1);} };
assert(pkg.dependencies?.react === '17.0.2', 'package.json: react debe mantenerse 17.0.2');
assert(pkg.dependencies?.['react-dom'] === '17.0.2', 'package.json: react-dom debe mantenerse 17.0.2');
const reactVersion = require('react/package.json').version;
const reactDomVersion = require('react-dom/package.json').version;
assert(reactVersion.startsWith('17.'), 'node_modules: react debe ser 17.x');
assert(reactDomVersion.startsWith('17.'), 'node_modules: react-dom debe ser 17.x');
console.log('✅ React 17 verificado tras registro:', reactVersion, reactDomVersion);
NODE
success "Plugin registrado y React 17 preservado."
