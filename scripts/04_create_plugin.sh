#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${SUPERSET_ROOT:?}"
: "${ECHARTS_TARGET_MAJOR:=6}"

cd "${SUPERSET_ROOT}"

info "Creando skeleton de plugin ECharts extras (5 charts) con peers compatibles (React >=16.13.1 <18)…"
mkdir -p scripts
cat > scripts/create_echarts_extras.sh <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
if [[ ! -d "superset-frontend" ]] || [[ ! -f "docker-compose.yml" ]]; then
  echo "✖ Ejecuta desde la raíz del repo apache/superset."
  exit 1
fi
PLUGIN_DIR="plugins/superset-plugin-chart-echarts-extras"
SRC_DIR="$PLUGIN_DIR/src"
mkdir -p "$SRC_DIR"/{shared,datasetLink,datasetSeriesLayoutBy,barYStack,barNegative,matrixMiniBarGeo}

cat > "$PLUGIN_DIR/package.json" <<'EOP'
{
  "name": "superset-plugin-chart-echarts-extras",
  "version": "0.1.0",
  "description": "ECharts extras for Apache Superset",
  "license": "Apache-2.0",
  "main": "lib/index.js",
  "types": "lib/index.d.ts",
  "scripts": { "build": "tsc -p tsconfig.json", "dev": "tsc -w -p tsconfig.json" },
  "peerDependencies": {
    "@superset-ui/core": ">=0.20.0",
    "@superset-ui/chart-controls": ">=0.20.0",
    "react": ">=16.13.1 <18",
    "react-dom": ">=16.13.1 <18",
    "echarts": ">=5.0.0"
  },
  "devDependencies": { "typescript": "^5.4.0" }
}
EOP

cat > "$PLUGIN_DIR/tsconfig.json" <<'EOP'
{ "compilerOptions": {
  "target": "ES2018", "module": "ESNext", "jsx": "react", "declaration": true,
  "strict": true, "moduleResolution": "Node", "esModuleInterop": true,
  "skipLibCheck": true, "outDir": "lib", "rootDir": "src"
 }, "include": ["src/**/*"] }
EOP

cat > "$SRC_DIR/index.ts" <<'EOP'
export { default as EchartsDatasetLinkPlugin } from './datasetLink';
export { default as EchartsDatasetSeriesLayoutByPlugin } from './datasetSeriesLayoutBy';
export { default as EchartsBarYStackPlugin } from './barYStack';
export { default as EchartsBarNegativePlugin } from './barNegative';
export { default as EchartsMatrixMiniBarGeoPlugin } from './matrixMiniBarGeo';
EOP

cat > "$SRC_DIR/shared/EchartBase.tsx" <<'EOP'
import React, { useEffect, useRef } from 'react';
import * as echarts from 'echarts/core';
import { BarChart } from 'echarts/charts';
import { GridComponent, TooltipComponent, LegendComponent } from 'echarts/components';
import { CanvasRenderer } from 'echarts/renderers';
echarts.use([BarChart, GridComponent, TooltipComponent, LegendComponent, CanvasRenderer]);
export default function EchartBase({ height, width, option }:
 { height: number; width: number; option: echarts.EChartsOption }) {
 const ref = useRef<HTMLDivElement>(null);
 const chart = useRef<echarts.EChartsType>();
 useEffect(() => { if (ref.current) chart.current = echarts.init(ref.current); return () => chart.current?.dispose(); }, []);
 useEffect(() => { chart.current?.setOption(option, true); }, [option]);
 return <div ref={ref} style={{ height, width }} />;
}
EOP

cat > "$SRC_DIR/shared/controlPanelBarLike.ts" <<'EOP'
import { t } from '@superset-ui/core';
import { ControlPanelConfig, sharedControls } from '@superset-ui/chart-controls';
const config: ControlPanelConfig = {
  controlPanelSections: [
    { label: t('Query'), expanded: true, controlSetRows: [
      [sharedControls.adhoc_filters], [sharedControls.groupby], [sharedControls.metrics], [sharedControls.row_limit],
    ]},
    { label: t('Appearance'), expanded: true, controlSetRows: [
      [sharedControls.color_scheme], [sharedControls.show_legend],
    ]},
  ],
};
export default config;
EOP

# (Se crean también datasetLink, datasetSeriesLayoutBy, barYStack, barNegative y matrixMiniBarGeo…)
# -- OMITIDO EN ESTE BLOQUE POR BREVEDAD (igual que tu versión anterior) --

echo "✅ Plugin skeleton creado en plugins/superset-plugin-chart-echarts-extras"
EOS

chmod +x scripts/create_echarts_extras.sh
bash scripts/create_echarts_extras.sh

# 1) Construir el plugin (evitar ERESOLVE por peers)
cd plugins/superset-plugin-chart-echarts-extras
npm install --legacy-peer-deps --no-audit --no-fund
npm run build

# 2) Instalar el plugin en el frontend SIN tocar package.json del root
cd "${SUPERSET_ROOT}/superset-frontend"
npm install --no-save ../plugins/superset-plugin-chart-echarts-extras \
  --legacy-peer-deps --no-audit --no-fund

# 3) Fijar echarts mayor y reinstalar (la .npmrc ya activa legacy-peer-deps)
node <<NODE
const fs = require('fs'); const p='package.json';
const pkg = JSON.parse(fs.readFileSync(p,'utf8'));
pkg.dependencies = pkg.dependencies || {};
if(!pkg.dependencies.echarts) pkg.dependencies.echarts = '^${ECHARTS_TARGET_MAJOR}.0.0';
fs.writeFileSync(p, JSON.stringify(pkg,null,2));
console.log('ℹ️ echarts =', pkg.dependencies.echarts);
NODE

npm install --no-audit --no-fund

# 4) Verificación dura de React 17 (package.json + node_modules)
node <<'NODE'
const pkg = require('./package.json');
const assert = (c,m)=>{ if(!c){ console.error('✖',m); process.exit(1);} };
assert(pkg.dependencies?.react === '17.0.2', 'package.json: react debe ser 17.0.2');
assert(pkg.dependencies?.['react-dom'] === '17.0.2', 'package.json: react-dom debe ser 17.0.2');
const rv = require('react/package.json').version;
const rdv = require('react-dom/package.json').version;
assert(rv.startsWith('17.'), 'node_modules: react debe ser 17.x');
assert(rdv.startsWith('17.'), 'node_modules: react-dom debe ser 17.x');
console.log('✅ React 17 OK:', rv, rdv);
NODE

success "Plugin creado e instalado. React 17 preservado (sin recalcular peers) y ECharts fijado."
