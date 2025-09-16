#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

: "${SUPERSET_ROOT:?Debes definir SUPERSET_ROOT en flags.env}"
: "${GIT_URL:?}"
: "${GIT_TAG:?}"

apt-get update -y
apt-get install -y git

if [[ -d "${SUPERSET_ROOT}/.git" ]]; then
  info "Repositorio ya existe en ${SUPERSET_ROOT}. Actualizando tags…"
  git -C "${SUPERSET_ROOT}" fetch --tags --prune
else
  info "Clonando ${GIT_URL} en ${SUPERSET_ROOT}…"
  git clone "${GIT_URL}" "${SUPERSET_ROOT}"
fi

info "Checkout tag ${GIT_TAG}…"
( cd "${SUPERSET_ROOT}" && git checkout "tags/${GIT_TAG}" )

success "Superset clonado en ${SUPERSET_ROOT} (tag ${GIT_TAG})."
