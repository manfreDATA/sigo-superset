#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

info "Instalando Docker Engine + Docker Compose plugin (repo oficial Docker)…"
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
. /etc/os-release
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker || true
usermod -aG docker "${SUDO_USER:-root}" || true

success "Docker y Compose instalados."
# Docs: https://docs.docker.com/engine/install/ubuntu/  |  https://docs.docker.com/compose/install/linux/
