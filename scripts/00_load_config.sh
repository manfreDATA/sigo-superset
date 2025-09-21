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

# Source existing config values into the environment (export while reading)
# Use a subshell to avoid polluting caller if source fails; but we want variables exported.
set -a
# shellcheck disable=SC1090
. "$CONFIG_FILE" 2>/dev/null || true
set +a

# List of default variable definitions. Add new defaults here if scripts need them.
# Format: VAR=default_value
DEFAULTS=(
  # Paths and filenames
  "ROOT_DIR=${ROOT_DIR}"
  "CONFIG_DIR=${CONFIG_DIR}"
  "SUPERSET_DIR=${ROOT_DIR}/superset"
  "ENV_FILE=.env-local"
  "SUP_CONFIG=superset_config_docker.py"
  "COMPOSE_NONDEV=docker-compose-non-dev.yml"
  "COMPOSE_DEV=docker-compose-dev.yml"

  # Targets inside the superset tree
  "DEST_ENV_DIR=\${SUPERSET_DIR}/docker"
  "DEST_SUP_CONFIG_DIR=\${SUPERSET_DIR}/docker/pythonpath_dev"
  "DEST_COMPOSE_DIR=\${SUPERSET_DIR}"

  # Superset runtime defaults (useful for compose scripts)
  "SUPERSET_PORT=8088"
  "SUPERSET_IMAGE=sigo-superset:latest"

  # DB & Redis sensible defaults (used by compose; appended so env file is complete)
  "POSTGRES_USER=superset"
  "POSTGRES_PASSWORD=superset"
  "POSTGRES_DB=superset"
  "CELERY_BROKER_URL=redis://redis:6379/0"
  "CELERY_RESULT_BACKEND=redis://redis:6379/1"

  # Optional admin user creation via superset-init
  "SUPERSET_ADMIN_USERNAME=admin"
  "SUPERSET_ADMIN_FIRSTNAME=Admin"
  "SUPERSET_ADMIN_LASTNAME=User"
  "SUPERSET_ADMIN_EMAIL=admin@example.com"
  "SUPERSET_ADMIN_PASSWORD=admin_password_here"

  # Other common values
  "FLASK_ENV=production"
  "SUPERSET_ENV=production"
)

# Helper: check if variable is defined (non-empty) in current environment.
is_set() {
  local varname="$1"
  # Use parameter expansion to avoid set -u issues
  [ -n "
${!varname-}" ]
}

# Append missing defaults to config file and export them into current shell
for entry in "${DEFAULTS[@]}"; do
  # Split on first '='
  varname="${entry%%=*}"
  # Evaluate the right side in a safe manner to allow ROOT_DIR expansions
  default_raw="${entry#*=}"
  # Expand embedded parameter references if any (e.g. \${SUPERSET_DIR})
  # We use 'eval' to expand only the right-hand side safely in context of this script.
  # Ensure no trailing newlines
  eval "default_value=\"$default_raw\""

  if ! is_set "$varname"; then
    # Append to CONFIG_FILE if not already present
    # Use "grep -q" to detect presence of a definition line starting with varname (ignoring comments)
    if ! grep -Eq "^[[:space:]]*${varname}=" "$CONFIG_FILE"; then
      echo "${varname}=${default_value}" >> "$CONFIG_FILE"
      echo "00_load_config: Appended default ${varname}=${default_value} to ${CONFIG_FILE}"
    fi
    # Export into environment for the caller
    export "$varname"="$default_value"
  else
    # Ensure the currently-set value is exported too
    export "$varname"="
${!varname}"
  fi
done

# Export once more commonly used derived paths (in case config file contained relative values)
# Re-evaluate DEST_* in case they used SUPERSET_DIR from the defaults appended above
export DEST_ENV_DIR="
${DEST_ENV_DIR:-\${SUPERSET_DIR}/docker}"
export DEST_SUP_CONFIG_DIR="
${DEST_SUP_CONFIG_DIR:-\${SUPERSET_DIR}/docker/pythonpath_dev}"
export DEST_COMPOSE_DIR="
${DEST_COMPOSE_DIR:-\${SUPERSET_DIR}}"

# Provide a small status line for user-visible scripts
: > /dev/null
