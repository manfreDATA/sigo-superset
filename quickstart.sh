#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo chmod +x run_all.sh scripts/*.sh || true
sudo ./run_all.sh
