#!/bin/bash
set -e
cd /app/plugins
mkdir -p echarts
cd echarts

for plugin in datasetLink datasetSeriesLayoutBy barYStack barNegative matrixMiniBarGeo; do
  mkdir -p $plugin
  echo "// Plugin $plugin" > $plugin/index.js
done

echo "Plugins ECharts creados correctamente."
