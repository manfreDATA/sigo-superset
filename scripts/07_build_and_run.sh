#!/usr/bin/env bash
set -euo pipefail

# Script 07
# Moves into the superset folder and runs docker compose with the copied docker-compose-non-dev.yml
# Performs an up -d with a build so images are fresh.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)" || exit 1
SUPERSET_DIR="$ROOT_DIR/superset"
COMPOSE_FILE="docker-compose-non-dev.yml"

echo "Starting script 07: build & bring up superset via docker compose."

# Basic checks
if [ ! -d "$SUPERSET_DIR" ]; then
  echo "ERROR: superset directory not found at $SUPERSET_DIR" >&2
  exit 2
fi

if [ ! -f "$SUPERSET_DIR/$COMPOSE_FILE" ]; then
  echo "ERROR: Compose file $SUPERSET_DIR/$COMPOSE_FILE not found. Please run script 06 first to copy it." >&2
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

echo "Using compose command: $DOCKER_COMPOSE_CMD"
echo "Changing directory to $SUPERSET_DIR"
cd "$SUPERSET_DIR"

# Run compose with build to ensure images are rebuilt
echo "Running: $DOCKER_COMPOSE_CMD -f $COMPOSE_FILE up -d --build"
# Use exec so exit code bubbles up; capture exit for reporting
if $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" up -d --build; then
  echo "Docker compose started successfully."
else
  echo "ERROR: docker compose failed. Check the logs with: $DOCKER_COMPOSE_CMD -f $COMPOSE_FILE logs --tail=200" >&2
  exit 6
fi

echo "Script 07 completed: superset should be up."