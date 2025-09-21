#!/bin/bash

# Script para construir e iniciar Superset usando docker compose y configuración desde config/

echo "➤ Construyendo imágenes de Superset..."
docker compose --env-file config/.env -f config/docker-compose-non-dev.override.yml build

echo "➤ Levantando servicios de Superset..."
docker compose --env-file config/.env -f config/docker-compose-non-dev.override.yml up -d

echo "⏳ Esperando que el contenedor 'superset' esté activo..."
sleep 10

echo "⚙️ Ejecutando inicialización de Superset..."
docker compose --env-file config/.env -f config/docker-compose-non-dev.override.yml exec superset superset db upgrade
docker compose --env-file config/.env -f config/docker-compose-non-dev.override.yml exec superset superset init

echo "🎉 Superset está listo y configurado con archivos desde config/"
