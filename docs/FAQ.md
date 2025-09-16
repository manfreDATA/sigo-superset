# FAQ
- **¿Dónde se instala Superset?** En `/root/superset` (ver `config/flags.env`).
- **Node/React usados:** **Node 20** y **React 17** (forzado con `overrides`).
- **Drivers Postgres:** `psycopg2-binary` se agrega vía `docker/requirements-local.txt`.
- **Cambiar a dev:** `config/flags.env` → `MODE=dev` y re‑ejecuta `run_all.sh`.
- **Error `No module named psycopg2`:** reconstruye con `--build` para hornear drivers.
