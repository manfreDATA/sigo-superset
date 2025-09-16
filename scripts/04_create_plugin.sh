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
# Helpers para imágenes oficiales y placeholders
# -------------------------------------------------------------------
png_placeholder_b64='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFxgJd0nS0NQAAAABJRU5ErkJggg=='
write_placeholder_png() { # $1 = ruta destino
  printf '%s' "$png_placeholder_b64" | base64 -d > "$1" || true
}

copy_first() { # $1 srcDir $2 baseName (sin extensión) $3 dstPath (con nombre final)
  local s="$1/$2.png"; [[ -f "$s" ]] && { cp -f "$s" "$3"; return 0; }
  s="$1/$2.jpg";        [[ -f "$s" ]] && { cp -f "$s" "$3"; return 0; }
  return 1
}

ensure_img_set() { # $1 srcDir  $2 dstDir
  mkdir -p "$2"
  # thumbnail
  if ! copy_first "$1" "thumbnail" "$2/thumbnail.png"; then
    write_placeholder_png "$2/thumbnail.png"
  fi
  # example1
  if ! copy_first "$1" "example1" "$2/example1.png"; then
    # Si no hay example1 oficial, duplica thumbnail
    cp -f "$2/thumbnail.png" "$2/example1.png" 2>/dev/null || write_placeholder_png "$2/example1.png"
  fi
  # example2 (opcional)
  if ! copy_first "$1" "example2" "$2/example2.png"; then
    # Si no hay example2, ignora (no es obligatorio tenerlo)
    :
  fi
}

# Mapeo a imágenes oficiales del repo de Superset (si existen)
SRC_ECHARTS_BASE="${SUPERSET_ROOT}/superset-frontend/plugins/plugin-chart-echarts/src"
SRC_PIE="${SRC_ECHARTS_BASE}/Pie/images"
SRC_HIST="${SRC_ECHARTS_BASE}/Histogram/images"
SRC_WATERFALL="${SRC_ECHARTS_BASE}/Waterfall/images"
SRC_TREEMAP="${SRC_ECHARTS_BASE}/Treemap/images"

# -------------------------------------------------------------------
# 1) CREAR/ACTUALIZAR SKELETON DEL PLUGIN (idempotente)
# -------------------------------------------------------------------
info "Creando/actualizando skeleton del plugin (idempotente)…"

PLUGIN_DIR="plugins/superset-plugin-chart-echarts-extras"
SRC_DIR="${PLUGIN_DIR}/src"
mkdir -p "${SRC_DIR}"/{shared,datasetLink,datasetSeriesLayoutBy,barYStack,barNegative,matrixMiniBarGeo}

# package.json del plugin (peers compatibles con React 17)
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
# -------------------------------------------------------------------
# 1.1) Thumbnails SVG (data-URI) compartidos + import de PNG oficiales
# -------------------------------------------------------------------
mkdir -p "${SRC_DIR}/shared"
cat > "${SRC_DIR}/shared/thumbnails.ts" <<'TS'
// Thumbnails en data-URI SVG (fallbacks)
const svg = (body: string, w = 160, h = 100) =>
  `data:image/svg+xml;utf8,` +
  encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`);

export const thumbDatasetLink = svg(`
  <rect width="160" height="100" fill="#F7F7F7"/>
  <rect x="18" y="50" width="18" height="40" fill="#1f77b4"/>
  <rect x="48" y="35" width="18" height="55" fill="#ff7f0e"/>
  <rect x="78" y="25" width="18" height="65" fill="#2ca02c"/>
  <rect x="108" y="60" width="18" height="30" fill="#d62728"/>
  <rect x="138" y="20" width="18" height="70" fill="#9467bd"/>
`);

export const thumbDatasetSeriesLayout = svg(`
  <rect width="160" height="100" fill="#FDFDFD"/>
  <rect x="15" y="45" width="16" height="25" fill="#1f77b4"/>
  <rect x="37" y="35" width="16" height="35" fill="#ff7f0e"/>
  <rect x="59" y="28" width="16" height="42" fill="#2ca02c"/>
  <line x1="10" y1="55" x2="150" y2="55" stroke="#DDD" stroke-width="2"/>
  <rect x="15" y="70" width="16" height="20" fill="#1f77b4" opacity="0.8"/>
  <rect x="37" y="70" width="16" height="20" fill="#ff7f0e" opacity="0.8"/>
  <rect x="59" y="70" width="16" height="20" fill="#2ca02c" opacity="0.8"/>
`);

export const thumbBarStackY = svg(`
  <rect width="160" height="100" fill="#F7F7F7"/>
  <rect x="30" y="65" width="18" height="10" fill="#1f77b4"/>
  <rect x="30" y="55" width="18" height="10" fill="#ff7f0e"/>
  <rect x="30" y="43" width="18" height="12" fill="#2ca02c"/>
  <rect x="70" y="70" width="18" height="5"  fill="#1f77b4"/>
  <rect x="70" y="50" width="18" height="20" fill="#ff7f0e"/>
  <rect x="110" y="40" width="18" height="35" fill="#1f77b4"/>
  <rect x="110" y="25" width="18" height="15" fill="#ff7f0e"/>
`);

export const thumbBarPositiveNegative = svg(`
  <rect width="160" height="100" fill="#FFFFFF"/>
  <line x1="80" y1="15" x2="80" y2="90" stroke="#BBB" stroke-width="2"/>
  <rect x="80" y="25" width="35" height="12" fill="#2ca02c"/>
  <rect x="80" y="45" width="20" height="12" fill="#2ca02c"/>
  <rect x="45" y="65" width="35" height="12" fill="#d62728"/>
  <rect x="60" y="80" width="20" height="6"  fill="#d62728"/>
`);

export const thumbMatrixMiniBarGeo = svg(`
  <rect width="160" height="100" fill="#FCFCFC"/>
  <rect x="15" y="20" width="60" height="45" fill="#e0f3ff" stroke="#b7ddff"/>
  <circle cx="40" cy="45" r="10" fill="#a6cee3"/>
  <rect x="95" y="25" width="12" height="35" fill="#1f77b4"/>
  <rect x="112" y="32" width="12" height="28" fill="#ff7f0e"/>
  <rect x="129" y="20" width="12" height="40" fill="#2ca02c"/>
`, 160, 100);
TS

# -------------------------------------------------------------------
# 1.2) Copiar imágenes oficiales a cada subplugin (si existen)
#      y crear placeholders si no.
# -------------------------------------------------------------------
ensure_img_set "${SRC_PIE}"       "${SRC_DIR}/datasetLink/images"
ensure_img_set "${SRC_HIST}"      "${SRC_DIR}/datasetSeriesLayoutBy/images"
ensure_img_set "${SRC_HIST}"      "${SRC_DIR}/barYStack/images"
ensure_img_set "${SRC_WATERFALL}" "${SRC_DIR}/barNegative/images"
ensure_img_set "${SRC_TREEMAP}"   "${SRC_DIR}/matrixMiniBarGeo/images"

# -------------------------------------------------------------------
# 1.3) Archivos fuente por subplugin (Chart.tsx / transformProps.ts / index.ts con metadata completa)
#      NOTA: en index.ts importamos PNGs oficiales + añadimos data-URI fallback (usado en exampleGallery si procede)
# -------------------------------------------------------------------

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

# ===== datasetLink =====
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
import { Behavior, ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike';
import transformProps from './transformProps';
import { thumbDatasetLink as fallbackThumb } from '../shared/thumbnails';
import thumbnail from './images/thumbnail.png';
import example1 from './images/example1.png';

export default class EchartsDatasetLinkPlugin extends ChartPlugin {
  constructor() {
    super({
      loadChart: () => import('./Chart'),
      metadata: new ChartMetadata({
        name: t('ECharts Dataset Link'),
        thumbnail,
        credits: ['https://echarts.apache.org'],
        category: t('Data Transformation'),
        description: t('Uses ECharts dataset linkage to map a tabular dataset directly to series, reducing manual mapping and enabling quick comparisons.'),
        tags: ['ECharts', t('Dataset'), t('Comparison'), t('Featured')],
        exampleGallery: [{ url: example1 || fallbackThumb }],
        behaviors: [Behavior.INTERACTIVE_CHART],
      }),
      transformProps,
      controlPanel,
    });
  }
}
TS

# ===== datasetSeriesLayoutBy =====
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
import { Behavior, ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike';
import transformProps from './transformProps';
import { thumbDatasetSeriesLayout as fallbackThumb } from '../shared/thumbnails';
import thumbnail from './images/thumbnail.png';
import example1 from './images/example1.png';
import example2 from './images/example2.png';

export default class EchartsDatasetSeriesLayoutByPlugin extends ChartPlugin {
  constructor() {
    super({
      loadChart: () => import('./Chart'),
      metadata: new ChartMetadata({
        name: t('ECharts Dataset SeriesLayoutBy'),
        thumbnail,
        credits: ['https://echarts.apache.org'],
        category: t('Data Transformation'),
        description: t('Explores ECharts seriesLayoutBy to flip dataset orientation across multiple panes, useful to compare series-by-row vs series-by-column.'),
        tags: ['ECharts', t('Dataset'), t('Layout'), t('Multi‑panel')],
        exampleGallery: [{ url: example1 || fallbackThumb }, { url: example2 || fallbackThumb }],
        behaviors: [Behavior.INTERACTIVE_CHART],
      }),
      transformProps,
      controlPanel,
    });
  }
}
TS

# ===== barYStack =====
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
import { Behavior, ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike';
import transformProps from './transformProps';
import { thumbBarStackY as fallbackThumb } from '../shared/thumbnails';
import thumbnail from './images/thumbnail.png';
import example1 from './images/example1.png';

export default class EchartsBarYStackPlugin extends ChartPlugin {
  constructor() {
    super({
      loadChart: () => import('./Chart'),
      metadata: new ChartMetadata({
        name: t('ECharts Stacked Bar (Y Category)'),
        thumbnail,
        credits: ['https://echarts.apache.org'],
        category: t('Comparison'),
        description: t('Stacked bars with categories on the Y axis, highlighting composition across groups. Ideal to compare parts-to-whole across categories.'),
        tags: ['ECharts', t('Bar'), t('Stacked'), t('Composition')],
        exampleGallery: [{ url: example1 || fallbackThumb }],
        behaviors: [Behavior.INTERACTIVE_CHART],
      }),
      transformProps,
      controlPanel,
    });
  }
}
TS
# ===== barNegative =====
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
import { Behavior, ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike';
import transformProps from './transformProps';
import { thumbBarPositiveNegative as fallbackThumb } from '../shared/thumbnails';
import thumbnail from './images/thumbnail.png';
import example1 from './images/example1.png';

export default class EchartsBarNegativePlugin extends ChartPlugin {
  constructor() {
    super({
      loadChart: () => import('./Chart'),
      metadata: new ChartMetadata({
        name: t('ECharts Bar (Positive/Negative)'),
        thumbnail,
        credits: ['https://echarts.apache.org'],
        category: t('Comparison'),
        description: t('Bidirectional bar chart to compare gains and losses around a zero baseline. Great for profit/loss breakdowns and net effects.'),
        tags: ['ECharts', t('Bar'), t('Diverging'), t('Business')],
        exampleGallery: [{ url: example1 || fallbackThumb }],
        behaviors: [Behavior.INTERACTIVE_CHART],
      }),
      transformProps,
      controlPanel,
    });
  }
}
TS

# ===== matrixMiniBarGeo =====
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
import { Behavior, ChartMetadata, ChartPlugin, t } from '@superset-ui/core';
import controlPanel from '../shared/controlPanelBarLike';
import transformProps from './transformProps';
import { thumbMatrixMiniBarGeo as fallbackThumb } from '../shared/thumbnails';
import thumbnail from './images/thumbnail.png';
import example1 from './images/example1.png';

export default class EchartsMatrixMiniBarGeoPlugin extends ChartPlugin {
  constructor() {
    super({
      loadChart: () => import('./Chart'),
      metadata: new ChartMetadata({
        name: t('ECharts Matrix Mini‑bar + Geo (v6)'),
        thumbnail,
        credits: ['https://echarts.apache.org'],
        category: t('Geospatial'),
        description: t('Experimental matrix layout combining mini‑bars with a geographic frame (ECharts v6 feature). Useful for dense, small‑multiple overviews.'),
        tags: ['ECharts', t('Matrix'), t('Geo'), t('Experimental')],
        exampleGallery: [{ url: example1 || fallbackThumb }],
        behaviors: [Behavior.INTERACTIVE_CHART],
      }),
      transformProps,
      controlPanel,
    });
  }
}
TS

info "Fuentes + metadata + imágenes listos."

# -------------------------------------------------------------------
# 2) DEV DEPENDENCIES del PLUGIN (para compilar con TypeScript)
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

success "Plugin ECharts: fuentes + imágenes oficiales + metadata listos; build e instalación completados."
