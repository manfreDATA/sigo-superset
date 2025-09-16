#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

red()    { printf "\e[31m%s\e[0m\n" "$*"; }
green()  { printf "\e[32m%s\e[0m\n" "$*"; }
yellow() { printf "\e[33m%s\e[0m\n" "$*"; }
blue()   { printf "\e[34m%s\e[0m\n" "$*"; }

info()    { blue   "➤ $*"; }
warn()    { yellow "⚠  $*"; }
error()   { red    "✖  $*"; }
success() { green  "✔  $*"; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    error "Debes ejecutar como root (sudo)."
    exit 1
  fi
}

run_step() {
  local script="${BASE_DIR}/scripts/$1"
  info "Ejecutando $1"
  bash "${script}"
  success "Ok $1"
}
