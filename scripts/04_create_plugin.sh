#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091

# Utilidades de logging si existen
if [[ -f "$(dirname "$0")/lib.sh" ]]; then
  source "$(dirname "$0")/lib.sh"
else
  info(){ printf "\e[34m➤ %s\e[0m\n" "$*"; }
  warn(){ printf "\e[33m⚠  %s\e[0m\n" "$*"; }
  error(){ printf "\e[31m✖  %s\e[0m\n" "$*"; }
  success(){ printf "\e[32m✔  %s\e[0m\n" "$*"; }
fi

: "${SUPERSET_ROOT:?Debes definir SUPERSET_ROOT (p.ej.: /root/superset)}"
: "${ECHARTS_TARGET_MAJOR:=6}"

cd "${SUPERSET_ROOT}"

# -------------------------------------------------------------------
# 1) CREAR/ACTUALIZAR SKELETON DEL PLUGIN (idempotente)
# -------------------------------------------------------------------
info "Creando/actualizando skeleton del plugin (idempotente)…"

PLUGIN_DIR="plugins/superset-plugin-chart-echarts-extras"
SRC_DIR="${PLUGIN_DIR}/src"
mkdir -p "${SRC_DIR}"/{shared,datasetLink,datasetSeriesLayoutBy,barYStack,barNegative,matrixMiniBarGeo}

# package.json del plugin (peerDependencies compatibles con React 17)
cat > "${PLUGIN_DIR}/package.json" <<'EOP'
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
  "devDependencies": {
    "typescript": "^5.4.0"
  }
}
EOP

# tsconfig del plugin
cat > "${PLUGIN_DIR}/tsconfig.json" <<'JSON'
{
  "compilerOptions": {
    "target": "ES2018",
    "module": "ESNext",
    "jsx": "react",
    "declaration": true,
    "strict": true,
    "moduleResolution": "Node",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "types": ["react", "react-dom"],
    "outDir": "lib",
    "rootDir": "src"
  },
  "include": ["src/**/*"]
}
JSON

# Barrel principal
cat > "${SRC_DIR}/index.ts" <<'TS'
export { default as EchartsDatasetLinkPlugin } from './datasetLink';
export { default as EchartsDatasetSeriesLayoutByPlugin } from './datasetSeriesLayoutBy';
export { default as EchartsBarYStackPlugin } from './barYStack';
export { default as EchartsBarNegativePlugin } from './barNegative';
export { default as EchartsMatrixMiniBarGeoPlugin } from './matrixMiniBarGeo';
TS

# shared/EchartBase.tsx
cat > "${SRC_DIR}/shared/EchartBase.tsx" <<'TSX'
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
TSX

# shared/controlPanelBarLike.ts
cat > "${SRC_DIR}/shared/controlPanelBarLike.ts" <<'TS'
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
TS
# datasetLink/*
cat > "${SRC_DIR}/datasetLink/transformProps.ts" <<'TS'
import { ChartProps } from '@superset-ui/core';
export default function transformProps({ height, width, queriesData }: ChartProps) {
  const data = (queriesData?.[0]?.data ?? []) as Array<Record<string, any>>;
  const columns = Object.keys(data[0] ?? {});
  const source: any[] = [columns, ...data.map(row => columns.map(c => row[c]))];
  const option = { legend: {}, tooltip: {}, dataset: { source }, xAxis: { type: 'category' }, yAxis: {},
    series: Array(Math.max(0, columns.length - 1)).fill(0).map(() => ({ type: 'bar' })) };
  return { height, width, echartOptions: option };
}
TS
cat > "${SRC_DIR}/datasetLink/Chart.tsx" <<'TSX'
import React from 'react';
import EchartBase from '../shared/EchartBase';
export default function Chart({ height, width, echartOptions }: any) {
  return <EchartBase height={height} width={width} option={echartOptions} />;
}
TSX
cat > "${SRC_DIR}/datasetLink/index.ts" <<'TS'
import { ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike';
import transformProps from './transformProps';
export default class EchartsDatasetLinkPlugin extends ChartPlugin {
  constructor() {
    super({ loadChart: () => import('./Chart'), metadata: new ChartMetadata({
      name: t('ECharts Dataset Link'), credits: ['Apache ECharts'], tags: ['ECharts','Dataset'],
    }), transformProps, controlPanel });
  }
}
TS
# datasetSeriesLayoutBy/*
cat > "${SRC_DIR}/datasetSeriesLayoutBy/transformProps.ts" <<'TS'
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
TS
cat > "${SRC_DIR}/datasetSeriesLayoutBy/Chart.tsx" <<'TSX'
import React from 'react';
import EchartBase from '../shared/EchartBase';
export default function Chart({ height, width, echartOptions }: any) {
  return <EchartBase height={height} width={width} option={echartOptions} />;
}
TSX
cat > "${SRC_DIR}/datasetSeriesLayoutBy/index.ts" <<'TS'
import { ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike';
import transformProps from './transformProps';
export default class EchartsDatasetSeriesLayoutByPlugin extends ChartPlugin {
  constructor() {
    super({ loadChart: () => import('./Chart'), metadata: new ChartMetadata({
      name: t('ECharts Dataset SeriesLayoutBy'), credits: ['Apache ECharts'], tags: ['ECharts','Dataset'],
    }), transformProps, controlPanel });
  }
}
TS
# barYStack/*
cat > "${SRC_DIR}/barYStack/transformProps.ts" <<'TS'
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
TS
cat > "${SRC_DIR}/barYStack/Chart.tsx" <<'TSX'
import React from 'react';
import EchartBase from '../shared/EchartBase';
export default function Chart({ height, width, echartOptions }: any) {
  return <EchartBase height={height} width={width} option={echartOptions} />;
}
TSX
cat > "${SRC_DIR}/barYStack/index.ts" <<'TS'
import { ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike';
import transformProps from './transformProps';
export default class EchartsBarYStackPlugin extends ChartPlugin {
  constructor() {
    super({ loadChart: () => import('./Chart'), metadata: new ChartMetadata({
      name: t('ECharts Stacked Bar (Y Category)'), credits: ['Apache ECharts'], tags: ['ECharts','Bar','Stacked'],
    }), transformProps, controlPanel });
  }
}
TS
# barNegative/*
cat > "${SRC_DIR}/barNegative/transformProps.ts" <<'TS'
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
TS
cat > "${SRC_DIR}/barNegative/Chart.tsx" <<'TSX'
import React from 'react';
import EchartBase from '../shared/EchartBase';
export default function Chart({ height, width, echartOptions }: any) {
  return <EchartBase height={height} width={width} option={echartOptions} />;
}
TSX
cat > "${SRC_DIR}/barNegative/index.ts" <<'TS'
import { ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike';
import transformProps from './transformProps';
export default class EchartsBarNegativePlugin extends ChartPlugin {
  constructor() {
    super({ loadChart: () => import('./Chart'), metadata: new ChartMetadata({
      name: t('ECharts Bar (Positive/Negative)'), credits: ['Apache ECharts'], tags: ['ECharts','Bar'],
    }), transformProps, controlPanel });
  }
}
TS

# matrixMiniBarGeo/*
cat > "${SRC_DIR}/matrixMiniBarGeo/transformProps.ts" <<'TS'
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
TS
cat > "${SRC_DIR}/matrixMiniBarGeo/Chart.tsx" <<'TSX'
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
TSX
cat > "${SRC_DIR}/matrixMiniBarGeo/index.ts" <<'TS'
import { ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike';
import transformProps from './transformProps';
export default class EchartsMatrixMiniBarGeoPlugin extends ChartPlugin {
  constructor() {
    super({ loadChart: () => import('./Chart'), metadata: new ChartMetadata({
      name: t('ECharts Matrix Mini-bar + Geo (v6)'), credits: ['Apache ECharts'], tags: ['ECharts','Matrix','Experimental'],
    }), transformProps, controlPanel });
  }
}
TS

info "Fuentes del plugin generadas/actualizadas."

# -------------------------------------------------------------------
# 2) DEV DEPENDENCIES del PLUGIN (para compilar con tsc)
#    *No afectan runtime en Superset; solo compilación local del plugin*
# -------------------------------------------------------------------
info "Asegurando devDependencies del plugin para compilación con TypeScript…"
node <<'NODE'
const fs = require('fs');
const p = 'plugins/superset-plugin-chart-echarts-extras/package.json';
const pkg = JSON.parse(fs.readFileSync(p, 'utf8'));
pkg.devDependencies = pkg.devDependencies || {};
if (!pkg.devDependencies['@types/react']) pkg.devDependencies['@types/react'] = '^17.0.0';
if (!pkg.devDependencies['@types/react-dom']) pkg.devDependencies['@types/react-dom'] = '^17.0.0';
if (!pkg.devDependencies['echarts']) pkg.devDependencies['echarts'] = '^5.4.0';
if (!pkg.devDependencies['@superset-ui/core']) pkg.devDependencies['@superset-ui/core'] = '*';
if (!pkg.devDependencies['@superset-ui/chart-controls']) pkg.devDependencies['@superset-ui/chart-controls'] = '*';
if (!pkg.devDependencies['typescript']) pkg.devDependencies['typescript'] = '^5.4.0';
fs.writeFileSync(p, JSON.stringify(pkg, null, 2));
console.log('✅ devDependencies listos para el build TS del plugin');
NODE

# -------------------------------------------------------------------
# 3) INSTALAR y COMPILAR el PLUGIN
# -------------------------------------------------------------------
info "Instalando devDependencies del plugin y compilando (tsc)…"
cd "${PLUGIN_DIR}"
npm install --legacy-peer-deps --no-audit --no-fund
npm run build

# -------------------------------------------------------------------
# 4) INSTALAR el PLUGIN en superset-frontend (sin recalcular peers)
# -------------------------------------------------------------------
cd "${SUPERSET_ROOT}/superset-frontend"

# Reforzar .npmrc (por si algún entorno no corrió 03b)
if [[ ! -f ".npmrc" ]]; then
  cat > ".npmrc" <<'NPMRC'
legacy-peer-deps=true
audit=false
fund=false
NPMRC
  info "Creado .npmrc (legacy-peer-deps=true) en superset-frontend."
fi

info "Instalando el plugin en superset-frontend (sin guardar en package.json)…"
npm install --no-save ../plugins/superset-plugin-chart-echarts-extras \
  --legacy-peer-deps --no-audit --no-fund

# Fijar echarts mayor si no está definido y reinstalar respetando .npmrc
node <<NODE
const fs = require('fs'); const p='package.json';
const pkg = JSON.parse(fs.readFileSync(p,'utf8'));
pkg.dependencies = pkg.dependencies || {};
if(!pkg.dependencies.echarts) pkg.dependencies.echarts = '^${ECHARTS_TARGET_MAJOR}.0.0';
fs.writeFileSync(p, JSON.stringify(pkg,null,2));
console.log('ℹ️ echarts =', pkg.dependencies.echarts);
NODE

npm install --no-audit --no-fund

# -------------------------------------------------------------------
# 5) VERIFICACIONES (React 17 presente en node_modules)
# -------------------------------------------------------------------
info "Verificando React 17 en superset-frontend…"
node <<'NODE'
const assert = (c,m)=>{ if(!c){ console.error('✖',m); process.exit(1);} };
let rv='n/a', rdv='n/a';
try { rv = require('react/package.json').version; } catch {}
try { rdv = require('react-dom/package.json').version; } catch {}
assert(String(rv).startsWith('17.'), `react no está en 17.x (actual: ${rv})`);
assert(String(rdv).startsWith('17.'), `react-dom no está en 17.x (actual: ${rdv})`);
console.log('✅ React 17 OK:', rv, rdv);
NODE

success "Plugin ECharts: fuentes listas, build ok e instalación en superset-frontend completada."
