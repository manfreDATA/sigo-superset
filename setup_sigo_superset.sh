#!/bin/bash

# Script de instalación y despliegue de SIGO Superset desde /root
# Compatible con Ubuntu 22.04 LTS

set -e

echo "🔧 Actualizando sistema..."
apt update && apt upgrade -y

echo "🐳 Instalando Docker y Docker Compose..."
apt install docker.io docker-compose git unzip curl -y
systemctl enable docker
systemctl start docker

echo "📁 Clonando repositorio principal SIGO Superset..."
cd /root
git clone https://github.com/manfreDATA/sigo-superset.git
cd sigo-superset

echo "🚀 Levantando entorno con Docker Compose..."
docker compose -f docker-compose-non-dev.yml --env-file .env-local up -d

echo "✅ Entorno SIGO Superset desplegado correctamente."
echo "📊 Puedes importar tus archivos CSV desde la interfaz de Superset."
