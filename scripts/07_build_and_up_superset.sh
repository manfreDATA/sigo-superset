#!/usr/bin/env bash
set -euo pipefail

# Script 07
# Builds and starts Superset using a chosen compose file.
# Reads configuration from scripts/00_load_config.sh and uses COMPOSE_NONDEV / COMPOSE_DEV.
#
# Usage:
#   scripts/07_build_and_up_superset.sh        # defaults to non-dev compose
#   scripts/07_build_and_up_superset.sh dev    # uses dev compose
#   MODE=dev scripts/07_build_and_up_superset.sh

# Source loader (this will populate environment variables and append defaults to config file)
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/00_load_config.sh"

MODE="${1:-${MODE:-non-dev}}"

if [ "${MODE}" = "dev" ] || [ "${MODE}" = "development" ]; then
  COMPOSE_BASENAME="${COMPOSE_DEV}"
else
  COMPOSE_BASENAME="${COMPOSE_NONDEV}"
  fi

COMPOSE_PATH="${SUPERSET_DIR}/${COMPOSE_BASENAME}"

echo "Starting script 07: build & bring up superset via docker compose (mode=${MODE})"
echo "Using compose file: ${COMPOSE_PATH}"

# Basic checks
if [ ! -d "${SUPERSET_DIR}" ]; then
  echo "ERROR: superset directory not found at ${SUPERSET_DIR}" >&2
  exit 2
fi

if [ ! -f "${COMPOSE_PATH}" ]; then
  echo "ERROR: Compose file ${COMPOSE_PATH} not found. Please run script 06 first to copy it or create it in ${CONFIG_DIR}." >&2
  exit 3
fi

# Ensure docker is available
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker CLI not found in PATH." >&2
  exit 4
fi

# Prefer 'docker compose' (plugin). If not available, fall back to 'docker-compose' if present.
DOCKER_COMPOSE_CMD=""
if docker compose version >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker-compose"
else
  echo "ERROR: neither 'docker compose' nor 'docker-compose' is available." >&2
  exit 5
fi

echo "Using compose command: ${DOCKER_COMPOSE_CMD}"
echo "Changing directory to ${SUPERSET_DIR}"
cd "${SUPERSET_DIR}"

# Run compose with build to ensure images are rebuilt
echo "Running: ${DOCKER_COMPOSE_CMD} -f ${COMPOSE_BASENAME} up --build"
if ${DOCKER_COMPOSE_CMD} -f "${COMPOSE_BASENAME}" up --build; then
  echo "Docker compose started successfully."
else
  echo "ERROR: docker compose failed. Check the logs with: ${DOCKER_COMPOSE_CMD} -f ${COMPOSE_BASENAME} logs --tail=200" >&2
  exit 6
fi

echo "Script 07 completed: superset should be up (mode=${MODE})."