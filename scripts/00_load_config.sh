#!/usr/bin/env bash
# Loads configuration from config/.env-local into the environment and ensures
# a set of sensible defaults are present in that config file.
#
# Intended to be sourced by other scripts:
#   . "$(dirname "${BASH_SOURCE[0]}")/00_load_config.sh"
#
# Behavior:
# - Determine repository root.
# - Ensure config directory exists.
# - Source config/.env-local if present (without failing the caller).
# - For each default variable below, if it's not defined in the environment
#   (or was not present in the config file), append a default definition to
#   config/.env-local and export it into the current environment.
#
# NOTE: This script appends defaults only when variables are missing. It will
# not overwrite existing values in config/.env-local.

set -u

# Compute repo root reliably whether sourced from scripts/ or executed from elsewhere
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
else
  THIS_DIR="$(pwd)"
fi
ROOT_DIR="$(cd "$THIS_DIR/.." >/dev/null 2>&1 && pwd)"

# Config file location (the user's "config" directory at repo root)
CONFIG_DIR="${ROOT_DIR}/config"
CONFIG_FILE="${CONFIG_DIR}/.env-local"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Ensure config file exists so we can safely append defaults later
if [ ! -f "$CONFIG_FILE" ]; then
  # create an empty file with a comment header to indicate it is managed
  cat > "$CONFIG_FILE" <<EOF
# config/.env-local
# This file is read by the repository scripts. Sensitive values should be kept out of VCS.
# Defaults will be appended here by scripts if variables are missing.
EOF
fi

ROOT_DIR=${ROOT_DIR}
CONFIG_DIR=${CONFIG_DIR}
SUPERSET_DIR="/root/superset"
ENV_FILE=".env-local"
SUP_CONFIG="superset_config_docker.py"
COMPOSE_NONDEV="docker-compose-non-dev.yml"
COMPOSE_DEV="docker-compose.yml"

  # Targets inside the superset tree
DEST_ENV_DIR="${SUPERSET_DIR}/docker"
DEST_SUP_CONFIG_DIR="${SUPERSET_DIR}/docker/pythonpath_dev"
DEST_COMPOSE_DIR="${SUPERSET_DIR}"

# Source existing config values into the environment (export while reading)
# Use a subshell to avoid polluting caller if source fails; but we want variables exported.
set -a
# shellcheck disable=SC1090
. "$CONFIG_FILE" 2>/dev/null || true
set +a

# Provide a small status line for user-visible scripts
: > /dev/null
