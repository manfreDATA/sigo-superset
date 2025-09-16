import os

SECRET_KEY = os.getenv("SUPERSET_SECRET_KEY", "PLEASE_CHANGE_ME")
ENABLE_PROXY_FIX = True
ROW_LIMIT = 5000

# Priorizar Postgres en el modal de nueva BD
PREFERRED_DATABASES = ["PostgreSQL"]
