# SIGO ECharts – Superset v6 + ECharts extras (Ubuntu 22.04)

Este paquete despliega **Apache Superset 6.0.0rc1** en `/root/superset` usando Docker Compose non‑dev, y agrega un plugin con **5 visualizaciones ECharts**. Debe ubicarse en `/root/sigo-echarts`.

## Uso rápido
```bash
cd /root/sigo-echarts
sudo chmod +x run_all.sh scripts/*.sh
sudo ./run_all.sh
```
Luego visita: `http://localhost:8088` (credenciales en `config/.env`).

## Lo que hace
- Instala Docker Engine + Compose plugin.
- Clona Superset 6.0.0rc1 en `/root/superset`.
- Instala **Node 20** y fija **React 17** (npm `overrides`).
- Crea plugin **ECharts** con 5 charts; intenta **ECharts v6** (fallback a v5).
- Copia `.env`, `superset_config_docker.py`, override compose y **drivers Postgres** (`psycopg2-binary`).
- Construye imagen **non‑dev** inmutable y deja Superset operativo.

## Flags y configuración
- `config/flags.env`: `MODE=prod|dev`, puertos, rutas, ECharts mayor.
- `config/.env`: admin y `SUPERSET_SECRET_KEY` (si `__GENERATE_ME__`, se genera).
- `config/superset_config_docker.py`: ajustes de producción (proxy, límites).
