#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

info "Instalando Node.js 20 + npm (NodeSource)…"
apt-get install -y ca-certificates curl gnupg
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
 | tee /etc/apt/sources.list.d/nodesource.list >/dev/null
apt-get update -y
apt-get install -y nodejs

node -v
npm -v
success "Node/npm instalados (alineados con Dockerfile oficial de Superset)."
