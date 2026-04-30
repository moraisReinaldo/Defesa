#!/bin/bash
# ==============================================================
# run-spring-boot.sh — Wrapper para iniciar o Spring Boot
# ==============================================================
# Lê a URL do MinIO do arquivo de env gerado pelo startup-server.sh
# e passa como variável de ambiente para o Java.
# Assim não precisa recompilar o backend a cada boot.
# ==============================================================

USR_HOME="/Users/reinaldohenriquemorais"
JAR="$USR_HOME/Defesa/defesa-backend/target/backend-0.0.1-SNAPSHOT.jar"
ENV_FILE="$USR_HOME/logs/tunnel-urls.env"

# Carregar variáveis de ambiente do arquivo gerado pelo startup
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# Fallback para localhost se não tiver URL do Cloudflare
export MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://localhost:9000}"

echo "[$(date)] Iniciando Spring Boot..."
echo "  MINIO_ENDPOINT=$MINIO_ENDPOINT"
echo "  JAR=$JAR"

# Verificar se o jar existe
if [ ! -f "$JAR" ]; then
    echo "[ERRO] JAR não encontrado: $JAR"
    echo "[ERRO] Execute: cd ~/Defesa/defesa-backend && ./mvnw package -DskipTests"
    exit 1
fi

exec /usr/bin/java \
    -Xmx512m \
    -Dserver.port=8080 \
    -jar "$JAR"
