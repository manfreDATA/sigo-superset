#!/usr/bin/env bash
set -euo pipefail

# Script 06
# Copies specific files from config/ into the corresponding locations in the superset code tree.
# - config/.env-local -> superset/docker/.env-local
# - config/superset_config_docker.py -> superset/docker/pythonpath_dev/superset_config_docker.py
# - config/docker-compose-non-dev.yml -> superset/docker-compose-non-dev.yml

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)" || exit 1
CONFIG_DIR="$ROOT_DIR/config"
SUPERSET_DIR="$ROOT_DIR/superset"

# Source filenames
ENV_FILE=".env-local"
SUP_CONFIG="superset_config_docker.py"
COMPOSE_FILE="docker-compose-non-dev.yml"

# Destinations
DEST_ENV_DIR="$SUPERSET_DIR/docker"
DEST_SUP_CONFIG_DIR="$SUPERSET_DIR/docker/pythonpath_dev"
DEST_COMPOSE_DIR="$SUPERSET_DIR"

echo "Starting script 06: copy specific config files into superset tree."

# Basic checks
if [ ! -d "$CONFIG_DIR" ]; then
  echo "ERROR: config directory not found at $CONFIG_DIR" >&2
  exit 2
fi

# Ensure superset dir exists
if [ ! -d "$SUPERSET_DIR" ]; then
  echo "ERROR: superset directory not found at $SUPERSET_DIR" >&2
  exit 3
fi

# Copy .env-local
if [ -f "$CONFIG_DIR/$ENV_FILE" ]; then
  mkdir -p "$DEST_ENV_DIR"
  cp -f "$CONFIG_DIR/$ENV_FILE" "$DEST_ENV_DIR/$ENV_FILE"
  echo "Copied $CONFIG_DIR/$ENV_FILE -> $DEST_ENV_DIR/$ENV_FILE"
else
  echo "WARNING: $CONFIG_DIR/$ENV_FILE not found, skipping copy of env file."
fi

# Copy superset_config_docker.py
if [ -f "$CONFIG_DIR/$SUP_CONFIG" ]; then
  mkdir -p "$DEST_SUP_CONFIG_DIR"
  cp -f "$CONFIG_DIR/$SUP_CONFIG" "$DEST_SUP_CONFIG_DIR/$SUP_CONFIG"
  echo "Copied $CONFIG_DIR/$SUP_CONFIG -> $DEST_SUP_CONFIG_DIR/$SUP_CONFIG"
else
  echo "WARNING: $CONFIG_DIR/$SUP_CONFIG not found, skipping copy of superset_config_docker.py."
fi

# Copy docker-compose-non-dev.yml into superset root
if [ -f "$CONFIG_DIR/$COMPOSE_FILE" ]; then
  cp -f "$CONFIG_DIR/$COMPOSE_FILE" "$DEST_COMPOSE_DIR/$COMPOSE_FILE"
  echo "Copied $CONFIG_DIR/$COMPOSE_FILE -> $DEST_COMPOSE_DIR/$COMPOSE_FILE"
else
  echo "WARNING: $CONFIG_DIR/$COMPOSE_FILE not found, skipping copy of docker-compose file."
fi

echo "Script 06 completed."