#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${SUPERSET_ROOT:?}"

cd "${SUPERSET_ROOT}/superset-frontend"

# Registro en MainPreset.js
node <<'NODE'
const fs = require('fs'), p='src/visualizations/presets/MainPreset.js';
let s = fs.readFileSync(p,'utf8');
if(!s.includes("plugin-chart-echarts-sigo")){
  s = s.replace(/(^import .*\n)(?=export default)/m,
`$1import {
  EchartsDatasetLinkPlugin,
  EchartsDatasetSeriesLayoutByPlugin,
  EchartsBarYStackPlugin,
  EchartsBarNegativePlugin,
  EchartsMatrixMiniBarGeoPlugin,
} from 'plugin-chart-echarts-sigo';
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

# Verificación dura de React 17 post-registro (por si algo tocó node_modules)
node <<'NODE'
const pkg = require('./package.json');
const assert = (c,m)=>{ if(!c){ console.error('✖',m); process.exit(1);} };
assert(pkg.dependencies?.react === '17.0.2', 'package.json: react debe mantenerse 17.0.2');
assert(pkg.dependencies?.['react-dom'] === '17.0.2', 'package.json: react-dom debe mantenerse 17.0.2');
const rv = require('react/package.json').version;
const rdv = require('react-dom/package.json').version;
assert(rv.startsWith('17.'), 'node_modules: react debe ser 17.x');
assert(rdv.startsWith('17.'), 'node_modules: react-dom debe ser 17.x');
console.log('✅ React 17 verificado tras registro:', rv, rdv);
NODE

success "Plugin registrado y React 17 preservado."
