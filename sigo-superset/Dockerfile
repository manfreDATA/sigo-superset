FROM apache/superset:6.0.0rc1
ARG BUILD_SUPERSET_FRONT=false
WORKDIR /app
COPY dashboards/ dashboards/
COPY datasources/ datasources/
COPY assets/ assets/
COPY plugins/ plugins/
COPY create_users.py create_users.py
COPY requirements.txt requirements.txt
COPY 04_create_plugin.sh /app/04_create_plugin.sh
RUN chmod +x /app/04_create_plugin.sh
RUN pip install --no-cache-dir -r requirements.txt
RUN if [ "$BUILD_SUPERSET_FRONT" = "true" ]; then \
      echo "Compilando frontend de Superset..." && \
      npm ci --legacy-peer-deps && \
      npm run build && \
      echo "✅ Frontend compilado correctamente."; \
    else \
      echo "⏭️ Compilación de frontend omitida."; \
    fi
CMD ["superset", "run", "-h", "0.0.0.0", "-p", "8088"]
