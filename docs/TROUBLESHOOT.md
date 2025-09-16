# Troubleshooting
- UI en :9000: Modo dev; para non‑dev usa `MODE=prod`.
- SECRET_KEY: si `config/.env` tiene `__GENERATE_ME__`, se genera automáticamente.
- Drivers faltantes: revisa `docker/requirements-local.txt` y reconstruye con `--build`.
- Permisos Docker: re‑logueo tras `01_docker.sh` para aplicar pertenencia al grupo docker.
- Version de React 17: cd /root/superset/superset-frontend
node -e "console.log(require('react/package.json').version, require('react-dom/package.json').version)"
# Debe imprimir 17.x 17.x

