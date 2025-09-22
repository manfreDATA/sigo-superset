#!/usr/bin/env bash
set -euo pipefail

# Script 06
# Copies specific files from config/ into the corresponding locations in the superset code tree.
# Uses configuration variables sourced/ensured by scripts/00_load_config.sh.

# Source loader (this will populate environment variables and append defaults to config file)
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/00_load_config.sh"

echo "Starting script 06: copy specific config files into superset tree."

# Basic checks using variables provided by 00_load_config.sh
if [ ! -d "${CONFIG_DIR}" ]; then
  echo "ERROR: config directory not found at ${CONFIG_DIR}" >&2
  exit 2
fi

if [ ! -d "${SUPERSET_DIR}" ]; then
  echo "ERROR: superset directory not found at ${SUPERSET_DIR}" >&2
  exit 3
fi



# Ensure destination directories exist
mkdir -p "${DEST_ENV_DIR}"
mkdir -p "${DEST_SUP_CONFIG_DIR}"
mkdir -p "${DEST_COMPOSE_DIR}"

# Copy superset_config_docker.py
if [ -f "${CONFIG_DIR}/${SUP_CONFIG}" ]; then
  cp -f "${CONFIG_DIR}/${SUP_CONFIG}" "${DEST_SUP_CONFIG_DIR}/${SUP_CONFIG}"
  echo "Copied ${CONFIG_DIR}/${SUP_CONFIG} -> ${DEST_SUP_CONFIG_DIR}/${SUP_CONFIG}"
else
  echo "WARNING: ${CONFIG_DIR}/${SUP_CONFIG} not found, skipping copy of ${SUP_CONFIG}."
fi

# Copy docker-compose-non-dev.yml into superset root
if [ -f "${CONFIG_DIR}/${COMPOSE_NONDEV}" ]; then
  cp -f "${CONFIG_DIR}/${COMPOSE_NONDEV}" "${DEST_COMPOSE_DIR}/${COMPOSE_NONDEV}"
  echo "Copied ${CONFIG_DIR}/${COMPOSE_NONDEV} -> ${DEST_COMPOSE_DIR}/${COMPOSE_NONDEV}"
else
  echo "WARNING: ${CONFIG_DIR}/${COMPOSE_NONDEV} not found, skipping copy of ${COMPOSE_NONDEV}."
fi

# Copy docker-compose-dev.yml into superset root
if [ -f "${CONFIG_DIR}/${COMPOSE_DEV}" ]; then
  cp -f "${CONFIG_DIR}/${COMPOSE_DEV}" "${DEST_COMPOSE_DIR}/${COMPOSE_DEV}"
  echo "Copied ${CONFIG_DIR}/${COMPOSE_DEV} -> ${DEST_COMPOSE_DIR}/${COMPOSE_DEV}"
else
  echo "WARNING: ${CONFIG_DIR}/${COMPOSE_DEV} not found, skipping copy of ${COMPOSE_DEV}."
fi

echo "Script 06 completed."