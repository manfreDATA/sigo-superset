#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${SUPERSET_ROOT:?}"

cd "${SUPERSET_ROOT}/superset-frontend"

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
  console.log("Registrado en MainPreset.js");
} else {
  console.log("Ya estaba registrado.");
}
NODE

success "Plugin registrado en MainPreset.js."
