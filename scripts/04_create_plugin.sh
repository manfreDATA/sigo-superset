#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
: "${SUPERSET_ROOT:?}"
: "${ECHARTS_TARGET_MAJOR:=6}"

cd "${SUPERSET_ROOT}"

info "Creando skeleton de plugin ECharts extras (5 charts) con peerDependencies React 17…"
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
    "react": "^17",
    "react-dom": "^17",
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

cat > "$SRC_DIR/datasetLink/transformProps.ts" <<'EOP'
import { ChartProps } from '@superset-ui/core';
export default function transformProps({ height, width, queriesData }: ChartProps) {
 const data = (queriesData?.[0]?.data ?? []) as Array<Record<string, any>>;
 const columns = Object.keys(data[0] ?? {});
 const source: any[] = [columns, ...data.map(row => columns.map(c => row[c]))];
 const option = { legend: {}, tooltip: {}, dataset: { source }, xAxis: { type: 'category' }, yAxis: {},
  series: Array(Math.max(0, columns.length - 1)).fill(0).map(() => ({ type: 'bar' })) };
 return { height, width, echartOptions: option };
}
EOP
cat > "$SRC_DIR/datasetLink/Chart.tsx" <<'EOP'
import React from 'react'; import EchartBase from '../shared/EchartBase';
export default function Chart({ height, width, echartOptions }: any) {
 return <EchartBase height={height} width={width} option={echartOptions} />;
}
EOP
cat > "$SRC_DIR/datasetLink/index.ts" <<'EOP'
import { ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike'; import transformProps from './transformProps';
export default class EchartsDatasetLinkPlugin extends ChartPlugin {
 constructor() { super({ loadChart: () => import('./Chart'), metadata: new ChartMetadata({
  name: t('ECharts Dataset Link'), credits: ['Apache ECharts'], tags: ['ECharts','Dataset'],
 }), transformProps, controlPanel }); }
}
EOP

cat > "$SRC_DIR/datasetSeriesLayoutBy/transformProps.ts" <<'EOP'
import { ChartProps } from '@superset-ui/core';
export default function transformProps({ height, width, queriesData }: ChartProps) {
 const data = (queriesData?.[0]?.data ?? []) as Array<Record<string, any>>;
 const cols = Object.keys(data[0] ?? {});
 const source: any[] = [cols, ...data.map(r => cols.map(c => r[c]))];
 const option = { legend: {}, tooltip: {}, dataset: { source },
  grid: [{ bottom: '55%' }, { top: '58%' }],
  xAxis: [{ type: 'category', gridIndex: 0 }, { type: 'category', gridIndex: 1 }],
  yAxis: [{ gridIndex: 0 }, { gridIndex: 1 }],
  series: [
   { type: 'bar', seriesLayoutBy: 'row' },
   { type: 'bar', seriesLayoutBy: 'row' },
   { type: 'bar', seriesLayoutBy: 'row' },
   { type: 'bar', xAxisIndex: 1, yAxisIndex: 1 },
   { type: 'bar', xAxisIndex: 1, yAxisIndex: 1 },
   { type: 'bar', xAxisIndex: 1, yAxisIndex: 1 },
  ]};
 return { height, width, echartOptions: option };
}
EOP
cat > "$SRC_DIR/datasetSeriesLayoutBy/Chart.tsx" <<'EOP'
import React from 'react'; import EchartBase from '../shared/EchartBase';
export default function Chart({ height, width, echartOptions }: any) {
 return <EchartBase height={height} width={width} option={echartOptions} />;
}
EOP
cat > "$SRC_DIR/datasetSeriesLayoutBy/index.ts" <<'EOP'
import { ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike'; import transformProps from './transformProps';
export default class EchartsDatasetSeriesLayoutByPlugin extends ChartPlugin {
 constructor() { super({ loadChart: () => import('./Chart'), metadata: new ChartMetadata({
  name: t('ECharts Dataset SeriesLayoutBy'), credits: ['Apache ECharts'], tags: ['ECharts','Dataset'],
 }), transformProps, controlPanel }); }
}
EOP

cat > "$SRC_DIR/barYStack/transformProps.ts" <<'EOP'
import { ChartProps } from '@superset-ui/core';
export default function transformProps({ height, width, queriesData }: ChartProps) {
 const rows = (queriesData?.[0]?.data ?? []) as Array<Record<string, any>>;
 if (!rows.length) return { height, width, echartOptions: { series: [] } };
 const yLabels = rows.map(r => r.y ?? r.category ?? r.label ?? '');
 const keys = Object.keys(rows[0]).filter(k => !['y','category','label'].includes(k));
 const option = { tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } }, legend: {},
  xAxis: { type: 'value' }, yAxis: { type: 'category', data: yLabels },
  series: keys.map(k => ({ name: k, type: 'bar', stack: 'total', data: rows.map(r => r[k] ?? 0) })) };
 return { height, width, echartOptions: option };
}
EOP
cat > "$SRC_DIR/barYStack/Chart.tsx" <<'EOP'
import React from 'react'; import EchartBase from '../shared/EchartBase';
export default function Chart({ height, width, echartOptions }: any) {
 return <EchartBase height={height} width={width} option={echartOptions} />;
}
EOP
cat > "$SRC_DIR/barYStack/index.ts" <<'EOP'
import { ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '..//shared/controlPanelBarLike'; import transformProps from './transformProps';
export default class EchartsBarYStackPlugin extends ChartPlugin {
 constructor() { super({ loadChart: () => import('./Chart'), metadata: new ChartMetadata({
  name: t('ECharts Stacked Bar (Y Category)'), credits: ['Apache ECharts'], tags: ['ECharts','Bar','Stacked'],
 }), transformProps, controlPanel }); }
}
EOP

cat > "$SRC_DIR/barNegative/transformProps.ts" <<'EOP'
import { ChartProps } from '@superset-ui/core';
export default function transformProps({ height, width, queriesData }: ChartProps) {
 const rows = (queriesData?.[0]?.data ?? []) as Array<Record<string, any>>;
 if (!rows.length) return { height, width, echartOptions: { series: [] } };
 const yLabels = rows.map(r => r.y ?? r.category ?? r.label ?? '');
 const keys = Object.keys(rows[0]).filter(k => !['y','category','label'].includes(k));
 const option = { tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } }, legend: { data: keys },
  xAxis: [{ type: 'value' }], yAxis: [{ type: 'category', axisTick: { show: false }, data: yLabels }],
  series: keys.map(k => ({ name: k, type: 'bar', data: rows.map(r => r[k] ?? 0) })) };
 return { height, width, echartOptions: option };
}
EOP
cat > "$SRC_DIR/barNegative/Chart.tsx" <<'EOP'
import React from 'react'; import EchartBase from '../shared/EchartBase';
export default function Chart({ height, width, echartOptions }: any) {
 return <EchartBase height={height} width={width} option={echartOptions} />;
}
EOP
cat > "$SRC_DIR/barNegative/index.ts" <<'EOP'
import { ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike'; import transformProps from './transformProps';
export default class EchartsBarNegativePlugin extends ChartPlugin {
 constructor() { super({ loadChart: () => import('./Chart'), metadata: new ChartMetadata({
  name: t('ECharts Bar (Positive/Negative)'), credits: ['Apache ECharts'], tags: ['ECharts','Bar'],
 }), transformProps, controlPanel }); }
}
EOP

cat > "$SRC_DIR/matrixMiniBarGeo/transformProps.ts" <<'EOP'
import { ChartProps } from '@superset-ui/core';
export default function transformProps({ height, width, queriesData }: ChartProps) {
 const rows = (queriesData?.[0]?.data ?? []) as Array<Record<string, any>>;
 const headers = ['Region','A','B','Geo'];
 const option: any = {
  matrix: { x: { levelSize: 40, data: headers.map(h => ({ value: h })), label: { fontWeight: 'bold' } },
            y: { data: rows.map(() => '_'), show: false }, body: { data: [] }, top: 25 },
  legend: {}, tooltip: {}, grid: [], xAxis: [], yAxis: [], geo: [], series: [],
 };
 return { height, width, echartOptions: option };
}
EOP
cat > "$SRC_DIR/matrixMiniBarGeo/Chart.tsx" <<'EOP'
import React from 'react';
import * as echarts from 'echarts/core';
import { BarChart, ScatterChart } from 'echarts/charts';
import { GridComponent, TooltipComponent, LegendComponent, GeoComponent } from 'echarts/components';
import { CanvasRenderer } from 'echarts/renderers';
let MatrixComponent: any;
try { const comps = require('echarts/components'); MatrixComponent = comps?.MatrixComponent; } catch { MatrixComponent = undefined; }
const toUse: any[] = [BarChart, ScatterChart, GridComponent, TooltipComponent, LegendComponent, GeoComponent, CanvasRenderer];
if (MatrixComponent) toUse.push(MatrixComponent);
echarts.use(toUse);
import EchartBase from '../shared/EchartBase';
export default function Chart({ height, width, echartOptions }: any) {
 return <EchartBase height={height} width={width} option={echartOptions} />;
}
EOP
cat > "$SRC_DIR/matrixMiniBarGeo/index.ts" <<'EOP'
import { ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike'; import transformProps from './transformProps';
export default class EchartsMatrixMiniBarGeoPlugin extends ChartPlugin {
 constructor() { super({ loadChart: () => import('./Chart'), metadata: new ChartMetadata({
  name: t('ECharts Matrix Mini-bar + Geo (v6)'), credits: ['Apache ECharts'], tags: ['ECharts','Matrix','Experimental'],
 }), transformProps, controlPanel }); }
}
EOP

echo "✅ Plugin skeleton creado en plugins/superset-plugin-chart-echarts-extras"
EOS

chmod +x scripts/create_echarts_extras.sh
bash scripts/create_echarts_extras.sh

# Construir el plugin (esto NO instala React, solo Typescript local del plugin)
cd plugins/superset-plugin-chart-echarts-extras
npm install --no-audit --no-fund
npm run build

# Instalar el plugin en el frontend sin tocar dependencies del root
cd "${SUPERSET_ROOT}/superset-frontend"

# Reasegurar React 17 (idempotente) ANTES de cualquier npm install
node <<'NODE'
const fs = require('fs'); const p='package.json';
const pkg = JSON.parse(fs.readFileSync(p,'utf8'));
pkg.dependencies = pkg.dependencies || {};
pkg.devDependencies = pkg.devDependencies || {};
pkg.dependencies['react'] = '17.0.2';
pkg.dependencies['react-dom'] = '17.0.2';
pkg.overrides = Object.assign({}, pkg.overrides, {
  'react': '17.0.2',
  'react-dom': '17.0.2',
  '@types/react': '^17',
  '@types/react-dom': '^17'
});
fs.writeFileSync(p, JSON.stringify(pkg,null,2));
console.log('✅ React 17 reafirmado (dependencies + overrides).');
NODE

# Instalar el plugin sin guardar en package.json para no recalcular árbol
npm install --no-save ../plugins/superset-plugin-chart-echarts-extras --no-audit --no-fund --legacy-peer-deps

# Asegurar ECharts mayor seleccionado y reinstalar dependencias respetando overrides
node <<NODE
const fs = require('fs'); const p='package.json';
const pkg = JSON.parse(fs.readFileSync(p,'utf8'));
pkg.dependencies = pkg.dependencies || {};
pkg.dependencies.echarts = pkg.dependencies.echarts || '^${ECHARTS_TARGET_MAJOR}.0.0';
fs.writeFileSync(p, JSON.stringify(pkg,null,2));
console.log('ℹ️ Dependencia echarts fijada:', pkg.dependencies.echarts);
NODE

npm install --no-audit --no-fund --legacy-peer-deps

# Verificación dura de React 17 (package.json + instalado)
node <<'NODE'
const pkg = require('./package.json');
const assert = (cond, msg) => { if(!cond){ console.error('✖',msg); process.exit(1);} };
assert(pkg.dependencies?.react === '17.0.2', 'package.json: react debe ser 17.0.2');
assert(pkg.dependencies?.['react-dom'] === '17.0.2', 'package.json: react-dom debe ser 17.0.2');
const reactVersion = require('react/package.json').version;
const reactDomVersion = require('react-dom/package.json').version;
assert(reactVersion.startsWith('17.'), 'node_modules: react debe ser 17.x');
assert(reactDomVersion.startsWith('17.'), 'node_modules: react-dom debe ser 17.x');
console.log('✅ Verificación React 17 OK:', reactVersion, reactDomVersion);
NODE
success "Plugin creado, instalado y React 17 preservado."
