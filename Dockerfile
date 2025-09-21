FROM apache/superset:6.0.0rc1

ARG BUILD_SUPERSET_FRONT=true
WORKDIR /app

COPY dashboards/ dashboards/
COPY datasources/ datasources/
COPY assets/ assets/
COPY create_users.py create_users.py
COPY requirements.txt requirements.txt
COPY 04_create_plugin.sh 04_create_plugin.sh

RUN pip install --no-cache-dir -r requirements.txt

RUN chmod +x /app/04_create_plugin.sh && \
    SUPERSET_ROOT=/app \
    /app/04_create_plugin.sh

CMD ["superset", "run", "-h", "0.0.0.0", "-p", "8088"]
