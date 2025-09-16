#!/usr/bin/env bash
# install_quick.sh — Instalación rápida end-to-end para Ubuntu 22.04
# No modifica la estructura existente; simplemente orquesta run_all.sh con chequeos básicos.
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "[✖] Debes ejecutar como root (sudo)." >&2
  exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${BASE_DIR}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y || true
apt-get install -y ca-certificates curl gnupg lsb-release git || true

chmod +x run_all.sh scripts/*.sh || true
./run_all.sh
