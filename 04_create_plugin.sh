#!/bin/bash
set -e

PLUGIN_ROOT=/app/plugins

create_plugin() {
  PLUGIN_NAME=$1
  PLUGIN_PATH="$PLUGIN_ROOT/$PLUGIN_NAME"
  mkdir -p "$PLUGIN_PATH"
  echo "// Plugin $PLUGIN_NAME entry point" > "$PLUGIN_PATH/index.js"
  echo "{\"name\": \"$PLUGIN_NAME\", \"version\": \"0.0.1\"}" > "$PLUGIN_PATH/package.json"
}

create_plugin "datasetLink"
create_plugin "datasetSeriesLayoutBy"
create_plugin "barYStack"
create_plugin "barNegative"
create_plugin "matrixMiniBarGeo"

echo "✅ Plugins ECharts creados correctamente en $PLUGIN_ROOT"
