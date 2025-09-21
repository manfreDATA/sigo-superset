# Superset Local non-dev Compose (production-ready)

This README explains how to run Apache Superset in a production-like setup using a local Docker build (Dockerfile in superset/docker/), how the configuration files are organized, and the minimal steps to get the stack running.

What I delivered
- docker-compose-non-dev.yml (place in the superset/ root) — builds the Superset image from superset/docker/Dockerfile and defines services: db, redis, superset, superset-init (one-shot migrations + optional admin creation), worker, and flower.
- docker/.env-local.example — a template you should copy to superset/docker/.env-local and populate with secrets and environment-specific values.
- Updated documentation (this README) describing required files and commands.

File placement and copy operations
- Copy config/.env-local -> superset/docker/.env-local
- Copy config/superset_config_docker.py -> superset/docker/pythonpath_dev/superset_config_docker.py
- Put docker-compose-non-dev.yml in the superset/ folder (root of the superset tree) so you can run: docker compose -f docker-compose-non-dev.yml up -d --build

If you already have the helper scripts (scripts/06 and scripts/07) they should:
- scripts/06: copy the required files from config/ into superset/docker and create the pythonpath_dev folder
- scripts/07: change into superset/ and run docker compose -f docker-compose-non-dev.yml up -d --build

Prerequisites
- Docker Engine (20.x+ recommended)
- Docker Compose plugin (docker compose) or docker-compose CLI
- Your repo root contains:
  - config/ (with your production .env-local and superset_config_docker.py)
  - superset/ (the compose file goes here)
  - superset/docker/ (contains Dockerfile and pythonpath_dev directory after copying)

Quick start (manual)
1. Copy the configuration files (manual):
   - cp config/.env-local superset/docker/.env-local
   - mkdir -p superset/docker/pythonpath_dev
   - cp config/superset_config_docker.py superset/docker/pythonpath_dev/superset_config_docker.py

2. Place docker-compose-non-dev.yml in the superset/ directory.

3. From the superset/ directory build & run:
   - docker compose -f docker-compose-non-dev.yml up -d --build

4. The first-run initialization is done by the superset-init one-shot container which:
   - waits for Postgres to be ready
   - runs `superset db upgrade`
   - runs `superset init`
   - optionally creates an admin user if SUPERSET_ADMIN_* variables are set in superset/docker/.env-local

Accessing Superset
- Default UI: http://localhost:${SUPERSET_PORT:-8088} (port controlled by SUPSERSET_PORT in .env-local)
- Flower (optional): http://localhost:5555

Logs and troubleshooting
- See service logs:
  - docker compose -f docker-compose-non-dev.yml logs -f superset
  - docker compose -f docker-compose-non-dev.yml logs -f superset-init
- Inspect container state:
  - docker ps
  - docker compose -f docker-compose-non-dev.yml ps

Stopping and removing stack
- docker compose -f docker-compose-non-dev.yml down --volumes --rmi local
  (this removes volumes defined in the compose file and locally built images)

Security notes
- Do NOT commit superset/docker/.env-local with real secrets to Git.
- Use a secrets manager or CI/CD secrets for production deployments.
- Consider using an external managed Postgres and Redis in production instead of the local containers.

What I changed and why
- Compose now builds the Superset image from your local superset/docker/Dockerfile so customizations in the Dockerfile are applied.
- The compose file is tuned to be production-friendly: healthchecks, restart policies, explicit volumes for persistence, and a one-shot initializer that runs migrations and can create an admin user.
- The .env-local template lists all environment variables referenced in the compose (and the usual ones you need to configure Superset), so you can fill in secrets and environment-specific settings.

Next steps
- Copy config files into superset/docker (manually or via scripts/06).
- Confirm Dockerfile in superset/docker builds as expected (install any project-specific packages, set correct workdir).
- Run docker compose -f docker-compose-non-dev.yml up -d --build and watch the superset-init logs for migration success and admin creation.
